import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { RekognitionClient, CompareFacesCommand } from "npm:@aws-sdk/client-rekognition";

// المفاتيح سيتم تخزينها في Supabase Secrets وليس في الكود
const AWS_REGION = Deno.env.get('AWS_REGION') || "us-east-1";
const AWS_ACCESS_KEY_ID = Deno.env.get('AWS_ACCESS_KEY_ID');
const AWS_SECRET_ACCESS_KEY = Deno.env.get('AWS_SECRET_ACCESS_KEY');

const rekognition = new RekognitionClient({
  region: AWS_REGION,
  credentials: {
    accessKeyId: AWS_ACCESS_KEY_ID || "",
    secretAccessKey: AWS_SECRET_ACCESS_KEY || "",
  },
});

serve(async (req: Request) => {
  try {
    const { sourceImageBase64, targetImageBase64 } = await req.json();

    if (!AWS_ACCESS_KEY_ID || !AWS_SECRET_ACCESS_KEY) {
      return new Response(
        JSON.stringify({ error: "AWS credentials are not configured in Supabase Secrets." }),
        { headers: { "Content-Type": "application/json" }, status: 500 }
      );
    }

    if (!sourceImageBase64 || !targetImageBase64) {
      return new Response(
        JSON.stringify({ error: "Both source and target images (base64) are required." }),
        { headers: { "Content-Type": "application/json" }, status: 400 }
      );
    }

    // Convert base64 to Uint8Array (Buffer)
    const sourceBytes = Uint8Array.from(atob(sourceImageBase64), c => c.charCodeAt(0));
    const targetBytes = Uint8Array.from(atob(targetImageBase64), c => c.charCodeAt(0));

    const command = new CompareFacesCommand({
      SourceImage: { Bytes: sourceBytes },
      TargetImage: { Bytes: targetBytes },
      SimilarityThreshold: 80, // نسبة التطابق المطلوبة (80% فما فوق)
    });

    const data = await rekognition.send(command);

    const matches = data.FaceMatches || [];
    const isMatch = matches.length > 0 && matches[0].Similarity >= 80;

    return new Response(
      JSON.stringify({
        success: true,
        isMatch: isMatch,
        similarity: isMatch ? matches[0].Similarity : 0,
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error: any) {
    console.error("AWS Rekognition Error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { "Content-Type": "application/json" }, status: 400 }
    );
  }
});
