# Respaldo Xofly a Google Drive — PROPUESTA NO ACTIVADA

## Estado
- Aislamiento: rama `dev/xofly-google-drive-backups-lab`, sin cambios a `main`, producción Vercel o Supabase.
- Solo `workflow_dispatch`: **sin horario diario y sin envío real**.
- Google Drive conectado a ChatGPT actualmente corresponde a `onovas01@gmail.com`. **No se autorizó aún que los datos de Xofly se almacenen ahí**. No se creó ninguna carpeta.
- Esta propuesta necesita escoger y autorizar la cuenta propietaria de la carpeta. Idealmente una cuenta del negocio controlada por la clienta, con acuerdo de acceso/retención. Si se usa cuenta del desarrollador, formalizarlo.

## Preparación pendiente
1. Definir cuenta Google Drive correcta y verificar que tenga espacio suficiente. No hay verificación de cuota disponible mediante la conexión actual.
2. Crear carpeta exclusiva no compartida `Xofly - Respaldos cifrados`; confirmar privacidad y recopilar ID de carpeta.
3. Configurar rclone Drive OAuth en un entorno seguro mediante flujo de autorización del titular. Configurar remoto `[xoflydrive]` con `type = drive`, `token` OAuth y `root_folder_id = <folder id>`. El acceso OAuth es una credencial sensible: guardar el archivo rclone.conf codificado en base64 **como GitHub Environment Secret**, no en el repositorio, comentarios ni conversaciones. El alcance OAuth se debe limitar cuanto permita el proveedor; verificar los permisos efectivos.
4. Crear clave age con `age-keygen`; conservar **clave privada fuera de GitHub, Drive y la máquina efímera de respaldo**, con una segunda copia segura y acceso de la persona responsable. Usar únicamente la clave pública `age1...` para cifrar en CI.
5. GitHub: crear environment `xofly-backups` con revisores requeridos y con autorización solo del branch aprobado. Secrets: `XOFLY_DB_PASSWORD`, `XOFLY_AGE_RECIPIENT`, `XOFLY_RCLONE_CONFIG_B64`. Nunca revelar valores.
6. Revisar seguridad del workflow: scripts, dependencias instaladas en runner, imagen `postgres:17` (anclar digest revisado antes de activar), retención de logs, fallos y cuotas. Realizar PR review antes de fusionar el código en main.
7. Ejecutar manualmente una prueba, verificar que Google Drive recibió un archivo cifrado y que contiene un dump legible tras descifrar.
8. Restaurar el dump en **PostgreSQL nuevo y aislado**, comprobar funciones, permisos, índices y conteos, además de compatibilidad del sitio.
9. **Importante:** este dump incluye solo esquema `public`; no asegura cobertura de Supabase Auth, Storage, roles de plataforma, configuraciones del proyecto ni funciones externas. Documentar y respaldar estos componentes por separado para poder recuperar toda la aplicación.
10. Solo tras pruebas, diseñar retención, auditoría mensual, avisos de fallo y `schedule` de GitHub Actions. El objetivo de costo es $0 **siempre sujeto** a cuotas vigentes de ambos servicios.

## Protección de datos
No subir archivos `.dump`, `.age`, contraseñas, tokens o archivos `rclone.conf` a GitHub. Los respaldos cifrados pueden tener información personal y necesitan una política de conservación. Un ZIP almacenado o la comprobación de tamaño remoto no demuestra que la restauración funciona.

## Referencias
- PR #2: auditoría de Xofly V5.
- PR #3: prototipo del cliente idempotente.
- PR #4: alternativa R2, sin activar. Elegir **solo uno** como destino de operación inicial y mantener el otro en borrador.
