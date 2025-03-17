import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

interface UpdatePostRequest {
  images?: string[];
  caption?: string;
  location?: string | null;
}

serve(async (req) => {
  if (req.method !== "PATCH") {
    return new Response(
      JSON.stringify({
        error: "Method not allowed",
        details: "Only PATCH method is supported",
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
      .select("*")
      .eq("id", postId)
      .single();

    if (postError) {
      return new Response(
        JSON.stringify({
          error: "Post not found",
          details: "The post you are trying to update does not exist",
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
          details: "You can only update your own posts",
        }),
        {
          status: 403,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    let updateData: UpdatePostRequest;
    try {
      updateData = await req.json();
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

    const { images, caption, location } = updateData;

    if (
      images !== undefined && (!Array.isArray(images) || images.length === 0)
    ) {
      return new Response(
        JSON.stringify({
          error: "Invalid request",
          details: "If provided, images must be a non-empty array",
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    if (
      caption !== undefined &&
      (typeof caption !== "string" || caption.trim() === "")
    ) {
      return new Response(
        JSON.stringify({
          error: "Invalid request",
          details: "If provided, caption must be a non-empty string",
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    if (
      location !== undefined && location !== null &&
      typeof location !== "string"
    ) {
      return new Response(
        JSON.stringify({
          error: "Invalid request",
          details: "Location must be a string or null if provided",
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    const updateObject: Record<string, unknown> = {};

    if (images !== undefined) {
      updateObject.images = images;
    }

    if (caption !== undefined) {
      updateObject.caption = caption;
    }

    if (location !== undefined) {
      updateObject.location = location;
    }

    if (Object.keys(updateObject).length === 0) {
      return new Response(
        JSON.stringify({
          error: "No update data",
          details: "No valid fields to update were provided",
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    const { data: updatedPost, error: updateError } = await supabase
      .from("posts")
      .update(updateObject)
      .eq("id", postId)
      .select("*")
      .single();

    if (updateError) {
      console.error("Error updating post:", updateError);
      return new Response(
        JSON.stringify({
          error: "Failed to update post",
          details: updateError.message,
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    return new Response(
      JSON.stringify({
        message: "Post updated successfully",
        post: updatedPost,
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
