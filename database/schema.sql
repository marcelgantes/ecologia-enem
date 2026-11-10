-- Ecologia ENEM — esquema inicial do banco
-- Execute no SQL Editor do projeto Supabase.
create extension if not exists pgcrypto;

create table if not exists public.student_attempts (
  id uuid primary key default gen_random_uuid(),
  student_name text not null check (char_length(trim(student_name)) between 2 and 100),
  email text not null check (char_length(email) <= 254),
  whatsapp text not null check (char_length(whatsapp) between 8 and 25),
  consent_email boolean not null default false,
  consent_whatsapp boolean not null default false,
  consent_recorded_at timestamptz,
  privacy_notice_version text not null default '1.0',
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  correct_count smallint check (correct_count between 0 and 28),
  question_count smallint not null default 28 check (question_count = 28),
  percentage numeric(5,2) check (percentage between 0 and 100),
  status text not null default 'in_progress' check (status in ('in_progress','completed'))
);

create table if not exists public.student_answers (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.student_attempts(id) on delete cascade,
  question_number smallint not null check (question_number between 1 and 28),
  selected_option smallint not null check (selected_option between 0 and 4),
  answered_at timestamptz not null default now(),
  unique (attempt_id, question_number)
);

alter table public.student_attempts enable row level security;
alter table public.student_answers enable row level security;

-- O navegador pode inserir inscrições e respostas, mas não pode consultar
-- ou baixar cadastros de outros estudantes.
drop policy if exists "public_insert_student_attempts" on public.student_attempts;
create policy "public_insert_student_attempts"
on public.student_attempts for insert
to anon
with check (
  char_length(trim(student_name)) between 2 and 100
  and consent_email in (true, false)
  and consent_whatsapp in (true, false)
);

drop policy if exists "public_insert_student_answers" on public.student_answers;
create policy "public_insert_student_answers"
on public.student_answers for insert
to anon
with check (
  question_number between 1 and 28
  and selected_option between 0 and 4
);

-- Nenhuma política de SELECT/UPDATE/DELETE é criada para anon.
-- Consultas administrativas devem usar autenticação e políticas próprias.
