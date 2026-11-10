# Verificación con Postman

El sistema no tiene interfaz gráfica; las funcionalidades se verifican con esta colección.

| Archivo | Contenido |
|---|---|
| `bank-microservices.postman_collection.json` | 53 peticiones en 6 carpetas (clientes, cuentas, créditos y tarjetas, transacciones de cuentas, pagos de créditos, tarjetas), con pruebas automáticas de código de respuesta, reglas de negocio y formato de errores. |
| `bank-local.postman_environment.json` | URLs de los servicios en `localhost:8081` a `8084` (docker-compose o ejecución local). |
| `bank-gateway.postman_environment.json` | Todas las peticiones por el API Gateway en `localhost:8080`. |

Las carpetas se ejecutan en orden: cada paso guarda en variables de la colección los ids que usan
los siguientes (cliente → cuenta → depósito, etc.). Cada ejecución crea datos nuevos.

## Ejecutar

En Postman: importar ambos archivos, elegir el entorno y usar **Run collection**.

Desde la terminal, con la solución levantada con `docker compose up`:

```bash
docker run --rm --network bank_default -v "$PWD/postman:/etc/newman" postman/newman:6-alpine \
  run bank-microservices.postman_collection.json -e bank-local.postman_environment.json \
  --env-var customerUrl=http://customer-service:8081 --env-var accountUrl=http://account-service:8082 \
  --env-var creditUrl=http://credit-service:8083 --env-var transactionUrl=http://transaction-service:8084
```

La cuenta a plazo fijo se abre con el día actual en UTC (la zona horaria de los contenedores), para
poder registrar su único movimiento del mes.
