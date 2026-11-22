// @ts-ignore - Deno import
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
// @ts-ignore - Deno import
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req: Request) => {
  try {
    const PAYMONGO_WEBHOOK_SECRET = Deno.env.get('PAYMONGO_WEBHOOK_SECRET');
    if (!PAYMONGO_WEBHOOK_SECRET) {
      throw new Error("Missing PAYMONGO_WEBHOOK_SECRET");
    }

    const signatureHeader = req.headers.get('paymongo-signature');
    if (!signatureHeader) throw new Error("No signature provided");

    const payloadText = await req.text();
    const payload = JSON.parse(payloadText);

    // 1. Verify Signature
    const parts = signatureHeader.split(',');
    const timestamp = parts[0].split('=')[1];
    const signature = parts[1].split('=')[1];

    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      "raw",
      encoder.encode(PAYMONGO_WEBHOOK_SECRET),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    );
    const signatureBuffer = await crypto.subtle.sign(
      "HMAC",
      key,
      encoder.encode(`${timestamp}.${payloadText}`)
    );
    const expectedSignature = Array.from(new Uint8Array(signatureBuffer))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('');

    if (expectedSignature !== signature) {
      throw new Error("Invalid signature");
    }

    // 2. Handle Payment Success
    if (payload.data.attributes.type === 'payment.paid') {
      const requestId = payload.data.attributes.data.attributes.reference_number;
      const paymentId = payload.data.attributes.data.id;

      // 3. Update Supabase
      const supabase = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
      );

      const { error } = await supabase
        .from('document_requests')
        .update({
          payment_status: 'Paid',
          status: 'Processing',
          paid_at: new Date().toISOString(),
          payment_reference: paymentId,
        })
        .eq('id', requestId);

      if (error) throw error;
    }

    return new Response(JSON.stringify({ received: true }), { status: 200 });
  } catch (error: any) {
    console.error('Webhook error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400 }
    );
  }
});