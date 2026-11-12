# Verificación con Postman

El sistema no tiene interfaz gráfica; las funcionalidades se verifican con esta colección.

| Archivo | Contenido |
|---|---|
| `bank-microservices.postman_collection.json` | 155 peticiones en 15 carpetas (clientes, autenticación, cuentas, créditos y tarjetas, transacciones de cuentas, pagos de créditos, tarjetas, productos VIP y PYME, comisión por transacción, transferencias, reportes, pagos de terceros, deuda vencida, tarjeta de débito y seguridad), con pruebas automáticas de código de respuesta, reglas de negocio y formato de errores. |
| `bank-gateway.postman_environment.json` | Todas las peticiones por el API Gateway en `localhost:8080`. |

Todas las peticiones pasan por el API Gateway, que valida el token JWT. Después de crear los
clientes, la carpeta de autenticación registra un usuario por cliente (personal, empresarial, VIP y
PYME), inicia sesión y guarda cada token. Las demás peticiones envían
`Authorization: Bearer <token>` del cliente que opera; ya no envían `X-Customer-Id`: el gateway lo
toma del claim `sub` del token. Llamar directo a los puertos de los servicios (8081 a 8085) se salta
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
  --env-var transactionUrl=http://api-gateway:8080
```

auth-service conoce a cada cliente por el evento `CustomerCreated` de Kafka; el primer registro
espera unos segundos para darle tiempo a llegar.

La cuenta a plazo fijo se abre con el día actual en UTC (la zona horaria de los contenedores), para
poder registrar su único movimiento del mes.
