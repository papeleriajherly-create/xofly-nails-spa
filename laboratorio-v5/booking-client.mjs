// Prototipo independiente. NO importar en index.html ni desplegar sin validar API.
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
export function validarSolicitud(raw){
  if(!raw||typeof raw!=='object')throw new TypeError('Solicitud inválida');
  const p={};
  for(const k of ['fecha','hora','nombre','telefono','servicio','notas']){
    if(k==='notas'&&raw[k]==null){p[k]='';continue;}
    if(typeof raw[k]!=='string')throw new TypeError('Campo inválido: '+k);
    p[k]=raw[k].trim();
  }
  if(!/^\d{4}-\d{2}-\d{2}$/.test(p.fecha)||!/^\d{2}:\d{2}$/.test(p.hora))throw new TypeError('Fecha/hora inválida');
  const dt=new Date(p.fecha+'T00:00:00Z');
  if(!Number.isFinite(+dt)||dt.toISOString().slice(0,10)!==p.fecha)throw new TypeError('Fecha imposible');
  const day=dt.getUTCDay();
  const slots=day>=1&&day<=5?['13:00','14:00','15:00','16:00','17:00']:day===6?['10:00','11:00','12:00','13:00','14:00']:[];
  if(!slots.includes(p.hora))throw new TypeError('Horario fuera de jornada');
  if(p.nombre.length<2||p.nombre.length>100||p.servicio.length<2||p.servicio.length>150||p.notas.length>500)throw new TypeError('Datos inválidos');
  if(!/^[+0-9() -]{10,20}$/.test(p.telefono))throw new TypeError('Teléfono inválido');
  const digits=p.telefono.replace(/\D/g,'');
  if(!(digits.length===10||(digits.length===12&&digits.startsWith('52'))||(digits.length===13&&digits.startsWith('521'))))throw new TypeError('Teléfono inválido');
  return p;
}
export function crearSolicitud(raw,requestId,turnstileToken){
  if(!UUID.test(requestId)||typeof turnstileToken!=='string'||turnstileToken.length<10)throw new TypeError('ID o captcha inválido');
  return {...validarSolicitud(raw),requestId,turnstileToken};
}
async function post(fetchImpl,endpoint,data){
  const res=await fetchImpl(endpoint,{method:'POST',credentials:'same-origin',cache:'no-store',headers:{'Content-Type':'application/json','Accept':'application/json'},body:JSON.stringify(data)});
  let json;try{json=await res.json()}catch{throw new Error('Respuesta no JSON')}
  if(!res.ok||json?.ok!==true)throw new Error('Solicitud rechazada');
  return json;
}
// Frente a una pérdida de conexión, recuperar sin reutilizar Turnstile ni generar otro ID.
// IMPORTANTE: op='recover' y nombre de token son provisionales hasta validar contrato Vercel.
export async function enviarORecuperar({solicitud,requestId,turnstileToken,fetchImpl=fetch,endpoint='/api/xofly-reservar'}){
  if(typeof fetchImpl!=='function'||!endpoint.startsWith('/api/'))throw new TypeError('Endpoint inválido');
  const create=crearSolicitud(solicitud,requestId,turnstileToken);
  try{return {estado:'creada',data:await post(fetchImpl,endpoint,create)}}
  catch(err){
    if(!(err instanceof TypeError))throw err;
    try{return {estado:'recuperada',data:await post(fetchImpl,endpoint,{...validarSolicitud(solicitud),requestId,op:'recover'})}}
    catch{return {estado:'incierta',data:null}}
  }
}
