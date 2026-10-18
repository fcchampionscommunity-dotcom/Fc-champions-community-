-- FC Champions Community — Supabase schema
-- Run this whole file in Supabase Dashboard > SQL Editor.
-- This schema enables public read access for public tournament data and writes only for approved admins.

create extension if not exists pgcrypto;

create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Admin',
  role text not null default 'admin' check (role in ('owner','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.tournaments (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  season text not null default 'Season 1',
  format text not null default 'world_cup',
  status text not null default 'upcoming' check (status in ('registration','upcoming','ongoing','completed','archived')),
  max_players integer not null default 16 check (max_players between 2 and 1000),
  description text not null default '',
  format_settings jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.players (
  id uuid primary key default gen_random_uuid(),
  display_name text not null,
  game_username text not null default '',
  game_uid text not null default '',
  team_ovr integer check (team_ovr is null or team_ovr between 1 and 200),
  created_at timestamptz not null default now()
);

create unique index if not exists players_game_uid_unique_nonempty
  on public.players(game_uid) where game_uid <> '';

create table if not exists public.tournament_players (
  id uuid primary key default gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  player_id uuid not null references public.players(id) on delete cascade,
  group_name text,
  registration_status text not null default 'approved' check (registration_status in ('pending','approved','rejected')),
  created_at timestamptz not null default now(),
  unique (tournament_id, player_id)
);

create table if not exists public.matches (
  id uuid primary key default gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  home_player_id uuid references public.players(id) on delete set null,
  away_player_id uuid references public.players(id) on delete set null,
  home_name text not null default 'TBD',
  away_name text not null default 'TBD',
  home_score integer check (home_score is null or home_score between 0 and 99),
  away_score integer check (away_score is null or away_score between 0 and 99),
  status text not null default 'scheduled' check (status in ('scheduled','completed','postponed','cancelled')),
  group_name text,
  round_name text not null default 'Group Stage',
  scheduled_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (home_player_id is null or away_player_id is null or home_player_id <> away_player_id),
  check ((status <> 'completed') or (home_score is not null and away_score is not null))
);

create table if not exists public.tournament_champions (
  id uuid primary key default gen_random_uuid(),
  tournament_id uuid references public.tournaments(id) on delete set null,
  player_id uuid references public.players(id) on delete set null,
  player_name text not null,
  tournament_name text not null default 'FC Champions Community',
  season_label text not null default 'Season 1',
  placement integer not null check (placement in (1,2,3)),
  created_at timestamptz not null default now(),
  unique (tournament_id, placement)
);

create index if not exists matches_tournament_idx on public.matches(tournament_id);
create index if not exists matches_status_idx on public.matches(status);
create index if not exists tournament_players_tournament_idx on public.tournament_players(tournament_id);

-- Security helper functions. SECURITY DEFINER avoids RLS recursion on the admins table.
create or replace function public.is_fcc_admin()
returns boolean language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.admins a where a.user_id = auth.uid()); $$;

create or replace function public.is_fcc_owner()
returns boolean language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.admins a where a.user_id = auth.uid() and a.role = 'owner'); $$;

alter table public.admins enable row level security;
alter table public.tournaments enable row level security;
alter table public.players enable row level security;
alter table public.tournament_players enable row level security;
alter table public.matches enable row level security;
alter table public.tournament_champions enable row level security;

-- Public can read public-facing competition data.
drop policy if exists "Public read tournaments" on public.tournaments;
create policy "Public read tournaments" on public.tournaments for select using (true);
drop policy if exists "Public read players" on public.players;
create policy "Public read players" on public.players for select using (true);
drop policy if exists "Public read tournament players" on public.tournament_players;
create policy "Public read tournament players" on public.tournament_players for select using (true);
drop policy if exists "Public read matches" on public.matches;
create policy "Public read matches" on public.matches for select using (true);
drop policy if exists "Public read champions" on public.tournament_champions;
create policy "Public read champions" on public.tournament_champions for select using (true);

-- Only approved admins can create/update/delete tournament data.
drop policy if exists "Admins manage tournaments" on public.tournaments;
create policy "Admins manage tournaments" on public.tournaments for all using (public.is_fcc_admin()) with check (public.is_fcc_admin());
drop policy if exists "Admins manage players" on public.players;
create policy "Admins manage players" on public.players for all using (public.is_fcc_admin()) with check (public.is_fcc_admin());
drop policy if exists "Admins manage tournament players" on public.tournament_players;
create policy "Admins manage tournament players" on public.tournament_players for all using (public.is_fcc_admin()) with check (public.is_fcc_admin());
drop policy if exists "Admins manage matches" on public.matches;
create policy "Admins manage matches" on public.matches for all using (public.is_fcc_admin()) with check (public.is_fcc_admin());
drop policy if exists "Admins manage champions" on public.tournament_champions;
create policy "Admins manage champions" on public.tournament_champions for all using (public.is_fcc_admin()) with check (public.is_fcc_admin());

-- Admins can see their own role. Only owner can manage the admin list.
drop policy if exists "Admins read own row" on public.admins;
create policy "Admins read own row" on public.admins for select using (user_id = auth.uid() or public.is_fcc_owner());
drop policy if exists "Owner manages admins" on public.admins;
create policy "Owner manages admins" on public.admins for all using (public.is_fcc_owner()) with check (public.is_fcc_owner());

-- Helpful default privileges for Supabase's API roles.
grant usage on schema public to anon, authenticated;
grant select on public.tournaments, public.players, public.tournament_players, public.matches, public.tournament_champions to anon, authenticated;
grant select, insert, update, delete on public.admins, public.tournaments, public.players, public.tournament_players, public.matches, public.tournament_champions to authenticated;
