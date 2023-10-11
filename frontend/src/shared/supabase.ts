import { createClient } from "@supabase/supabase-js";
import { env } from "./environment";

// Create a single supabase client for interacting with your database
export const supabase = createClient(env.supabaseUrl, env.supabaseAnonKey);
