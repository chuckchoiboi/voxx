// src/supabaseClient.ts
import { createClient, SupabaseClient } from '@supabase/supabase-js';

const SUPABASE_URL: string = 'https://your-project-url.supabase.co'; // From your Supabase dashboard
const SUPABASE_ANON_KEY: string = 'your-anon-key'; // From your Supabase dashboard

export const supabase: SupabaseClient = createClient(
	SUPABASE_URL,
	SUPABASE_ANON_KEY
);
