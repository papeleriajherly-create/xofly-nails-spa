# Xofly Nails & Spa — respaldo cifrado a Cloudflare R2 (preparación)

**NO ESTÁ ACTIVO.** El workflow `.github/workflows/xofly-backup-manual.yml` solo tiene `workflow_dispatch`, sin `schedule`, y esta rama no es `main`. No se ha creado ningún respaldo remoto ni se han consultado secretos. No se desplegará a Vercel.

## Arquitectura y alcance
- Fuente: Supabase productivo `puibzkjpdpznlojrkftd`, conexión Session Pooler IPv4 en `aws-1-us-west-2.pooler.supabase.com:5432`, usuario `postgres.puibzkjpdpznlojrkftd`.
- `pg_dump` cliente PostgreSQL 17, archivo custom `public`. Incluye tablas Xofly del esquema public (citas, clientas, servicios, tratamientos, pagos). Es un respaldo **parcial** de la plataforma: NO garantiza recuperar Auth, Storage, configuraciones del proyecto, Edge Functions ni secretos.
- Cifrado `age` con clave pública del administrador; su clave privada **nunca** se comparte con GitHub ni Cloudflare.
- Destino: bucket **privado** R2 mediante API S3; no GitHub Artifacts, no Git LFS y no archivo dentro del repositorio.
- Validación de exportación: `pg_restore --list` y presencia de `xofly_appointments`. Validación de subida: comparación de tamaños. **No equivale a restauración satisfactoria.**
- No comprometer el proyecto por costos: revisar cuotas de GitHub Actions, facturación/uso de R2 y egreso, sin prometer $0 permanente.

## Configuración que debe realizar el propietario (sin compartir contraseñas aquí)
1. Crear una cuenta de Cloudflare R2 y un bucket privado exclusivo de Xofly; verificar costos y facturación **antes** de habilitarlo. Configurar lifecycle y retención apropiada, p. ej. 7–14 copias diarias, con control de acceso. Preferir una cuenta que controle el propietario; si es de tu clienta, documentar titularidad y acceso.
2. Crear una credencial de R2 limitada al bucket con permiso de escribir y consultar objetos. Evitar tokens de cuenta con permisos globales.
3. Generar un par de claves `age` **en un equipo seguro controlado por el responsable** y guardar la clave privada en dos lugares privados, independientes del repositorio/R2. GitHub únicamente recibe la cadena pública `age1...`. Sin clave privada no podrá restaurarse el archivo.
4. En GitHub → Settings → Environments, crear `xofly-backups`; añadir aprobación de revisores y restringir a rama `main` después de revisar el PR. Limitar permisos de Actions según política del repositorio.
5. Crear estos **secrets de environment**, no variables públicas:
   - `XOFLY_DB_PASSWORD`: contraseña de base de datos Supabase del usuario indicado. No compartirla por chat ni incluir URI completa en logs.
   - `XOFLY_R2_ENDPOINT`: `https://<ACCOUNT_ID>.r2.cloudflarestorage.com`.
   - `XOFLY_R2_BUCKET`: nombre exacto del bucket privado.
   - `XOFLY_R2_ACCESS_KEY_ID` y `XOFLY_R2_SECRET_ACCESS_KEY`: credenciales limitadas del bucket.
   - `XOFLY_AGE_RECIPIENT`: clave **pública** de cifrado `age1...`.
6. Revisar PR y solo entonces integrar el workflow a `main`. Ejecutar `workflow_dispatch` con aprobación. Comprobar archivo cifrado en R2, tamaño y registro de ejecución sin datos de clientas.
7. Descargar **una** copia desde R2 a un entorno aislado, descifrar con la clave privada, ejecutar `pg_restore --list` y restaurar en PostgreSQL 17 **nuevo y vacío**. Comprobar tablas, relaciones, procedimientos, índices y conteos sin publicar datos personales. No restaurar en producción ni staging.
8. Validar cobertura de `auth`, `storage`, roles, extensiones y configuración del sistema; diseñar respaldos separados para lo que falte. Solo entonces declarar recuperable el sitio.
9. Una vez que una restauración esté acreditada, abrir otro PR para agregar `schedule` (por ejemplo `0 9 * * *` UTC, ~3 a. m. CDMX), alertas por fallo, retención y monitoreo mensual. No habilitar `schedule` por anticipado.

## Riesgos a revisar
- Los programas en GitHub Actions pueden consumir minutos de ejecución. R2 puede cobrar almacenamiento u operaciones fuera de su cuota. El precio inicial de desarrollo de $2,500 MXN no contempla necesariamente cuotas futuras.
- Si se pierde la clave privada `age`, los respaldos cifrados son irrecuperables.
- El archivo de exportación contiene datos sensibles durante la ejecución del runner. Se crea con `umask 077`, se elimina antes de subir y el runner es efímero; utilizar siempre políticas de acceso y secretos del environment. Nunca imprimirlo ni subirlo a un artifact.
- No desplegar ni publicar scripts con credenciales en su código. El nombre del host y usuario no son secretos; la contraseña sí.
- Un archivo comprimido válido y un `head-object` correcto no prueban una recuperación exitosa. La aprobación final requiere restaurar.
- Si cambia el host, puerto, versión de PostgreSQL o contraseña, modificar el script mediante un PR revisado.
