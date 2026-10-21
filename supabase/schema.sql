-- =====================================================================
-- Tayang — skema database Supabase (PostgreSQL)
--
-- Cara pakai: buka Supabase Dashboard → SQL Editor → New query,
-- tempel SELURUH isi file ini, klik Run. Cukup dijalankan sekali.
--
-- Tabel:
--   1. users      profil pengguna + role (admin / user),
--                 1–1 dengan akun login Supabase Auth
--   2. movies     daftar film
--   3. bookmarks  film favorit milik tiap user (relasi users ↔ movies)
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. USERS
-- Login/signup ditangani Supabase Auth (tabel internal auth.users, berisi
-- email + password ter-hash). Tabel ini menyimpan profilnya, dan barisnya
-- dibuat otomatis oleh trigger setiap ada akun baru.
--
-- role: 'user' (default, hanya bisa melihat film & menyimpan favorit) atau
-- 'admin' (boleh tambah/edit/hapus film). Role hanya bisa diubah dari
-- dashboard Supabase — lihat supabase/SETUP.md.
-- ---------------------------------------------------------------------
create table public.users (
  id          uuid        primary key references auth.users (id) on delete cascade,
  name        text        not null,
  email       text        not null unique,
  role        text        not null default 'user' check (role in ('user', 'admin')),
  created_at  timestamptz not null default now()
);

-- true kalau user yang sedang login adalah admin. security definer supaya
-- bisa membaca tabel users tanpa terhalang RLS.
create function public.is_admin()
returns boolean
language sql
stable
security definer set search_path = ''
as $$
  select exists (
    select 1 from public.users
    where id = (select auth.uid()) and role = 'admin'
  );
$$;

create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.users (id, name, email)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'name'), ''), split_part(new.email, '@', 1)),
    new.email
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();


-- ---------------------------------------------------------------------
-- 2. MOVIES
-- created_by kosong (null) = film bawaan; terisi = admin yang menambahkan.
-- showtimes: { "<id bioskop>": ["13:00", "15:30"] } — id bioskop sesuai
-- assets/data/tayang.json di aplikasi.
-- ---------------------------------------------------------------------
create table public.movies (
  id          uuid        primary key default gen_random_uuid(),
  title       text        not null check (length(trim(title)) > 0),
  poster_url  text,
  year        int         check (year between 1888 and 2100),
  genres      text[]      not null default '{}',
  duration    int         check (duration > 0),
  rating      text        not null default 'SU' check (rating in ('SU', '13+', '17+', '21+')),
  synopsis    text        not null default '',
  showtimes   jsonb       not null default '{}'::jsonb,
  created_by  uuid        references public.users (id) on delete set null,
  created_at  timestamptz not null default now()
);


-- ---------------------------------------------------------------------
-- 3. BOOKMARKS (favorit)
-- Satu user hanya bisa mem-favoritkan film yang sama satu kali.
-- ---------------------------------------------------------------------
create table public.bookmarks (
  id          bigint      generated always as identity primary key,
  user_id     uuid        not null references public.users (id) on delete cascade,
  movie_id    uuid        not null references public.movies (id) on delete cascade,
  created_at  timestamptz not null default now(),
  unique (user_id, movie_id)
);

create index bookmarks_movie_id_idx on public.bookmarks (movie_id);
create index movies_created_by_idx on public.movies (created_by);


-- ---------------------------------------------------------------------
-- Hak akses (Row Level Security)
-- ---------------------------------------------------------------------
alter table public.users     enable row level security;
alter table public.movies    enable row level security;
alter table public.bookmarks enable row level security;

-- users hanya boleh mengubah kolom name — role TIDAK bisa diubah dari app.
revoke all on public.users from anon, authenticated;
grant select                         on public.users     to authenticated;
grant update (name)                  on public.users     to authenticated;
grant select                         on public.movies    to anon, authenticated;
grant insert, update, delete         on public.movies    to authenticated;
grant select, insert, delete         on public.bookmarks to authenticated;

-- users: hanya bisa melihat & mengubah nama di profil sendiri
create policy "users: lihat profil sendiri" on public.users
  for select to authenticated using ((select auth.uid()) = id);
create policy "users: ubah profil sendiri" on public.users
  for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

-- movies: semua orang boleh lihat; hanya admin yang boleh tambah/ubah/hapus
create policy "movies: semua boleh lihat" on public.movies
  for select to anon, authenticated using (true);
create policy "movies: admin boleh tambah" on public.movies
  for insert to authenticated
  with check ((select public.is_admin()) and created_by = (select auth.uid()));
create policy "movies: admin boleh ubah" on public.movies
  for update to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "movies: admin boleh hapus" on public.movies
  for delete to authenticated using ((select public.is_admin()));

-- bookmarks: tiap user hanya mengelola favoritnya sendiri
create policy "bookmarks: lihat milik sendiri" on public.bookmarks
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "bookmarks: tambah milik sendiri" on public.bookmarks
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "bookmarks: hapus milik sendiri" on public.bookmarks
  for delete to authenticated using ((select auth.uid()) = user_id);


-- ---------------------------------------------------------------------
-- Storage: poster yang dipilih dari galeri
-- File disimpan di posters/<user id>/<nama file>, bisa dibaca publik,
-- hanya admin yang boleh mengunggah / menghapus.
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('posters', 'posters', true)
on conflict (id) do nothing;

