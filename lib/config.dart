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
/// Nilai di bawah = project bawaan repo. Pakai project Supabase sendiri tanpa
/// mengubah file ini: copy `supabase.example.json` → `supabase.json`, isi, lalu
///   flutter run -d chrome --dart-define-from-file=supabase.json
/// (lihat TUTORIAL.md langkah 5–7).
const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://ihrimgpcvjquohzdfxbz.supabase.co',
);

const supabaseKey = String.fromEnvironment(
  'SUPABASE_KEY',
  defaultValue: 'sb_publishable_GlEwPadEo4tcSKrK5xYmCw_pZtNB-XQ',
);

bool get supabaseConfigured =>
    supabaseUrl.startsWith('https://') && supabaseKey.isNotEmpty;
