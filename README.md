# Sistema bancario — microservicios

Carpeta raíz de la solución. Cada microservicio y la configuración tienen su propio repositorio git:

| Carpeta | Descripción | Puerto |
|---|---|---|
| `config-server` | Spring Cloud Config Server | 8888 |
| `config-repo` | Configuración externalizada (repositorio git) | — |
| `customer-service` | Clientes | 8081 |
| `account-service` | Cuentas bancarias | 8082 |
| `credit-service` | Créditos y tarjetas de crédito | 8083 |
| `transaction-service` | Depósitos, retiros, pagos, consumos, saldos y movimientos | 8084 |

## Levantar la solución con Docker

```bash
docker compose up --build
```

Los puertos publicados en el host se pueden cambiar con `MONGO_PORT`, `CONFIG_SERVER_PORT`,
`CUSTOMER_SERVICE_PORT`, `ACCOUNT_SERVICE_PORT`, `CREDIT_SERVICE_PORT` y `TRANSACTION_SERVICE_PORT`.

En Docker, config-server lee los archivos de `config-repo` montados en solo lectura (perfil
`native`). Al ejecutarlo localmente, los lee desde el repositorio git (rama `main`).
