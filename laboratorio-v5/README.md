# Xofly V5 — prototipo de cliente, NO listo para integrar

Este directorio **no es parte del sitio publicado**. No importar ni desplegar sin revisar el contrato real de `/api/xofly-reservar` y el HTML actual de 3.6 MB.

## Ejecutar ensayos de código
```bash
node --test laboratorio-v5/booking-client.test.mjs
```
Diez casos definidos para Node: 6 verificaciones de entrada y 4 rutas de creación, recuperación, incertidumbre y fallo HTTP. La versión local equivalente se ejecutó el 7 de noviembre de 2026 con 10/10 aprobados; las pruebas agregadas a GitHub necesitan repetirse desde un checkout del commit exacto antes de aprobar el PR.

## Supuestos pendientes de contrastar
- `turnstileToken` es nombre de campo **provisional**. La API de Vercel puede esperar otro contrato.
- `op:'recover'` es **provisional**. Confirmar operación y endpoint de recuperación reales. No asumir que la API pública permite recuperar sin desafío.
- `/api/xofly-reservar` es la ruta preparada en laboratorio V5.17, pero la producción actual NO está integrada.
- Los checks de horario del navegador son solo UX: servidor y SQL mantienen autoridad. Las reglas de fechas en zona `America/Mexico_City` deben ser verificadas en Preview.
- No se han realizado pruebas con token real de Cloudflare ni POST HTTP completo. No utilizar claves secretas en HTML ni exponer datos personales.

## Condiciones antes de conectar
1. Obtener fuente real del formulario y localizar la función exacta que hoy llama a RPC de Supabase.
2. Validar contrato de JSON y respuesta de `/api/xofly-reservar` y `/api/xofly-lab-v521`, incluyendo campos reales de Turnstile.
3. Integrar únicamente en Preview aislado protegido, conservando control de errores, accesibilidad y estado incierto después de error de red.
4. Prueba Turnstile real con escrituras ficticias, expiración de bandera, recuperación del mismo comprobante y cero residuos.
5. Respaldo productivo restaurable y autorización explícita antes de cualquier publicación.

Este código NO debe fusionarse ni activar el formulario real. El PR permanece en borrador.
