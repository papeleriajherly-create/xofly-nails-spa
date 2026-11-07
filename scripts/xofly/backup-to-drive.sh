#!/usr/bin/env bash
# Xofly: exportar exclusivamente public, cifrar localmente y cargar a Google Drive.
# NO ejecutar hasta configurar cuenta correcta, clave age y entorno GitHub protegido.
set -Eeuo pipefail
umask 077
for name in XOFLY_DB_PASSWORD XOFLY_AGE_RECIPIENT XOFLY_RCLONE_CONFIG_B64; do
  if [[ -z "${!name:-}" ]]; then echo "Falta variable privada: $name" >&2; exit 2; fi
done
[[ "$XOFLY_AGE_RECIPIENT" =~ ^age1[a-z0-9]+$ ]] || { echo "Clave publica age invalida" >&2; exit 2; }
# Los paquetes y la imagen requieren revision/actualizacion de seguridad antes de activar.
sudo apt-get update -qq >/dev/null
sudo apt-get install -y -qq age rclone >/dev/null
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
config="$work/rclone.conf"
printf '%s' "$XOFLY_RCLONE_CONFIG_B64" | base64 -d > "$config"
chmod 600 "$config"
unset XOFLY_RCLONE_CONFIG_B64
# Requiere remoto Drive de nombre xoflydrive limitado a una carpeta especifica.
grep -Eq '^\[xoflydrive\]$' "$config" || { echo "Falta remoto Drive" >&2; exit 3; }
grep -Eq '^type = drive$' "$config" || { echo "Remoto no es Drive" >&2; exit 3; }
grep -Eq '^root_folder_id = [A-Za-z0-9_-]{10,}$' "$config" || { echo "Falta carpeta raiz dedicada" >&2; exit 3; }
export RCLONE_CONFIG="$config"
export PGPASSWORD="$XOFLY_DB_PASSWORD"
export PGSSLMODE=require
archive="$work/public.dump"
when="$(date -u +%Y-%m-%dT%H-%M-%SZ)"
encrypted="$work/xofly-public-$when.dump.age"
# Contrato probado por lectura: Supabase Postgres 17, Session Pooler IPv4.
docker run --rm --network host -e PGPASSWORD -e PGSSLMODE postgres:17 \
  pg_dump --host=aws-1-us-west-2.pooler.supabase.com --port=5432 \
  --username=postgres.puibzkjpdpznlojrkftd --dbname=postgres \
  --format=custom --no-owner --no-acl --schema=public --file=/dev/stdout > "$archive"
unset PGPASSWORD XOFLY_DB_PASSWORD
[[ -s "$archive" ]] || { echo "Exportacion vacia" >&2; exit 4; }
docker run --rm -i postgres:17 pg_restore --list < "$archive" > "$work/manifest.txt"
grep -Fq 'xofly_appointments' "$work/manifest.txt" || { echo "Falta tabla de citas en el archivo" >&2; exit 4; }
age -r "$XOFLY_AGE_RECIPIENT" -o "$encrypted" "$archive"
[[ -s "$encrypted" ]] || { echo "No fue posible cifrar" >&2; exit 4; }
rm -f "$archive" "$work/manifest.txt"
# remote root_folder_id está establecido en el archivo protegido.
rclone copyto "$encrypted" "xoflydrive:daily/${encrypted##*/}" --config "$config" --retries 2 --low-level-retries 2 --stats 0
# Verificacion de existencia/tamano sin descargar datos personales.
local_bytes="$(wc -c < "$encrypted" | tr -d ' ')"
remote_bytes="$(rclone size "xoflydrive:daily/${encrypted##*/}" --config "$config" --json | python3 -c 'import sys,json; print(json.load(sys.stdin)["bytes"])')"
[[ "$local_bytes" == "$remote_bytes" ]] || { echo "No coincide el tamaño remoto" >&2; exit 5; }
echo "Archivo cifrado transferido y tamaño confirmado. RESTAURACION REAL TODAVIA PENDIENTE."
