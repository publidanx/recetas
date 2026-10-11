import Foundation
import Supabase

enum SupabaseConfig {
    static let url = URL(string: "https://srpzqbdctswcosoufqvj.supabase.co")!
    /// Clave anónima pública, la misma que usa la app web. El acceso real lo limitan las políticas RLS.
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNycHpxYmRjdHN3Y29zb3VmcXZqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwODQ4NTMsImV4cCI6MjA4ODY2MDg1M30.6mQZXzhm7fK9qa1XPfrGJWt8rPkGu306sMmVKPjhj78"
    static let recipesTable = "Recetas"
    static let imageBucket = "imagen_recetas"
}

enum SupabaseProvider {
    static let client = SupabaseClient(
        supabaseURL: SupabaseConfig.url,
        supabaseKey: SupabaseConfig.anonKey
    )
}
