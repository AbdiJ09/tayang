/// Koneksi ke project Supabase.
///
/// Ambil dari Supabase Dashboard → tombol **Connect** (atau Project Settings →
/// API Keys): "Project URL" dan "publishable key" (`sb_publishable_...`;
/// project lama menyebutnya "anon key" — dua-duanya bisa).
///
/// Key ini memang boleh ada di aplikasi (bukan rahasia). Keamanan data dijaga
/// oleh Row Level Security di `supabase/schema.sql`. JANGAN pernah taruh
/// secret key / `service_role` di sini.
///
/// Bisa juga diisi saat run tanpa mengubah file:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');

const supabaseKey = String.fromEnvironment('SUPABASE_KEY', defaultValue: '');

bool get supabaseConfigured =>
    supabaseUrl.startsWith('https://') && supabaseKey.isNotEmpty;
