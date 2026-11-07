# Xofly Nails & Spa — control de salida V5 (2026-11-07)

Este archivo es un registro de evidencias, **no** una autorización para desplegar en producción. Se preparó exclusivamente en la rama `audit/xofly-v5-20261107-readiness`; `main`, Supabase productivo y Vercel productivo quedan fuera de alcance.

## Destinos fijados y comprobados
- GitHub: `papeleriajherly-create/xofly-nails-spa`, `main` en commit `fe8980238c794468157f8c59682f753432985516` (versión desplegada, 2026-10-08).
- Producción Supabase: `puibzkjpdpznlojrkftd` — **NO ejecutar pruebas con escritura**.
- Laboratorio Supabase: `kjkmlwehbyagbwvthlhk`.
- Producción Vercel: `prj_2CbO1Q6VhtZ4RT5dLbvHITytjXt0`.
- Laboratorio Vercel: `prj_OLGEnaHLu5k7TK2q3j8HDZmnwxPI`; hostname fijo `xofly-seguridad-staging.vercel.app`.

## Evidencia observada el 2026-11-07
- GitHub permite escritura a la cuenta correcta; no se ha mezclado ninguna corrección en `main`.
- El laboratorio Vercel devuelve HTTP 200 para `/api/estado-seguridad`, `/api/estado-laboratorio-v526`, `/api/turnstile-config`, `/api/horarios?fecha=2026-11-09` (consultas efectuadas a través del conector autenticado). La última responde `origen=staging` y `soloLectura=true`.
- `/api/estado-laboratorio-v526` confirma `preview=true`, `isolatedProject=true`, `publicBookingsClosed=true`, `labFlagSet=false`, `testWriteGateOpen=false`; vence `2026-11-08T04:00:00Z`.
- Laboratorio: ocho funciones Xofly examinadas, ninguna ejecutable por `anon`; cuatro tablas de laboratorio con RLS activado. `xofly_preprod_appointments.request_id` posee UNIQUE.
- Producción: las funciones `xofly_book_slot`, `xofly_busy_slots`, `xofly_horarios_ocupados` y `xofly_solicitar_cita` siguen ejecutables por `anon` y son `SECURITY DEFINER`. **Riesgo abierto**; no revocar a ciegas porque la página usa rutas heredadas.
- No se ha certificado un respaldo restaurable de Supabase productivo. El conector disponible no ofrece inventario ni ejecución de restauración de backups; un estado ACTIVE_HEALTHY no acredita backups.
- La raíz del laboratorio anuncia reservas desactivadas. El ensayo integral con Turnstile real y pérdida de respuesta **no está certificado**; los GET no prueban POST.

## Criterios de aprobación pendientes (obligatorios)
- [ ] Obtener backup consistente de producción y documentar fecha, punto de recuperación, cobertura (esquema, datos, permisos y configuraciones relevantes), ubicación, retención y persona responsable.
- [ ] Restaurar una copia en un destino **nuevo y aislado**, comprobar integridad y al menos una lectura funcional; nunca restaurar sobre producción ni sobre staging sin plan.
- [ ] Confirmar en laboratorio que POST público falla cerrado y que solamente el endpoint de prueba habilitado para la ventana autorizada acepta **datos totalmente ficticios**.
- [ ] Ejecutar Turnstile real en el hostname exacto, un único POST con requestId UUID, simular respuesta perdida, recuperar el mismo ID sin consumir otro desafío/cuota; comparar conteos de registros y límites antes/después.
- [ ] Verificar antirreplay (mismo requestId con carga distinta debe rechazarse), cuota, horarios, conflictos, validaciones, errores de Supabase y ausencia de datos personales en logs.
- [ ] Comprobar caducidad y desactivación automática del permiso de escritura de laboratorio.
- [ ] Preparar adaptación de formulario real en rama separada (sin apuntar el navegador directamente a RPC privilegiadas), probar CORS/headers, mobile y accesibilidad. Revisar y aprobar PR.
- [ ] Cortar acceso anónimo a RPC heredadas **solo tras** verificar que el frontend nuevo usa la API protegida, que existe respaldo restaurable y que se aprobó despliegue separado.
- [ ] Probar en Preview de integración con configuración de prueba; preparar rollback de Vercel y reversión SQL revisada.
- [ ] Autorización expresa para ventana de producción, migración y promoción; monitoreo posterior.

## Orden de publicación segura
1. Backup verificable y simulacro de recuperación.
2. Completar ensayo de laboratorio antes de su expiración o crear una nueva ventana explícita, nunca ampliar silenciosamente.
3. PR de integración y Preview seguro, con pruebas completas y aprobación de la clienta.
4. Construir deployment productivo sin asignar dominio, inspeccionar configuración y regresión, aprobar promoción.
5. Promover el deployment autorizado; observar el formulario y reservas reales sin crear pruebas ficticias en producción.
6. Restringir RPC heredadas con una migración revisada **después de confirmar que no hay llamadas residuales**. Mantener plan de reversión; consultar métricas de errores.
7. Ante 5xx, errores de registro o pérdida de funciones: revertir Vercel al deployment productivo previo y ejecutar solo la reversión SQL necesaria y previamente probada; conservar evidencias y detener nuevos cambios.

## Prohibiciones
- No desplegar este informe ni scripts en producción; no rotar credenciales ni cambiar permisos de producción sin ventana autorizada.
- Nunca insertar datos ficticios en producción, habilitar el modo de laboratorio en el proyecto productivo ni copiar claves de servicio a cliente.
- Nunca interpretar HTTP 200 de un GET como aprobación de un circuito completo de reservas.
