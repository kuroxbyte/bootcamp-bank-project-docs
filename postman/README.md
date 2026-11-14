# Verificación con Postman

El sistema no tiene interfaz gráfica; las funcionalidades se verifican con esta colección.

| Archivo | Contenido |
|---|---|
| `bank-microservices.postman_collection.json` | 268 peticiones en 17 carpetas (clientes, autenticación, cuentas, créditos y tarjetas, transacciones de cuentas, pagos de créditos, tarjetas, productos VIP y PYME, comisión por transacción, transferencias, reportes, pagos de terceros, deuda vencida, tarjeta de débito, monedero Yanki, seguridad y administración y bajas), con pruebas automáticas de código de respuesta, reglas de negocio y formato de errores. |
| `bank-gateway.postman_environment.json` | Todas las peticiones por el API Gateway en `localhost:8080`. |

Todas las peticiones pasan por el API Gateway, que valida el token JWT. Después de crear los
clientes, la carpeta de autenticación registra un usuario por cliente (personal, empresarial, VIP y
PYME), inicia sesión y guarda cada token. Las demás peticiones envían
`Authorization: Bearer <token>` del cliente que opera; ya no envían `X-Customer-Id`: el gateway lo
toma del claim `sub` del token. Llamar directo a los puertos de los servicios (8081 a 8087) se salta
esa validación, por eso no hay entorno para hacerlo.

Las carpetas se ejecutan en orden: cada paso guarda en variables de la colección los ids y tokens
que usan los siguientes (cliente → usuario → token → cuenta → depósito, etc.). Cada ejecución crea
datos nuevos; los nombres de usuario llevan un sufijo distinto en cada ejecución.

## Ejecutar

En Postman: importar ambos archivos, elegir el entorno y usar **Run collection**.

La carpeta de deuda vencida necesita que debt-service evalúe como si fuera pasado mañana: un crédito
que vence mañana queda vencido de inmediato. Por eso la solución se levanta con
`docker-compose.e2e.yml` (con solo `docker-compose.yml`, esa carpeta falla):

```bash
docker compose -f docker-compose.yml -f docker-compose.e2e.yml up --build
```

Desde la terminal, con la solución levantada así:

```bash
docker run --rm --network bank_default -v "$PWD/postman:/etc/newman" postman/newman:6-alpine \
  run bank-microservices.postman_collection.json -e bank-gateway.postman_environment.json \
  --env-var authUrl=http://api-gateway:8080 --env-var customerUrl=http://api-gateway:8080 \
  --env-var accountUrl=http://api-gateway:8080 --env-var creditUrl=http://api-gateway:8080 \
  --env-var transactionUrl=http://api-gateway:8080 --env-var yankiUrl=http://api-gateway:8080
```

auth-service conoce a cada cliente por el evento `CustomerCreated` de Kafka; el primer registro
espera unos segundos para darle tiempo a llegar. Lo mismo con los monederos (`WalletCreated`).

La carpeta del monedero Yanki crea tres monederos con celulares distintos en cada ejecución, inicia
sesión con cada uno (token con rol `WALLET`) y asocia tarjetas de débito. Los pagos en los que
interviene una cuenta se completan por eventos: la petición que consulta el resultado espera unos
segundos antes de enviarse.

La cuenta a plazo fijo se abre con el día actual en UTC (la zona horaria de los contenedores), para
poder registrar su único movimiento del mes.

La carpeta de administración inicia sesión como empleado (`admin` / `Admin2026!`, token con rol
`ADMIN`) y recorre el CRUD con un cliente propio: lista clientes, modifica y da de baja el cliente y
sus cuentas, tarjeta de débito, crédito y tarjeta de crédito, comprobando cada regla (saldo, deuda,
tarjeta asociada, productos activos). También comprueba que la comisión de la corriente PYME sea
obligatoria (0) al modificarla. Termina con un monedero Yanki que su dueño modifica y da de baja, y
con un monedero nuevo que reutiliza su celular. Las peticiones que dependen de un evento de Kafka
(usuario eliminado, tarjeta quitada) esperan unos segundos antes de enviarse.