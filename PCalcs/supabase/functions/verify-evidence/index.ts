// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import nacl from "https://esm.sh/tweetnacl@1.0.3";

interface Input {
  id?: string;
  payload_json?: any;
  evidence_hash_hex?: string;
  evidence_sig_hex?: string;
  device_pubkey_hex?: string;
}

function hexToBytes(hex: string): Uint8Array {
  if (!/^([0-9a-fA-F]{2})+$/.test(hex)) throw new Error("invalid hex");
  const arr = new Uint8Array(hex.length / 2);
  for (let i = 0; i < hex.length; i += 2) {
    arr[i / 2] = parseInt(hex.slice(i, i + 2), 16);
  }
  return arr;
}

function stableStringify(obj: any): string {
  if (obj === null || typeof obj !== "object") return JSON.stringify(obj);
  if (Array.isArray(obj)) return "[" + obj.map((v) => stableStringify(v)).join(",") + "]";
  const keys = Object.keys(obj).sort();
  const parts = keys.map((k) => JSON.stringify(k) + ":" + stableStringify(obj[k]));
  return "{" + parts.join(",") + "}";
}

async function handler(req: Request): Promise<Response> {
  try {
    const input = (await req.json()) as Input;
    if (!input) return new Response(JSON.stringify({ ok: false, reason: "no input" }), { status: 400 });

    // Fetch row if only id provided
    let payload_json = input.payload_json;
    let evidence_hash_hex = input.evidence_hash_hex;
    let evidence_sig_hex = input.evidence_sig_hex;
    let device_pubkey_hex = input.device_pubkey_hex;

    if (input.id && (!payload_json || !evidence_hash_hex || !evidence_sig_hex || !device_pubkey_hex)) {
      const url = Deno.env.get("SUPABASE_URL");
      const key = Deno.env.get("SUPABASE_ANON_KEY");
      if (!url || !key) throw new Error("Missing Supabase env");
      const r = await fetch(`${url}/rest/v1/history?id=eq.${input.id}&select=payload_json,evidence_hash_hex,evidence_sig_hex,device_pubkey_hex`, {
        headers: { Authorization: `Bearer ${key}` }
      });
      if (!r.ok) return new Response(JSON.stringify({ ok: false, reason: `select failed ${r.status}` }), { status: 500 });
      const rows = await r.json();
      if (!rows || !rows[0]) return new Response(JSON.stringify({ ok: false, reason: "not found" }), { status: 404 });
      payload_json = rows[0].payload_json;
      evidence_hash_hex = rows[0].evidence_hash_hex;
      evidence_sig_hex = rows[0].evidence_sig_hex;
      device_pubkey_hex = rows[0].device_pubkey_hex;
    }

    if (!payload_json || !evidence_hash_hex || !evidence_sig_hex || !device_pubkey_hex) {
      return new Response(JSON.stringify({ ok: false, reason: "missing fields" }), { status: 400 });
    }

    // Stable stringify and hash
    const canonical = stableStringify(payload_json);
    const bytes = new TextEncoder().encode(canonical);
    const hashBuf = await crypto.subtle.digest("SHA-256", bytes);
    const hashHex = Array.from(new Uint8Array(hashBuf)).map((b) => b.toString(16).padStart(2, "0")).join("");

    if (hashHex.toLowerCase() !== evidence_hash_hex.toLowerCase()) {
      return new Response(JSON.stringify({ ok: false, reason: "hash mismatch" }), { status: 200 });
    }

    // Verify signature
    const pub = hexToBytes(device_pubkey_hex);
    const sig = hexToBytes(evidence_sig_hex);
    const ok = nacl.sign.detached.verify(hexToBytes(hashHex), sig, pub);
    if (!ok) return new Response(JSON.stringify({ ok: false, reason: "bad signature" }), { status: 200 });

    // Update server_verified=true
    if (input.id) {
      const url = Deno.env.get("SUPABASE_URL");
      const key = Deno.env.get("SUPABASE_ANON_KEY");
      if (!url || !key) throw new Error("Missing Supabase env");
      const u = await fetch(`${url}/rest/v1/history?id=eq.${input.id}`, {
        method: "PATCH",
        headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
        body: JSON.stringify({ server_verified: true }),
      });
      if (!u.ok) return new Response(JSON.stringify({ ok: false, reason: `update failed ${u.status}` }), { status: 500 });
    }

    return new Response(JSON.stringify({ ok: true }), { status: 200 });
  } catch (e) {
    return new Response(JSON.stringify({ ok: false, reason: String(e) }), { status: 500 });
  }
}

serve(handler);