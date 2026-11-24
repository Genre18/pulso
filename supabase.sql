-- Operaciones del diario
create table public.operaciones (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  fecha timestamptz not null default now(),
  par text not null default 'EUR/USD',
  cuenta text not null default 'real' check (cuenta in ('real','demo')),
  direccion text not null check (direccion in ('arriba','abajo')),
  monto numeric(12,2) not null check (monto > 0),
  pago numeric(5,2) not null default 85 check (pago > 0 and pago <= 100),
  vencimiento_min int,
  resultado text not null check (resultado in ('gano','perdio','empate')),
  motivo text not null check (motivo in ('tendencia','soporte_resistencia','ruptura','noticia','corazonada','otro')),
  siguio_reglas boolean not null,
  emocion text check (emocion in ('tranquila','ansiosa','recuperar','euforica','cansada')),
  nota text,
  creado timestamptz not null default now()
);
create index on public.operaciones (user_id, fecha desc);

-- Lista "antes de operar", una fila por dia
create table public.checklist_diario (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  fecha date not null,
  items jsonb not null default '{}',
  primary key (user_id, fecha)
);

-- Tus reglas personales
create table public.ajustes (
  user_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  max_operaciones int not null default 3,
  max_perdidas_seguidas int not null default 3,
  pago_habitual numeric(5,2) not null default 85,
  monto_habitual numeric(12,2),
  moneda text not null default 'USD'
);

-- Seguridad: cada quien ve y toca SOLO sus datos
alter table public.operaciones enable row level security;
alter table public.checklist_diario enable row level security;
alter table public.ajustes enable row level security;

create policy "propias" on public.operaciones for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "propias" on public.checklist_diario for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "propias" on public.ajustes for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
-- Permisos para la usuaria con sesion iniciada (la seguridad por fila sigue limitando a SUS datos)
grant select, insert, update, delete on public.operaciones, public.checklist_diario, public.ajustes to authenticated;
