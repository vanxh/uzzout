import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

interface CreatePostRequest {
  images: string[];
  caption: string;
  location?: string;
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

    let postData: CreatePostRequest;
    try {
      postData = await req.json();
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

    const { images, caption, location } = postData;

    if (!images || !Array.isArray(images) || images.length === 0) {
      return new Response(
        JSON.stringify({
          error: "Invalid request",
          details: "At least one image is required",
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    if (!caption || typeof caption !== "string" || caption.trim() === "") {
      return new Response(
        JSON.stringify({
          error: "Invalid request",
          details: "Caption is required",
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    if (location !== undefined && (typeof location !== "string")) {
      return new Response(
        JSON.stringify({
          error: "Invalid request",
          details: "Location must be a string if provided",
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    const { data: post, error: postError } = await supabase
      .from("posts")
      .insert({
        user_id: currentUser.id,
        images,
        caption,
        location: location || null,
      })
      .select("*")
      .single();

    if (postError) {
      console.error("Error creating post:", postError);
      return new Response(
        JSON.stringify({
          error: "Failed to create post",
          details: postError.message,
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    return new Response(
      JSON.stringify({
        message: "Post created successfully",
        post,
      }),
      {
        status: 201,
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
