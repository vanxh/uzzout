import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

serve(async (req) => {
  if (req.method !== "DELETE") {
    return new Response(
      JSON.stringify({
        error: "Method not allowed",
        details: "Only DELETE method is supported",
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

    const url = new URL(req.url);
    const pathParts = url.pathname.split("/");
    const postId = pathParts.length > 0
      ? pathParts[pathParts.length - 1]
      : null;

    if (!postId) {
      return new Response(
        JSON.stringify({
          error: "Missing post ID",
          details: "Post ID is required",
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    const { data: post, error: postError } = await supabase
      .from("posts")
      .select("id, user_id")
      .eq("id", postId)
      .single();

    if (postError) {
      return new Response(
        JSON.stringify({
          error: "Post not found",
          details: "The post you are trying to delete does not exist",
        }),
        {
          status: 404,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    if (post.user_id !== currentUser.id) {
      return new Response(
        JSON.stringify({
          error: "Forbidden",
          details: "You can only delete your own posts",
        }),
        {
          status: 403,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    const { error: deleteError } = await supabase
      .from("posts")
      .delete()
      .eq("id", postId);

    if (deleteError) {
      console.error("Error deleting post:", deleteError);
      return new Response(
        JSON.stringify({
          error: "Failed to delete post",
          details: deleteError.message,
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    return new Response(
      JSON.stringify({
        message: "Post deleted successfully",
        id: postId,
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
