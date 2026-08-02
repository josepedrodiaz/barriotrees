-- Poblar y limpiar el sandbox de pruebas (BT-40).
--
-- Para ensayar el circuito hace falta más de un árbol: el cooldown deja regar
-- cada árbol una vez cada 12h, así que con uno solo se prueba una vez y listo.
-- Y como los riegos de mentira dan puntos e insignias reales, el borrado tiene
-- que devolver esas cuentas a como estaban — si no, el ranking queda inflado.
--
-- Los árboles de prueba se identifican SIEMPRE por el código: `test-...`.
-- Ese es el contrato; no crear árboles reales con ese prefijo.

-- ---------- poblar ----------
-- Idempotente: crea los que falten hasta llegar a p_cantidad. Sin coordenadas
-- (no exigen proximidad, se prueba desde casa) y con F propia baja, para que
-- pidan agua aunque acabe de llover.
create function poblar_pruebas(p_cantidad integer default 10)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_especie uuid := (select id from especies where nombre_comun = 'Jacarandá');
  v_creados integer := 0;
  i integer;
  v_codigo text;
begin
  if not es_admin() then
    return jsonb_build_object('ok', false, 'motivo', 'no_admin');
  end if;
  if p_cantidad is null or p_cantidad < 1 or p_cantidad > 50 then
    return jsonb_build_object('ok', false, 'motivo', 'cantidad_invalida');
  end if;
  if v_especie is null then
    return jsonb_build_object('ok', false, 'motivo', 'sin_especie');
  end if;

  for i in 1..p_cantidad loop
    v_codigo := 'test-' || lpad(i::text, 2, '0');
    insert into arboles (codigo, especie_id, nombre, sector, frecuencia_dias_override, activo)
    select v_codigo, v_especie, 'Árbol de pruebas ' || i, 'Pruebas', 0.4, true
    where not exists (select 1 from arboles where codigo = v_codigo);
    if found then v_creados := v_creados + 1; end if;
  end loop;

  return jsonb_build_object('ok', true, 'creados', v_creados, 'total', p_cantidad);
end $$;

-- ---------- limpiar ----------
-- Borra todo rastro de las pruebas y deja las cuentas como si no hubieran
-- pasado. Tres cuidados, los tres aprendidos de una revisión que encontró el
-- daño ANTES de que tocara producción:
--
-- 1. TODO se acota a los perfiles que efectivamente regaron un árbol de prueba.
--    Un borrado global de insignias pendientes se llevaba puestas las de
--    vecinos que nunca tocaron un árbol test.
-- 2. Los puntos se descuentan en RELATIVO (puntos - delta), no recalculando el
--    total. Si un vecino riega justo mientras corre la limpieza, recalcular el
--    total pisaba su riego recién hecho; restar no.
-- 3. Las insignias que sobreviven recuperan su `canje_token` y su `ganada_en`
--    originales. Borrarlas y re-otorgarlas las devuelve como filas NUEVAS: QR
--    de canje distinto (el que el vecino tenga guardado deja de servir) y fecha
--    de logro pisada. Por eso se saca una foto antes y se restaura después.
--
-- Las YA ENTREGADAS no se borran nunca: ese pin físico está en la mano de
-- alguien, sacarlo del sistema sería mentir sobre el mundo real.
create function limpiar_pruebas()
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_riegos integer := 0;
  v_arboles integer := 0;
  v_perfiles integer := 0;
  r record;
begin
  if not es_admin() then
    return jsonb_build_object('ok', false, 'motivo', 'no_admin');
  end if;

  create temp table _afectados on commit drop as
  select r2.perfil_id, sum(r2.puntos)::integer as delta
  from riegos r2
  where r2.arbol_id in (select id from arboles where codigo like 'test-%')
    and r2.perfil_id is not null
  group by r2.perfil_id;

  -- La foto de las insignias de esos perfiles, para devolverles después el
  -- token y la fecha a las que sigan correspondiendo.
  create temp table _foto on commit drop as
  select g.perfil_id, g.insignia_id, g.ganada_en, g.canje_token
  from insignias_ganadas g
  where g.perfil_id in (select perfil_id from _afectados);

  -- Borrar en orden: ninguna de estas FK cascadea.
  delete from reportes where arbol_id in (select id from arboles where codigo like 'test-%');
  delete from riegos where arbol_id in (select id from arboles where codigo like 'test-%');
  get diagnostics v_riegos = row_count;
  delete from arboles where codigo like 'test-%';
  get diagnostics v_arboles = row_count;

  update perfiles p
  set puntos = greatest(0, p.puntos - a.delta)
  from _afectados a
  where p.id = a.perfil_id;
  get diagnostics v_perfiles = row_count;

  -- Las insignias no se pueden "descontar" una por una (otorgar_insignias solo
  -- suma), así que se borran las pendientes DE LOS AFECTADOS y se vuelven a
  -- otorgar sobre los datos ya limpios: la función existente decide qué
  -- corresponde, sin duplicar acá los criterios.
  delete from insignias_ganadas g
  where g.canje_estado = 'pendiente'
    and g.perfil_id in (select perfil_id from _afectados);

  for r in select perfil_id from _afectados loop
    perform otorgar_insignias(r.perfil_id);
  end loop;

  -- Y las que volvieron recuperan su identidad original.
  update insignias_ganadas g
  set ganada_en = f.ganada_en, canje_token = f.canje_token
  from _foto f
  where g.perfil_id = f.perfil_id and g.insignia_id = f.insignia_id;

  return jsonb_build_object(
    'ok', true,
    'riegos_borrados', v_riegos,
    'arboles_borrados', v_arboles,
    'perfiles_ajustados', v_perfiles
  );
end $$;
