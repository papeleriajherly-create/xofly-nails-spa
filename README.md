# Xofly Nails & Spa — Panel conectado a Supabase

Incluye la página Premium V4 conservada, panel `admin.html` y `config.js` con la URL y la clave pública de Supabase.

## Publicar
1. Extrae el ZIP.
2. En el repositorio GitHub `xofly-nails-spa`, reemplaza `index.html` y sube `admin.html` y `config.js` a la raíz. No subas el ZIP directamente.
3. Espera el despliegue automático en Vercel.
4. Abre `https://xofly-nails-spa.vercel.app/admin.html` e inicia sesión con el usuario autorizado en Supabase.
5. Agrega un servicio o promoción de prueba y comprueba que aparezca en la sección Novedades de la web pública.

## Alcance
El panel gestiona registros nuevos de servicios/precios y promociones; **el catálogo y las imágenes originales de la página siguen siendo estáticos**. La tabla `xofly_gallery` y `xofly_settings` todavía no tienen editor. La disponibilidad de citas sigue confirmándose por WhatsApp. No subir contraseñas ni claves `sb_secret_` al repositorio.
