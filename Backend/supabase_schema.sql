-- KRYONIX backend blueprint. No credentials included.
create table if not exists couples (
  id uuid primary key default gen_random_uuid(),
  invite_code text unique not null,
  created_at timestamptz not null default now()
);

create table if not exists couple_members (
  couple_id uuid references couples(id) on delete cascade,
  user_id uuid not null,
  display_name text,
  nickname text,
  joined_at timestamptz not null default now(),
  primary key (couple_id, user_id)
);

create table if not exists messages (
  id uuid primary key,
  couple_id uuid references couples(id) on delete cascade not null,
  sender_id uuid not null,
  body text,
  media_url text,
  media_type text,
  reaction text,
  is_pinned boolean not null default false,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  edited_at timestamptz,
  read_at timestamptz
);

create table if not exists albums (
  id uuid primary key,
  couple_id uuid references couples(id) on delete cascade not null,
  name text not null,
  note text,
  favorite boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists memories (
  id uuid primary key,
  couple_id uuid references couples(id) on delete cascade not null,
  album_id uuid references albums(id) on delete cascade not null,
  owner_id uuid not null,
  media_url text not null,
  media_type text not null,
  title text,
  caption text,
  location_name text,
  favorite boolean not null default false,
  memory_date timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists stories (
  id uuid primary key,
  couple_id uuid references couples(id) on delete cascade not null,
  owner_id uuid not null,
  media_url text not null,
  media_type text not null,
  caption text,
  music_title text,
  music_artist text,
  music_url text,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  highlight boolean not null default false
);

create table if not exists story_views (
  story_id uuid references stories(id) on delete cascade,
  viewer_id uuid not null,
  viewed_at timestamptz not null default now(),
  primary key (story_id, viewer_id)
);

create table if not exists presence (
  couple_id uuid references couples(id) on delete cascade,
  user_id uuid not null,
  last_active timestamptz not null default now(),
  battery integer,
  latitude double precision,
  longitude double precision,
  location_updated_at timestamptz,
  sharing_location boolean not null default false,
  primary key (couple_id, user_id)
);
