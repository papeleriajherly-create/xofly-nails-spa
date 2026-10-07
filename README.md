# Xofly Nails & Spa — precios administrables V2

1. En Supabase → SQL Editor → New query, ejecuta el archivo `IMPORTAR_PRECIOS.sql` para importar 24 precios y paquetes sin sobrescribir los existentes.
2. En GitHub, reemplaza `index.html` y `admin.html` con los de este ZIP. Conserva `config.js` (incluido). No subas el SQL ni el ZIP a la web; el SQL se ejecuta en Supabase.
3. Espera el despliegue automático de Vercel.
4. Abre `/admin.html`, edita un registro de categoría `Catálogo · ...` y comprueba el cambio en la sección Lista de precios.
5. Los servicios originales permanecen visibles como respaldo hasta que Supabase devuelva registros del catálogo. Los registros de prueba de categoría `General` no se incluyen en la lista de precios administrable.

**Atención:** la página conserva el diseño original y las demás secciones; los precios que aparezcan en otras imágenes o textos estáticos no se actualizan automáticamente. Revisa que los precios originales sean correctos.
