import { createClient } from '@supabase/supabase-js'

const supabaseUrl = "https://srpzqbdctswcosoufqvj.supabase.co"
const supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNycHpxYmRjdHN3Y29zb3VmcXZqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwODQ4NTMsImV4cCI6MjA4ODY2MDg1M30.6mQZXzhm7fK9qa1XPfrGJWt8rPkGu306sMmVKPjhj78"

export const supabase = createClient(supabaseUrl, supabaseKey)