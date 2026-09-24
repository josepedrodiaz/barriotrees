-- Arte propio + copys nuevos para la escalera de insignias.
--
-- El arte lo hizo el equipo de arte: un .jpeg por pin, en static/pines/ (se
-- sirve en /pines/<slug>.jpeg). Los `id` de las insignias NO se tocan (son PK y
-- FK de insignias_ganadas): solo cambian el nombre visible, el copy y se agrega
-- la columna `imagen`. Las de mérito (rescatista/madrugador/sereno/centinela)
-- quedan con imagen null → siguen usando el Pin genérico hasta tener su arte.

alter table insignias add column if not exists imagen text;

update insignias set nombre = 'Primer Riego', imagen = '/pines/primer-riego.jpeg',
  copy_desbloqueo = 'Tu primer balde. Todos los gigantes de la plaza empezaron por acá.'
  where id = 'primer-riego';

update insignias set nombre = 'Primeros Brotes', imagen = '/pines/primeros-brotes.jpeg',
  copy_desbloqueo = 'Volviste, y varias veces. El hábito ya asoma, como estos brotes.'
  where id = 'aprendiz';

update insignias set nombre = 'Tierra Fértil', imagen = '/pines/tierra-fertil.jpeg',
  copy_desbloqueo = 'Ya sos de la plaza. Bienvenido al clan de cuidadores.'
  where id = 'cuidador';

update insignias set nombre = 'Manos Cuidadoras', imagen = '/pines/manos-cuidadoras.jpeg',
  copy_desbloqueo = 'Gracias por no aflojar! La plaza crece porque hay manos como las tuyas.'
  where id = 'gran-cuidador';

update insignias set nombre = 'Raíz del Barrio', imagen = '/pines/raiz-del-barrio.jpeg',
  copy_desbloqueo = 'Ya no venís de visita: echaste raíz.'
  where id = 'raiz-del-barrio';

update insignias set nombre = 'Alma de la Plaza', imagen = '/pines/alma-de-la-plaza.jpeg',
  copy_desbloqueo = 'Sos de los pocos que llegan hasta acá. La plaza tiene alma por gente como vos.'
  where id = 'alma-de-la-plaza';

update insignias set nombre = 'Gigante del Oeste', imagen = '/pines/gigante-del-oeste.jpeg',
  copy_desbloqueo = 'El último peldaño. El nombre del barrio ahora es tuyo. Felicitaciones!'
  where id = 'gigante-del-oeste';

-- otorgar_insignias: el payload que ve el cliente al ganar una insignia ahora
-- incluye `imagen` (idéntica al original salvo ese campo).
create or replace function otorgar_insignias(p_perfil uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_total integer;
  v_tz text := 'America/Argentina/Buenos_Aires';
  v_nuevas jsonb;
begin
  select puntos into v_total from perfiles where id = p_perfil;
  if v_total is null then
    return '[]'::jsonb;
  end if;

  with candidatas as (
    select i.id from insignias i
    where i.activa
      and (
        (i.tipo = 'escalera' and i.umbral_puntos <= v_total)
        or (i.id = 'rescatista'
            and (select count(*) from riegos r
                 where r.perfil_id = p_perfil and r.estado_al_regar = 'muy_sediento')
                >= (select (valor)::integer from config where clave = 'rescatista_n'))
        or (i.id = 'madrugador'
            and (select count(*) from riegos r
                 where r.perfil_id = p_perfil
                   and extract(hour from r.creado_en at time zone v_tz)
                       < (select (valor)::integer from config where clave = 'madrugador_hora_limite'))
                >= (select (valor)::integer from config where clave = 'madrugador_n'))
        or (i.id = 'sereno'
            and (select count(*) from riegos r
                 where r.perfil_id = p_perfil
                   and extract(hour from r.creado_en at time zone v_tz)
                       >= (select (valor)::integer from config where clave = 'sereno_hora_inicio'))
                >= (select (valor)::integer from config where clave = 'sereno_n'))
      )
      and not exists (select 1 from insignias_ganadas g
                      where g.perfil_id = p_perfil and g.insignia_id = i.id)
  ), ins as (
    insert into insignias_ganadas (perfil_id, insignia_id)
    select p_perfil, id from candidatas
    returning insignia_id
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', i.id, 'nombre', i.nombre, 'copy', i.copy_desbloqueo, 'imagen', i.imagen)), '[]'::jsonb)
  into v_nuevas
  from ins join insignias i on i.id = ins.insignia_id;

  return v_nuevas;
end $$;
