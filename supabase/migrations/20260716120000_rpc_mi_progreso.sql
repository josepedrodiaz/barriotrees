-- Cuánto lleva el vecino de cada criterio, para dibujar la escalera y las
-- insignias de mérito con su avance real ("3 de 5 rescates").
--
-- Los conteos se calculan acá y no en el navegador a propósito: la hora de
-- corte de Madrugador/Sereno depende de la zona horaria y de config, y si esa
-- cuenta se duplicara en JS, la pantalla terminaría diciendo una cosa y el
-- otorgamiento haciendo otra. Las claves de 'conteos' son las mismas que usa
-- insignias.criterio->>'evento'.

create function mi_progreso() returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  v_perfil uuid := auth.uid();
  v_tz text := 'America/Argentina/Buenos_Aires';
  v_hora_madrugada integer := (select (valor)::integer from config where clave = 'madrugador_hora_limite');
  v_hora_atardecer integer := (select (valor)::integer from config where clave = 'sereno_hora_inicio');
begin
  if v_perfil is null then
    return jsonb_build_object('ok', false, 'motivo', 'sin_sesion');
  end if;

  return jsonb_build_object(
    'ok', true,
    'puntos', (select puntos from perfiles where id = v_perfil),
    'riegos', (select count(*) from riegos where perfil_id = v_perfil),
    'conteos', jsonb_build_object(
      'rescate', (select count(*) from riegos
                  where perfil_id = v_perfil and estado_al_regar = 'muy_sediento'),
      'madrugada', (select count(*) from riegos
                    where perfil_id = v_perfil
                      and extract(hour from creado_en at time zone v_tz) < v_hora_madrugada),
      'atardecer', (select count(*) from riegos
                    where perfil_id = v_perfil
                      and extract(hour from creado_en at time zone v_tz) >= v_hora_atardecer),
      'reporte_verificado', (select count(*) from reportes
                             where perfil_id = v_perfil and estado = 'verificado')
    )
  );
end $$;