create policy "posters: admin upload" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'posters' and (select public.is_admin()));
create policy "posters: admin hapus" on storage.objects
  for delete to authenticated
  using (bucket_id = 'posters' and (select public.is_admin()));


-- ---------------------------------------------------------------------
-- Data awal: 7 film contoh (created_by = null → film bawaan)
-- ---------------------------------------------------------------------
insert into public.movies (title, poster_url, year, genres, duration, rating, synopsis, showtimes) values
  ('Jumbo', 'https://image.tmdb.org/t/p/w500/rbjTGOKWcL6xjhTMGhRN1YNejE5.jpg', 2025, array['Animasi', 'Keluarga']::text[], 102, 'SU',
   'Don, anak yatim piatu yang sering diremehkan karena badannya besar, ingin membuktikan diri lewat pentas bakat — dibantu sahabat-sahabatnya dan satu teman yang tak terduga.',
   '{"plaza-senayan-xxi": ["11:00", "13:15", "15:30"], "kokas-xxi": ["10:45", "13:00", "17:20"], "mkg-xxi": ["12:00", "14:15"], "margo-city-xxi": ["11:30", "13:45", "16:00"], "cipinang-xxi": ["12:15", "14:30"]}'::jsonb),
  ('Pengepungan di Bukit Duri', 'https://image.tmdb.org/t/p/w500/tx2toda5HijndqRZXDuoGkSud8L.jpg', 2025, array['Aksi', 'Thriller']::text[], 118, '17+',
   'Seorang guru yang mencari keponakannya terjebak di sekolah paling brutal di Jakarta, ketika kota mulai runtuh di sekelilingnya.',
   '{"senayan-city-xxi": ["14:00", "18:45", "21:30"], "cgv-grand-indonesia": ["13:30", "19:00", "21:45"], "central-park-xxi": ["15:10", "20:00"], "sms-xxi": ["16:30", "21:00"]}'::jsonb),
  ('Sore: Istri dari Masa Depan', 'https://image.tmdb.org/t/p/w500/u4pNXPmBuYeTtksakUCZgJ1zpSB.jpg', 2025, array['Drama', 'Romansa', 'Fantasi']::text[], 119, '13+',
   'Jonathan, fotografer yang hidup sendiri di Kroasia, tiba-tiba didatangi perempuan bernama Sore yang mengaku istrinya dari masa depan.',
   '{"plaza-senayan-xxi": ["16:00", "19:10"], "cgv-pacific-place": ["15:45", "20:15"], "metropole-xxi": ["14:20", "18:30"], "puri-xxi": ["17:00", "20:30"], "botani-xxi": ["15:00", "19:00"]}'::jsonb),
  ('The Odyssey', 'https://image.tmdb.org/t/p/w500/5rhTDKUhPYvpdQIijFIs5VoWsON.jpg', 2026, array['Epik', 'Petualangan']::text[], 165, '13+',
   'Perjalanan panjang Odysseus pulang ke Ithaca setelah Perang Troya, melewati laut, dewa, dan monster yang menguji tekadnya.',
   '{"gandaria-city-xxi": ["12:30", "16:10", "20:00"], "cgv-pacific-place": ["13:00", "17:00", "21:00"], "cgv-grand-indonesia": ["12:00", "16:00", "20:30"], "emporium-pluit-xxi": ["14:45", "19:15"], "smb-xxi": ["13:30", "18:00"]}'::jsonb),
  ('Spider-Man: Brand New Day', 'https://image.tmdb.org/t/p/w500/bjiS5ipwxb9JFy3XRRN4OAilSeX.jpg', 2026, array['Aksi', 'Superhero']::text[], 135, '13+',
   'Setelah dunia melupakan siapa dirinya, Peter Parker memulai hidup baru — sampai ancaman lama kembali mengetuk pintu.',
   '{"pim-xxi": ["11:15", "14:00", "17:45", "21:15"], "kokas-xxi": ["12:40", "16:20", "20:10"], "central-park-xxi": ["13:00", "16:45", "21:00"], "mkg-xxi": ["15:30", "19:45"], "cipinang-xxi": ["16:00", "20:00"], "margo-city-xxi": ["14:15", "18:30"]}'::jsonb),
  ('Toy Story 5', 'https://image.tmdb.org/t/p/w500/sfQtVlIHljToOwYjhe21KPGzZWK.jpg', 2026, array['Animasi', 'Komedi']::text[], 100, 'SU',
   'Woody, Buzz, dan kawan-kawan berhadapan dengan rival paling modern: sebuah tablet yang merebut perhatian anak-anak.',
   '{"senayan-city-xxi": ["10:30", "12:45"], "gandaria-city-xxi": ["11:00", "13:20", "15:40"], "puri-xxi": ["10:45", "13:00"], "emporium-pluit-xxi": ["11:30", "13:50"], "sms-xxi": ["10:40", "12:50", "15:00"], "botani-xxi": ["11:10", "13:30"]}'::jsonb),
  ('Michael', 'https://image.tmdb.org/t/p/w500/dueFqKLvjftnELZaGYwY7xinfaI.jpg', 2026, array['Biografi', 'Musikal']::text[], 128, '13+',
   'Kisah hidup Michael Jackson — dari panggung keluarga di Gary, Indiana, hingga menjadi Raja Pop dunia.',
   '{"pim-xxi": ["18:30", "21:40"], "metropole-xxi": ["19:00"], "cgv-grand-indonesia": ["18:15", "21:20"], "smb-xxi": ["19:30"]}'::jsonb);
