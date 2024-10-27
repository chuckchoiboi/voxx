// src/models/JournalModel.ts
import { supabase } from '../services/supabaseClient';
import { Database } from '../database.types';

type JournalEntry = Database['public']['Tables']['journal_entries']['Row'];

export async function fetchJournalEntries(): Promise<JournalEntry[] | null> {
	const { data, error } = await supabase.from('journal_entries').select('*');

	if (error) {
		console.error('Error fetching journal entries:', error);
		return null;
	} else {
		console.log('Journal entries:', data);
		return data;
	}
}
