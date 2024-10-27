// src/services/supabaseClient.ts
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { SUPABASE_URL, SUPABASE_ANON_KEY } from '@env';

export const supabase: SupabaseClient = createClient(
	SUPABASE_URL,
	SUPABASE_ANON_KEY
);
