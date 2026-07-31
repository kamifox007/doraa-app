import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

// مفتاح الخادم (سيتم تخزينه لاحقاً في Supabase Secrets)
const FIREBASE_SERVER_KEY = Deno.env.get('FIREBASE_SERVER_KEY');

serve(async (req: Request) => {
  try {
    const { fcm_token, title, body, data } = await req.json();

    if (!FIREBASE_SERVER_KEY) {
      return new Response(
        JSON.stringify({ error: 'Firebase Server Key is not configured in Supabase Secrets.' }),
        { headers: { "Content-Type": "application/json" }, status: 500 }
      );
    }

    const payload = {
      to: fcm_token,
      notification: {
        title: title,
        body: body,
      },
      data: data || {},
    };

    const response = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `key=${FIREBASE_SERVER_KEY}`,
      },
      body: JSON.stringify(payload),
    });

    const result = await response.json();

    return new Response(
      JSON.stringify({ success: true, result }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { "Content-Type": "application/json" }, status: 400 }
    );
  }
});
