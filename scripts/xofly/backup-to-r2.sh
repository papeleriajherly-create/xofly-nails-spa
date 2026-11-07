#!/usr/bin/env bash
# Xofly: exportación cifrada de datos de negocio (esquema public).
# Ejecutar SOLO en GitHub Actions protegido. No imprime datos ni contraseñas.
set -Eeuo pipefail
umask 077
for var in XOFLY_DB_PASSWORD XOFLY_R2_ENDPOINT XOFLY_R2_BUCKET AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY XOFLY_AGE_RECIPIENT; do
  if [[ -z "${!var:-}" ]]; then echo "Configuracion incompleta: ${var}" >&2; exit 2; fi
done
if [[ ! "$XOFLY_R2_ENDPOINT" =~ ^https://[a-zA-Z0-9.-]+\.r2\.cloudflarestorage\.com$ ]]; then
  echo "Destino R2 invalido" >&2; exit 2
fi
if [[ ! "$XOFLY_AGE_RECIPIENT" =~ ^age1[a-z0-9]+$ ]]; then
  echo "Clave publica age invalida" >&2; exit 2
fi
sudo apt-get update -qq >/dev/null
sudo apt-get install -y -qq age awscli >/dev/null
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
dump="$work/xofly-public.dump"
date_utc="$(date -u +%Y-%m-%dT%H-%M-%SZ)"
filename="xofly-public-${date_utc}.dump.age"
object_key="xofly/daily/$filename"
export PGPASSWORD="$XOFLY_DB_PASSWORD"
export PGSSLMODE=require
# El proyecto utiliza Postgres 17. Sesion IPv4 con pooler puerto 5432.
docker run --rm --network host -e PGPASSWORD -e PGSSLMODE postgres:17 \
  pg_dump --host=aws-1-us-west-2.pooler.supabase.com --port=5432 \
  --username=postgres.puibzkjpdpznlojrkftd --dbname=postgres \
  --format=custom --no-owner --no-acl --schema=public --file=/dev/stdout > "$dump"
unset PGPASSWORD
[[ -s "$dump" ]] || { echo "Exportacion vacia" >&2; exit 3; }
docker run --rm -i postgres:17 pg_restore --list < "$dump" > "$work/list.txt"
grep -Fq 'xofly_appointments' "$work/list.txt" || { echo "Falta tabla de citas en exportacion" >&2; exit 3; }
age -r "$XOFLY_AGE_RECIPIENT" -o "$work/$filename" "$dump"
[[ -s "$work/$filename" ]] || { echo "Cifrado fallido" >&2; exit 3; }
# Borrar el volcado sin cifrar antes de iniciar la subida; runner efimero.
rm -f "$dump" "$work/list.txt"
aws --endpoint-url "$XOFLY_R2_ENDPOINT" s3 cp "$work/$filename" "s3://$XOFLY_R2_BUCKET/$object_key" --only-show-errors
expected="$(wc -c < "$work/$filename" | tr -d ' ')"
actual="$(aws --endpoint-url "$XOFLY_R2_ENDPOINT" s3api head-object --bucket "$XOFLY_R2_BUCKET" --key "$object_key" --query ContentLength --output text)"
[[ "$actual" == "$expected" ]] || { echo "Tamano remoto incorrecto" >&2; exit 4; }
echo "Respaldo cifrado subido y tamano remoto comprobado. Falta ensayo independiente de restauracion."
