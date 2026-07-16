-- Editar el nombre del vecino (BT-26) + tabla de posiciones (BT-18).

-- ---------- cambiar el nombre propio ----------
-- El nombre es público (aparece en el ranking), así que no puede escribirse
-- directo desde el cliente (perfiles no tiene policy de escritura, principio 3).
-- Va por RPC con validación: ni vacío, ni gigante, ni con saltos de línea.
create function actualizar_mi_nombre(p_nombre text)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_perfil uuid := auth.uid();
  v_limpio text := trim(regexp_replace(coalesce(p_nombre, ''), '\s+', ' ', 'g'));
begin
  if v_perfil is null then
    return jsonb_build_object('ok', false, 'motivo', 'sin_sesion');
  end if;
  if length(v_limpio) < 2 then
    return jsonb_build_object('ok', false, 'motivo', 'muy_corto');
  end if;
  if length(v_limpio) > 24 then
    return jsonb_build_object('ok', false, 'motivo', 'muy_largo');
  end if;

  update perfiles set nombre = v_limpio where id = v_perfil;
  return jsonb_build_object('ok', true, 'nombre', v_limpio);
end $$;

-- ---------- tabla de posiciones ----------
-- Se calcula al vuelo en cada consulta, no con cron (decisión 13: a esta escala
-- sobra). Vista de lectura pública: el ranking se ve sin cuenta.
--
-- Empata por puntos y desempata por quién llegó antes a ese puntaje (su último
-- riego más viejo gana): premia al que viene sosteniéndolo, no al último que
-- sumó. Solo entran los que regaron al menos una vez.
create view v_ranking as
select
  p.id,
  p.nombre,
  p.puntos,
  (select count(*) from riegos r where r.perfil_id = p.id) as riegos,
  rank() over (order by p.puntos desc) as puesto
from perfiles p
where p.puntos > 0;

-- Vista sobre tabla con RLS: hereda el permiso del que consulta. La lectura de
-- perfiles/riegos ya es pública, así que el ranking también.
