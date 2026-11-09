# Sistema bancario — microservicios

Carpeta raíz de la solución. Cada microservicio y la configuración tienen su propio repositorio git:

| Carpeta | Descripción | Puerto |
|---|---|---|
| `discovery-server` | Registro de APIs (Eureka); panel en http://localhost:8761/ | 8761 |
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

Los puertos publicados en el host se pueden cambiar con `MONGO_PORT`, `DISCOVERY_SERVER_PORT`, `CONFIG_SERVER_PORT`,
`CUSTOMER_SERVICE_PORT`, `ACCOUNT_SERVICE_PORT`, `CREDIT_SERVICE_PORT` y `TRANSACTION_SERVICE_PORT`.

En Docker, config-server lee los archivos de `config-repo` montados en solo lectura (perfil
`native`). Al ejecutarlo localmente, los lee desde el repositorio git (rama `main`).

## Documentación

- `docs/diagrams/`: diagramas UML en draw.io (diseño de la solución y diagramas de secuencia).
- `postman/`: colección y entorno de Postman para verificar las funcionalidades.
