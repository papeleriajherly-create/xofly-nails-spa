# Xofly V5 — evidencia de validación transaccional (2026-11-07)

**Alcance:** únicamente Supabase de laboratorio `kjkmlwehbyagbwvthlhk`. La base productiva `puibzkjpdpznlojrkftd` NO recibió escrituras. No constituye un test HTTP extremo a extremo ni demuestra que exista backup restaurable de producción.

## Comprobaciones ejecutadas y resultado

1. Se consultaron firmas y definiciones de `public.xofly_preprod_book_atomic` y `public.xofly_preprod_recover`; la primera conserva cuotas en tablas aisladas y ambas comprueban el mismo `request_id`.
2. La prueba negativa de tres condiciones terminó sin errores: UUID todo cero rechazado (SQLSTATE 22023), domingo rechazado (SQLSTATE 22023) y recuperación de solicitud inexistente sin filas.
3. Se ejecutó un bloque SQL `DO` con subtransacción PL/pgSQL y datos **enteramente ficticios**: `2026-12-15 16:00`, teléfono `0000000000`, `request_id=bc95c1a3-6dbc-444f-aac4-4a36c591ca73`. El bloque comprueba con excepciones que:
   - la primera llamada a `xofly_preprod_book_atomic` devuelve un UUID nuevo y `was_replayed=false, quota_allowed=true`;
   - repetir el mismo payload/requestId devuelve **exactamente** el mismo UUID con `was_replayed=true`;
   - `xofly_preprod_recover` devuelve ese UUID y `was_replayed=true`;
   - antes de revertir hay **una** fila de cita y el total de `hits` de las dos cuotas es **2** (no se cobran reintentos);
   - intentar recuperar el mismo ID cambiando el servicio se rechaza con SQLSTATE 22023.
4. El bloque fuerza una excepción exclusiva `P9001` para **revertir todas las escrituras del ensayo**. Después comprueba que no quedaron filas en las dos tablas. Terminó exitosamente, sin excepción no controlada.
5. Una consulta separada posterior devolvió `citas_laboratorio=0`, `cuotas_laboratorio=0`.

**Precisión:** prueba SQL transaccional ejecutada, **no** HTTP ni Turnstile real. No se modificó la bandera que permite POST en el laboratorio. No se ha confirmado el respaldo restaurable, y ninguna función se modificó en producción.

## Riesgos abiertos y exigencias de salida
- Backup real de producción más restauración comprobada en destino aislado (no basta con disponibilidad de proyecto ni conteos).
- Turnstile real desde hostname autorizado y POST HTTP en ventana de prueba con `testWriteGateOpen=true`, sin ampliar silenciosamente la expiración. Probar respuesta perdida, recuperación, datos alterados y límites; verificar cero registros al finalizar.
- Adaptación del formulario real, pruebas móviles, CORS, errores, no divulgación de claves y protección de datos; PR separado antes de publicar.
- Revisión de funciones anónimas `SECURITY DEFINER` productivas con plan de migración escalonada y reversión; no revocar hasta que el cliente ya opere a través de la API protegida.
- Autorización expresa de cambio productivo **después** de verificar backup y Preview.

## Estado protegido
- GitHub `main`: sin cambios.
- Vercel productivo: sin cambios.
- Supabase productivo: sin cambios.
- Laboratorio: cero filas persistidas por esta prueba.
