// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

interface RequestBody {
  restaurantId: string; // fsq_id
  preference: "like" | "dislike";
}

console.log("Hello from Functions!");

serve(async (req) => {
  try {
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseKey);

    const token = req.headers.get("Authorization")?.split(" ")[1];

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
    const { restaurantId, preference } = requestData;

    if (!restaurantId || !preference) {
      return new Response(
        JSON.stringify({ error: "Restaurant ID and preference are required" }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    // Validate preference value
    if (preference !== "like" && preference !== "dislike") {
      return new Response(
        JSON.stringify({ error: "Preference must be 'like' or 'dislike'" }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    // Save preference to the database (upsert to handle both new and existing preferences)
    const { data, error } = await supabase
      .from("restaurant_preferences")
      .upsert({
        user_id: userId,
        restaurant_id: restaurantId,
        preference: preference,
      }, { onConflict: "user_id,restaurant_id" });

    if (error) {
      return new Response(
        JSON.stringify({
          error: "Failed to save preference",
          details: error.message,
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `Restaurant ${restaurantId} marked as ${preference}`,
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

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/save-restaurant-preference' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
