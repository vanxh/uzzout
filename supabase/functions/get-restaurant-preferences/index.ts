// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

interface RequestBody {
  restaurantId: string; // fsq_id
}

interface PreferenceCounts {
  likes: number;
  dislikes: number;
  userPreference: string | null;
}

console.log("Restaurant Preferences Function initialized!");

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
    // Get authenticated user
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
    const { restaurantId } = requestData;

    if (!restaurantId) {
      return new Response(
        JSON.stringify({ error: "Restaurant ID is required" }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    console.log(
      "Getting preferences for restaurant:",
      restaurantId,
    );

    // Get total likes for the restaurant
    const { count: likesCount, error: likesError } = await supabase
      .from("restaurant_preferences")
      .select("*", { count: "exact", head: true })
      .eq("restaurant_id", restaurantId)
      .eq("preference", "like");

    if (likesError) {
      return new Response(
        JSON.stringify({
          error: "Failed to get likes count",
          details: likesError.message,
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    // Get total dislikes for the restaurant
    const { count: dislikesCount, error: dislikesError } = await supabase
      .from("restaurant_preferences")
      .select("*", { count: "exact", head: true })
      .eq("restaurant_id", restaurantId)
      .eq("preference", "dislike");

    if (dislikesError) {
      return new Response(
        JSON.stringify({
          error: "Failed to get dislikes count",
          details: dislikesError.message,
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    // Get the current user's preference for this restaurant
    const { data: userPreference, error: userPrefError } = await supabase
      .from("restaurant_preferences")
      .select("preference")
      .eq("restaurant_id", restaurantId)
      .eq("user_id", userId)
      .single();

    if (userPrefError && userPrefError.code !== "PGRST116") { // PGRST116 is 'no rows returned' which is fine
      return new Response(
        JSON.stringify({
          error: "Failed to get user preference",
          details: userPrefError.message,
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    const result: PreferenceCounts = {
      likes: likesCount || 0,
      dislikes: dislikesCount || 0,
      userPreference: userPreference ? userPreference.preference : null,
    };

    return new Response(
      JSON.stringify({
        success: true,
        data: result,
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

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/get-restaurant-preferences' \
    --header 'Authorization: Bearer YOUR_ANON_KEY' \
    --header 'Content-Type: application/json' \
    --data '{"restaurantId":"YOUR_RESTAURANT_ID"}'

*/
