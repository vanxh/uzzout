import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

interface UnfollowRequest {
  user_id: string;
}

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({
        error: "Method not allowed",
        details: "Only POST method is supported",
      }),
      {
        status: 405,
        headers: { "Content-Type": "application/json" },
      },
    );
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const authorization = req.headers.get("Authorization") ?? "";

    if (!authorization) {
      return new Response(
        JSON.stringify({ error: "Unauthorized: No authorization header" }),
        {
          status: 401,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: {
        headers: {
          "Authorization": authorization,
        },
      },
    });

    const token = authorization.split(" ")[1];
    const { data: authData, error: authError } = await supabase.auth.getUser(
      token,
    );

    if (authError || !authData?.user) {
      console.error("Authentication error:", authError);
      return new Response(
        JSON.stringify({
          error: "Unauthorized",
          details: authError?.message ?? "User not found",
        }),
        {
          status: 401,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    const currentUser = authData.user;

    let unfollowRequest: UnfollowRequest;
    try {
      unfollowRequest = await req.json();
    } catch {
      return new Response(
        JSON.stringify({
          error: "Invalid request body",
          details: "Request body must be valid JSON",
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    const { user_id } = unfollowRequest;

    if (!user_id) {
      return new Response(
        JSON.stringify({
          error: "Invalid request",
          details: "user_id is required",
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    if (user_id === currentUser.id) {
      return new Response(
        JSON.stringify({
          error: "Invalid request",
          details: "You cannot unfollow yourself",
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    const { data: existingFollow } = await supabase
      .from("user_followers")
      .select("id")
      .eq("follower_id", currentUser.id)
      .eq("following_id", user_id)
      .single();

    if (!existingFollow) {
      return new Response(
        JSON.stringify({
          error: "Not following",
          details: "You are not following this user",
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    const { error: unfollowError } = await supabase
      .from("user_followers")
      .delete()
      .eq("follower_id", currentUser.id)
      .eq("following_id", user_id);

    if (unfollowError) {
      console.error("Error unfollowing user:", unfollowError);
      return new Response(
        JSON.stringify({
          error: "Failed to unfollow user",
          details: unfollowError.message,
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    return new Response(
      JSON.stringify({
        message: "Successfully unfollowed user",
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error("Unhandled error:", error);
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
