// @ts-nocheck
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1"
import { RekognitionClient, CompareFacesCommand } from "npm:@aws-sdk/client-rekognition@3.370.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  // Handle CORS preflight request
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { userId, cniImageUrl, selfieImageUrl } = await req.json()

    // 1. Initialize Supabase Client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    // 2. Fetch images from URLs to get ArrayBuffers (AWS requires bytes)
    const [cniResponse, selfieResponse] = await Promise.all([
      fetch(cniImageUrl),
      fetch(selfieImageUrl)
    ])

    if (!cniResponse.ok || !selfieResponse.ok) {
      throw new Error('Failed to download images for comparison')
    }

    const cniBytes = new Uint8Array(await cniResponse.arrayBuffer())
    const selfieBytes = new Uint8Array(await selfieResponse.arrayBuffer())

    // 3. Initialize AWS Rekognition Client
    // NOTE: Requires AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_REGION in Supabase Secrets
    const rekognition = new RekognitionClient({
      region: Deno.env.get('AWS_REGION') || 'us-east-1',
      credentials: {
        accessKeyId: Deno.env.get('AWS_ACCESS_KEY_ID') || '',
        secretAccessKey: Deno.env.get('AWS_SECRET_ACCESS_KEY') || '',
      }
    })

    // 4. Compare Faces using AWS
    const command = new CompareFacesCommand({
      SourceImage: { Bytes: cniBytes },
      TargetImage: { Bytes: selfieBytes },
      SimilarityThreshold: 80.0, // Minimum 80% match
    })

    const response = await rekognition.send(command)

    // 5. Calculate results
    const faceMatches = response.FaceMatches || []
    const isApproved = faceMatches.length > 0 && (faceMatches[0].Similarity ?? 0) >= 80.0
    const similarityScore = faceMatches.length > 0 ? faceMatches[0].Similarity : 0

    // 6. Save decision to Supabase ai_decisions table
    await supabaseClient.from('ai_decisions').insert({
      user_id: userId,
      decision_type: 'face_verification',
      score: similarityScore,
      is_approved: isApproved,
      metadata: { aws_response: response }
    })

    // 7. Return Result
    return new Response(
      JSON.stringify({ 
        success: true, 
        isApproved, 
        similarity: similarityScore 
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    const err = error as Error;
    return new Response(
      JSON.stringify({ success: false, error: err.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
