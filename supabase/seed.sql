-- Seed LOCAL. Corre SOLO en tu máquina, con `supabase db reset` / `supabase start`.
-- NUNCA corre en producción: prod se despliega por migraciones vía CI, el seed no.
--
-- Por qué existe: en local el login por magic link (Supabase, flujo PKCE) entra
-- en un loop eterno por el mismo motivo de siempre — el verificador PKCE se
-- guarda en el localStorage de `localhost:5173` y cualquier salto a `127.0.0.1`
-- o segundo click lo pierde, así que la sesión vuelve null y te rebota a /entrar.
-- Y Google no está habilitado en local. Este seed crea un admin de desarrollo
-- para entrar sin mail ni Google, con un click.
--
--   usuario: josepedrodiaz@gmail.com   ·   contraseña: dev
--
-- OJO: el email TIENE que ser josepedrodiaz@gmail.com. es_admin() (migración
-- roles_entregador) decide admin por EMAIL en auth.users, NO por perfiles.es_admin.
-- Con cualquier otro email, las lecturas públicas andan pero TODO write de admin
-- da 0 filas (RLS), p.ej. mover un pin no persiste.
--
-- El botón "Entrar como dev (local)" en /entrar (visible solo con import.meta.env.DEV)
-- hace signInWithPassword contra este usuario. Ver docs/login-local-dev.md.

do $$
declare
  v_id uuid := '00000000-0000-0000-0000-0000000000ad';
begin
  if not exists (select 1 from auth.users where id = v_id) then
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at,
      raw_app_meta_data, raw_user_meta_data,
      confirmation_token, recovery_token, email_change_token_new, email_change
    ) values (
      '00000000-0000-0000-0000-000000000000', v_id, 'authenticated', 'authenticated',
      'josepedrodiaz@gmail.com', extensions.crypt('dev', extensions.gen_salt('bf')),
      now(), now(), now(),
      '{"provider":"email","providers":["email"]}', '{"full_name":"Dev Admin"}',
      '', '', '', ''
    );

    -- GoTrue necesita la identity de email para el login por contraseña.
    insert into auth.identities (
      id, user_id, identity_data, provider, provider_id,
      last_sign_in_at, created_at, updated_at
    ) values (
      gen_random_uuid(), v_id,
      jsonb_build_object('sub', v_id::text, 'email', 'josepedrodiaz@gmail.com'),
      'email', v_id::text,
      now(), now(), now()
    );
  end if;

  -- El trigger crear_perfil_al_registrarse ya creó el perfil con es_admin=false.
  -- Lo ascendemos con un UPDATE directo: el seed corre como postgres (saltea RLS)
  -- y la protección vieja (trigger perfiles_proteger) se eliminó en la migración
  -- 20260716030000 — hoy a perfiles solo lo tocan las RPC, nada revierte esto.
  update perfiles set es_admin = true, nombre = 'Dev Admin' where id = v_id;
end $$;

-- ---------------------------------------------------------------------------
-- Grants base para el cliente (SOLO LOCAL — esto es seed, no corre en prod).
--
-- En prod, anon/authenticated tienen SELECT/DML sobre las tablas por el default
-- histórico de Supabase. Un `db reset` local desde cero NO trae ese default:
-- las tablas base quedan sin select/DML y el cliente recibe 403 al leer perfiles,
-- arboles, etc. Esto lo repone para que local == prod. NO va como migración a
-- propósito: una migración correría en prod por CI y podría ensanchar permisos
-- allá; acá es local y no toca nada de producción.
--
-- RLS gobierna fila por fila en todas las tablas (todas tienen RLS on), así que
-- esto solo repone el permiso a nivel tabla.
grant usage on all sequences in schema public to anon, authenticated;
grant select on all tables in schema public to anon, authenticated;
grant insert, update, delete on all tables in schema public to authenticated;

-- REPONER el blindaje de la auditoría de seguridad que el grant de arriba pisó.
-- Copiado TAL CUAL de las migraciones de seguridad, para que local no exponga
-- lo que prod cierra:
--   · insignias_ganadas: sin SELECT (protege canje_token) — 20260716213000
--   · riegos: SELECT por columnas, sin dispositivo_id (no enumerable) — 20260920120000
revoke select on insignias_ganadas from anon, authenticated;
revoke select on riegos from anon, authenticated;
grant select (id, arbol_id, perfil_id, estado_al_regar, puntos, lat, lng, creado_en)
  on riegos to anon, authenticated;
