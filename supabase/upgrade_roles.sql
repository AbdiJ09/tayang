-- =====================================================================
-- Tayang — upgrade: role admin & user
--
-- Untuk project yang SUDAH menjalankan schema.sql versi lama (sebelum ada
-- role). Project baru cukup menjalankan schema.sql terbaru, tidak perlu ini.
--
-- Cara pakai: Supabase Dashboard → SQL Editor → New query, tempel seluruh
-- isi file ini, klik Run. Cukup sekali.
--
-- Setelah ini:
--   - semua akun yang sudah ada menjadi 'user' (hanya bisa melihat);
--   - jadikan akunmu admin dengan query paling bawah.
-- =====================================================================

-- 1. Kolom role
alter table public.users
  add column role text not null default 'user' check (role in ('user', 'admin'));

-- 2. User tidak boleh mengubah role-nya sendiri: dari app hanya kolom
--    name yang boleh di-update.
revoke all on public.users from anon, authenticated;
grant select on public.users to authenticated;
grant update (name) on public.users to authenticated;

-- 3. Fungsi pengecek admin
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

-- 4. Film: hanya admin yang boleh tambah / ubah / hapus
drop policy "movies: user login boleh tambah" on public.movies;
drop policy "movies: pembuat boleh ubah" on public.movies;
drop policy "movies: pembuat boleh hapus" on public.movies;

create policy "movies: admin boleh tambah" on public.movies
  for insert to authenticated
  with check ((select public.is_admin()) and created_by = (select auth.uid()));
create policy "movies: admin boleh ubah" on public.movies
  for update to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "movies: admin boleh hapus" on public.movies
  for delete to authenticated using ((select public.is_admin()));

-- 5. Poster: hanya admin yang boleh unggah / hapus
drop policy "posters: user upload ke foldernya" on storage.objects;
drop policy "posters: user hapus filenya" on storage.objects;

create policy "posters: admin upload" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'posters' and (select public.is_admin()));
create policy "posters: admin hapus" on storage.objects
  for delete to authenticated
  using (bucket_id = 'posters' and (select public.is_admin()));


-- ---------------------------------------------------------------------
-- 6. Jadikan akunmu admin — ganti email di bawah dengan email akunmu.
-- ---------------------------------------------------------------------
update public.users set role = 'admin' where email = 'GANTI_DENGAN_EMAIL_KAMU';

-- Cek hasilnya:
select name, email, role from public.users order by created_at;
