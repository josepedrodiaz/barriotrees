-- BUG (detectado por Pedro el 16-jul, regando en la plaza): los puntos nunca
-- llegaban al perfil y por lo tanto no se otorgaba ninguna insignia.
--
-- Causa: el trigger perfiles_proteger (BT-10) revertía `puntos` y `es_admin`
-- en TODO update hecho por un no-admin. Nació para que nadie se auto-inflara
-- el puntaje vía la API, pero no distinguía al tramposo de nuestras propias
-- RPC: registrar_riego y reclamar_riegos sumaban los puntos y el trigger los
-- devolvía a su valor anterior, en silencio.
--
-- Arreglo: cerrar la puerta en vez de vigilarla. Si el cliente no puede
-- escribir `perfiles`, el trigger no tiene sentido. Queda alineado con el
-- principio 3 de docs/arquitectura.md: el perfil lo tocan solo las RPC.
-- (Para editar el nombre, cuando haga falta, va una RPC dedicada.)

drop trigger perfiles_proteger on perfiles;
drop function proteger_campos_perfil();

-- Sin estas policies no hay ningún camino de escritura desde el cliente:
-- el perfil lo crea el trigger de auth y lo actualizan las RPC (security
-- definer), que no pasan por RLS.
drop policy perfil_propio_update on perfiles;
drop policy perfil_propio_insert on perfiles;

-- ---------- reparar los datos que el bug dejó mal ----------
-- El puntaje siempre estuvo bien guardado en cada riego; lo que faltaba era
-- el acumulado. Se recalcula desde la fuente de verdad.
update perfiles p
set puntos = coalesce((select sum(r.puntos) from riegos r where r.perfil_id = p.id), 0);

-- Y ahora sí, las insignias que se habían ganado en su momento.
select otorgar_insignias(id) from perfiles;
