// @ts-ignore - Deno import (VS Code may complain but works on Supabase)
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const PAYMONGO_SECRET_KEY = Deno.env.get('sk_test_NNR963A2fi6HsNXoA99jxCtk');
    if (!PAYMONGO_SECRET_KEY) {
      throw new Error("Missing PayMongo Secret Key in Supabase secrets.");
    }

    const { amount, request_id, description } = await req.json();

    const response = await fetch('https://api.paymongo.com/v1/checkout_sessions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${btoa(PAYMONGO_SECRET_KEY + ':')}`,
      },
      body: JSON.stringify({
        data: {
          attributes: {
            send_email_receipt: true,
            show_description: true,
            show_line_items: true,
            description: description,
            line_items: [
              { currency: 'PHP', amount: amount, name: description, quantity: 1 }
            ],
            payment_method_types: ['gcash'],
            reference_number: request_id,
            success_url: 'https://yourdomain.com/payment_success',
            cancel_url: 'https://yourdomain.com/payment_cancel',
          },
        },
      }),
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.errors ? data.errors[0].detail : "PayMongo Error");
    }

    return new Response(
      JSON.stringify({ checkout_url: data.data.attributes.checkout_url }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    );
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    );
  }
});