import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

interface UserProfile {
  id: string;
  email: string;
  full_name?: string;
  avatar_url?: string;
  bio?: string;
  updated_at?: string;
}

interface UpdateProfileRequest {
  full_name?: string;
  avatar_url?: string;
  bio?: string;
}

serve(async (req) => {
  if (req.method !== "PUT") {
    return new Response(
      JSON.stringify({
        error: "Method not allowed",
        details: "Only PUT method is supported",
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

    const user = authData.user;

    let updateData: UpdateProfileRequest;
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

    if (
      typeof updateData !== "object" ||
      updateData === null ||
      Object.keys(updateData).length === 0
    ) {
      return new Response(
        JSON.stringify({
          error: "Invalid update data",
          details: "No valid fields to update",
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    if ((updateData.bio && updateData.bio.length > 100)) {
      return new Response(
        JSON.stringify({
          error: "Invalid update data",
          details: "Bio must be less than 100 characters",
        }),
      );
    }

    const updates: Partial<UserProfile> = {
      updated_at: new Date().toISOString(),
    };

    if (updateData.full_name !== undefined) {
      updates.full_name = updateData.full_name;
    }

    if (updateData.avatar_url !== undefined) {
      updates.avatar_url = updateData.avatar_url;
    }

    if (updateData.bio !== undefined) {
      updates.bio = updateData.bio;
    }

    const { data: updatedProfile, error: updateError } = await supabase
      .from("users")
      .update(updates)
      .eq("id", user.id)
      .select("*")
      .single();

    if (updateError) {
      console.error("Error updating profile:", updateError);
      return new Response(
        JSON.stringify({
          error: "Failed to update profile",
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
        message: "Profile updated successfully",
        profile: updatedProfile,
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
