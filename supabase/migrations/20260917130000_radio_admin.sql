-- Radio de proximidad manejable desde el admin + vuelta a producción (50 m).

-- 1) Valor de producción ya, revierte la migración temporal 20260802100000_radio_pruebas.
update config set valor = '50' where clave = 'radio_proximidad_metros';

-- 2) RPC para que el admin cambie el radio en vivo (sin migraciones).
--    `config.valor` es jsonb: guardamos un JSON number con to_jsonb() para que el RPC
--    de riego lo siga leyendo con (valor)::numeric. (p_metros::text no castea a jsonb.)
create or replace function set_radio_proximidad(p_metros integer)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not es_admin() then
    return jsonb_build_object('ok', false, 'motivo', 'no_admin');
  end if;
  if p_metros is null or p_metros < 1 or p_metros > 5000 then
    return jsonb_build_object('ok', false, 'motivo', 'fuera_de_rango');
  end if;
  update config set valor = to_jsonb(p_metros) where clave = 'radio_proximidad_metros';
  return jsonb_build_object('ok', true, 'metros', p_metros);
end $$;

-- 3) resetear_juego ahora TAMBIÉN deja el radio en producción (50 m), para que
--    "arrancar el juego real" sea atómico. El resto de la lógica queda igual.
create or replace function resetear_juego() returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_riegos integer;
  v_insignias integer;
  v_arboles integer;
begin
  if not es_admin() then
    return jsonb_build_object('ok', false, 'motivo', 'no_admin');
  end if;

  -- Orden por las FK (ninguna cascadea entre estas tablas).
  delete from insignias_ganadas;           -- incluye las entregadas, a propósito
  get diagnostics v_insignias = row_count;

  delete from reportes;
  delete from riegos;
  get diagnostics v_riegos = row_count;

  delete from arboles where codigo like 'test-%';
  get diagnostics v_arboles = row_count;

  update perfiles set puntos = 0 where puntos <> 0;

  update config set valor = '50' where clave = 'radio_proximidad_metros';

  return jsonb_build_object(
    'ok', true,
    'riegos_borrados', v_riegos,
    'insignias_borradas', v_insignias,
    'arboles_prueba_borrados', v_arboles
  );
end $$;
