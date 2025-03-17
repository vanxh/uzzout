import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

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
          Authorization: authorization,
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
    const userId = pathParts.length > 0
      ? pathParts[pathParts.length - 1]
      : null;

    const uuidRegex =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    const isValidUuid = userId && uuidRegex.test(userId);
    const targetUserId = isValidUuid ? userId : currentUser.id;

    const page = Number.parseInt(url.searchParams.get("page") ?? "1");
    const limit = Number.parseInt(url.searchParams.get("limit") ?? "20");
    const offset = (page - 1) * limit;

    const {
      data: following,
      error: followingError,
      count,
    } = await supabase
      .from("user_followers")
      .select("*, user:following_id(id, email, full_name, avatar_url, bio)", {
        count: "exact",
      })
      .eq("follower_id", targetUserId)
      .order("created_at", { ascending: false })
      .range(offset, offset + limit - 1);

    if (followingError) {
      console.error("Error fetching following:", followingError);
      return new Response(
        JSON.stringify({
          error: "Failed to fetch following",
          details: followingError.message,
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    const processedFollowing = following.map((follow) => {
      if (follow.user && follow.following_id !== currentUser.id) {
        return {
          ...follow,
          user: {
            ...follow.user,
            email: `${follow.user.email.split("@")[0]?.slice(0, 1)}****@${
              follow.user.email.split("@")[1]
            }`,
          },
        };
      }
      return follow;
    });

    return new Response(
      JSON.stringify({
        following: processedFollowing,
        pagination: {
          total: count ?? 0,
          page,
          limit,
          totalPages: Math.ceil((count ?? 0) / limit),
        },
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
