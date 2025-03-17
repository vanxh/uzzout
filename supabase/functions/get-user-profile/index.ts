import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

interface UserProfile {
  id: string;
  email: string;
  full_name?: string;
  avatar_url?: string;
  bio?: string;
  created_at?: string;
  updated_at?: string;
}

serve(async (req) => {
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

    const url = new URL(req.url);
    const pathParts = url.pathname.split("/");
    const userId = pathParts.length > 0
      ? pathParts[pathParts.length - 1]
      : null;

    const uuidRegex =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    const isValidUuid = userId && uuidRegex.test(userId);
    const requestedUserId = isValidUuid ? userId : user.id;

    if (isValidUuid && requestedUserId !== user.id) {
      const { data: publicProfile, error: publicProfileError } = await supabase
        .from("users")
        .select("*")
        .eq("id", requestedUserId)
        .single();

      if (publicProfileError) {
        console.error("Error fetching public profile:", publicProfileError);
        return new Response(
          JSON.stringify({
            error: "Profile not found",
            details: publicProfileError.message,
          }),
          {
            status: 404,
            headers: { "Content-Type": "application/json" },
          },
        );
      }

      return new Response(
        JSON.stringify({
          profile: {
            ...publicProfile,
            email: `${publicProfile.email.split("@")[0]?.slice(0, 1)}****@${
              publicProfile.email.split("@")[1]
            }`,
          },
        }),
        {
          status: 200,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    const { data: profile } = await supabase
      .from("users")
      .select("*")
      .eq("id", user.id)
      .single();

    if (profile) {
      return new Response(
        JSON.stringify({
          auth_user: user,
          profile,
        }),
        {
          status: 200,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    const newProfile: UserProfile = {
      id: user.id,
      email: user.email ?? "",
      full_name: user.user_metadata?.full_name,
      avatar_url: user.user_metadata?.avatar_url,
      bio: "",
      created_at: user.created_at ?? new Date().toISOString(),
      updated_at: user.updated_at ?? new Date().toISOString(),
    };

    const { data: createdProfile, error: createError } = await supabase
      .from("users")
      .insert(newProfile)
      .select("*")
      .single();

    if (createError) {
      console.error("Error creating profile:", createError);
      return new Response(
        JSON.stringify({
          error: "Failed to create profile",
          details: createError.message,
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    return new Response(
      JSON.stringify({
        auth_user: user,
        profile: createdProfile,
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
