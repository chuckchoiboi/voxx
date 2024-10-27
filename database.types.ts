// src/database.types.ts
export type Json =
	| string
	| number
	| boolean
	| null
	| { [key: string]: Json }
	| Json[];

export interface Database {
	public: {
		Tables: {
			journal_entries: {
				Row: {
					id: number;
					user_id: string | null;
					audio_url: string;
					summary: string | null;
					created_at: string;
				};
				Insert: {
					user_id?: string | null;
					audio_url: string;
					summary?: string | null;
					created_at?: string;
				};
				Update: {
					user_id?: string | null;
					audio_url?: string;
					summary?: string | null;
					created_at?: string;
				};
			};
		};
		Views: {};
		Functions: {};
		Enums: {};
	};
}
