// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

// Getit Foursquare API key from environment variable
const FOURSQUARE_API_KEY = Deno.env.get("FOURSQUARE_API_KEY") ?? "";
const CACHE_TTL_MINUTES = 10; // Cache expires after 10 minutes

interface RequestBody {
  latitude: number;
  longitude: number;
  radius?: number;
  categories?: string;
  sort?: string;
  limit?: number;
}

console.log("Hello from Functions!");

serve(async (req) => {
  try {
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const authorization = req.headers.get("Authorization") ?? "";
    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: {
        headers: {
          "Authorization": authorization,
        },
      },
    });

    const token = authorization.split(" ")[1];
    // Get user authentication
    const { data: authData } = await supabase.auth.getUser(token);
    if (!authData?.user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        {
          status: 401,
          headers: { "Content-Type": "application/json" },
        },
      );
    }
    const userId = authData.user.id;

    // Parse request body
    const requestData: RequestBody = await req.json();
    const {
      latitude,
      longitude,
      radius = 22000,
      categories = "63be6904847c3692a84b9bb5",
      sort = "distance",
      limit = 50,
    } = requestData;

    if (!latitude || !longitude) {
      return new Response(
        JSON.stringify({ error: "Latitude and longitude are required" }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    // Generate a unique hash for this query
    const queryParams = {
      latitude,
      longitude,
      radius,
      categories,
      sort,
      limit,
    };
    const queryHash = await generateQueryHash(queryParams);

    // Check for cached response
    const { data: cachedData, error: cacheError } = await supabase
      .from("restaurant_cache")
      .select("response, expires_at")
      .eq("user_id", userId)
      .eq("query_hash", queryHash)
      .single();

    // If cache exists and is not expired, return it
    if (
      cachedData && !cacheError && new Date(cachedData.expires_at) > new Date()
    ) {
      // Get user preferences to include with the cached results
      const { data: preferencesData } = await supabase
        .from("restaurant_preferences")
        .select("restaurant_id, preference")
        .eq("user_id", userId);

      const userPreferences = preferencesData || [];

      // Convert preferences to a more usable format
      const preferencesMap = {};
      userPreferences.forEach((pref) => {
        preferencesMap[pref.restaurant_id] = pref.preference;
      });

      return new Response(
        JSON.stringify({
          results: cachedData.response,
          source: "cache",
          userPreferences: preferencesMap,
        }),
        {
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    // Check if API key is available
    if (!FOURSQUARE_API_KEY) {
      return new Response(
        JSON.stringify({ error: "Foursquare API key not configured" }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    // Construct Foursquare API URL
    const fields = [
      "fsq_id",
      "name",
      "geocodes",
      "categories",
      "location",
      "timezone",
      "distance",
      "closed_bucket",
      "photos",
      "description",
      "tel",
      "email",
      "website",
      "social_media",
      "hours",
      "hours_popular",
      "rating",
      "stats",
      "popularity",
      "price",
      "menu",
      "features",
    ].join(",");

    const foursquareUrl = new URL(
      "https://api.foursquare.com/v3/places/search",
    );
    foursquareUrl.searchParams.append("ll", `${latitude},${longitude}`);
    foursquareUrl.searchParams.append("radius", radius.toString());
    foursquareUrl.searchParams.append("categories", categories);
    foursquareUrl.searchParams.append("fields", fields);
    foursquareUrl.searchParams.append("sort", sort);
    foursquareUrl.searchParams.append("limit", limit.toString());

    // Log request details for debugging
    console.log("Foursquare API URL:", foursquareUrl.toString());
    console.log("Latitude, Longitude:", latitude, longitude);
    console.log("Category ID:", categories);
    console.log("API Key present:", FOURSQUARE_API_KEY ? "Yes" : "No");

    // Make request to Foursquare API
    const foursquareResponse = await fetch(foursquareUrl.toString(), {
      method: "GET",
      headers: {
        "Accept": "application/json",
        "Authorization": FOURSQUARE_API_KEY,
      },
    });

    // Log response details for debugging
    console.log("Foursquare Response Status:", foursquareResponse.status);
    console.log(
      "Foursquare Response Status Text:",
      foursquareResponse.statusText,
    );

    if (!foursquareResponse.ok) {
      const errorText = await foursquareResponse.text();
      console.log("Foursquare Error Response:", errorText);

      return new Response(
        JSON.stringify({
          error: "Failed to fetch from Foursquare API",
          status: foursquareResponse.status,
          statusText: foursquareResponse.statusText,
          errorDetails: errorText,
        }),
        {
          status: foursquareResponse.status,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    const foursquareData = await foursquareResponse.json();

    // Store in cache with 10-minute expiration
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + CACHE_TTL_MINUTES);

    // Use upsert to either insert a new cache entry or update an existing one
    const { error: cacheUpdateError } = await supabase
      .from("restaurant_cache")
      .upsert({
        user_id: userId,
        query_hash: queryHash,
        response: foursquareData,
        expires_at: expiresAt.toISOString(),
      });

    if (cacheUpdateError) {
      console.error("Error updating cache:", cacheUpdateError);
    }

    // Get user preferences to include with the results
    const { data: preferencesData } = await supabase
      .from("restaurant_preferences")
      .select("restaurant_id, preference")
      .eq("user_id", userId);

    const userPreferences = preferencesData || [];

    // Convert preferences to a more usable format
    const preferencesMap = {};
    userPreferences.forEach((pref) => {
      preferencesMap[pref.restaurant_id] = pref.preference;
    });

    return new Response(
      JSON.stringify({
        results: foursquareData,
        source: "foursquare_api",
        userPreferences: preferencesMap,
      }),
      {
        headers: { "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        details: error.message,
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      },
    );
  }
});

// Helper function to generate a hash from query parameters
async function generateQueryHash(params: object): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(JSON.stringify(params));
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/fetch-restaurants' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
