# Sistema bancario — microservicios

Carpeta raíz de la solución. Cada microservicio y la configuración tienen su propio repositorio git:

| Carpeta | Descripción | Puerto |
|---|---|---|
| `api-gateway` | Punto de entrada único (Spring Cloud Gateway); valida el JWT y enruta por Eureka | 8080 |
| `discovery-server` | Registro de APIs (Eureka); panel en http://localhost:8761/ | 8761 |
| `config-server` | Spring Cloud Config Server | 8888 |
| `config-repo` | Configuración externalizada (repositorio git) | — |
| `customer-service` | Clientes | 8081 |
| `account-service` | Cuentas bancarias | 8082 |
| `credit-service` | Créditos y tarjetas de crédito | 8083 |
| `transaction-service` | Depósitos, retiros, transferencias, pagos, consumos, saldos, movimientos y reportes | 8084 |
| `auth-service` | Registro de usuarios e inicio de sesión con JWT | 8085 |

## Levantar la solución con Docker

```bash
docker compose up --build
```

Cada microservicio tiene su propia instancia de MongoDB con su propio volumen:

| Microservicio | Contenedor | Base de datos | Puerto en el host |
|---|---|---|---|
| customer-service | `customer-db` | `customer_db` | 27017 |
| account-service | `account-db` | `account_db` | 27018 |
| credit-service | `credit-db` | `credit_db` | 27019 |
| transaction-service | `transaction-db` | `transaction_db` | 27020 |
| auth-service | `auth-db` | `auth_db` | 27021 |

Fuera de Docker, cada servicio usa por defecto su instancia en `localhost` con ese puerto
(se cambia con `MONGODB_URI`).

Además levanta Kafka (modo KRaft, puerto 9092; los contenedores usan `kafka:29092`) y Redis
(puerto 6379).

Los puertos publicados en el host se pueden cambiar con `CUSTOMER_DB_PORT`, `ACCOUNT_DB_PORT`,
`CREDIT_DB_PORT`, `TRANSACTION_DB_PORT`, `AUTH_DB_PORT`, `KAFKA_PORT`, `REDIS_PORT`,
`API_GATEWAY_PORT`, `DISCOVERY_SERVER_PORT`, `CONFIG_SERVER_PORT`, `CUSTOMER_SERVICE_PORT`,
`ACCOUNT_SERVICE_PORT`, `CREDIT_SERVICE_PORT`, `TRANSACTION_SERVICE_PORT` y `AUTH_SERVICE_PORT`.

El gateway y las llamadas entre servicios encuentran los servicios en Eureka (discovery-server):
un servicio que arranca o se reinicia vuelve a estar disponible en unos 5 segundos. Para ejecutar
los servicios fuera de Docker también hay que levantar discovery-server.

Las llamadas entre servicios y las rutas del gateway usan circuit breaker (Resilience4j) con un
timeout de 2 segundos; si un servicio no responde a tiempo, falla o tiene su circuito abierto, se
responde 503.

En Docker, config-server lee los archivos de `config-repo` montados en solo lectura (perfil
`native`). Al ejecutarlo localmente, los lee desde el repositorio git (rama `main`).

## Autenticación con JWT

1. Crear el cliente: `POST /api/v1/customers` (público).
2. Registrar su usuario: `POST /api/v1/auth/register` con `customerId`, `username` y `password`
   (público). auth-service conoce al cliente por el evento `CustomerCreated` de Kafka; si se acaba
   de crear, puede tardar unos segundos.
3. Iniciar sesión: `POST /api/v1/auth/login` (público). Devuelve un JWT RS256 de 1 hora cuyo claim
   `sub` es el id del cliente.
4. Las demás peticiones envían `Authorization: Bearer <token>`. El API Gateway valida firma,
   vencimiento y emisor con la clave pública de config-repo; sin token o con uno inválido responde
   401. El gateway descarta cualquier `X-Customer-Id` que mande el cliente y envía a los servicios
   el del token.

El token se valida solo en el gateway: llamar directo a los puertos de los servicios se salta la
validación. Las claves RSA de config-repo son solo de desarrollo; en otro entorno se reemplazan con
`JWT_PRIVATE_KEY` (auth-service) y `JWT_PUBLIC_KEY` (gateway).

## Eventos y caché

Las funcionalidades nuevas usan eventos en Kafka: los microservicios nuevos no invocan por REST las
APIs de otros microservicios. Los datos maestros se leen con caché en Redis.

- customer-service publica `CustomerCreated` en el tópico `customer-events` después de guardar cada
  cliente. Si Kafka no responde en 1 s, el error se registra y el cliente igual se crea (el evento
  se pierde; evitarlo requiere el patrón outbox).
- auth-service consume ese tópico y guarda su copia de clientes en MongoDB; la lee con caché en
  Redis (cache-aside, 10 minutos, configurable con `CACHE_CUSTOMERS_TTL`).
- El contrato de los eventos está en `docs/events/asyncapi.yaml`.

## Documentación

- `docs/diagrams/`: diagramas UML en draw.io (diseño de la solución y diagramas de secuencia).
- `docs/events/asyncapi.yaml`: contrato de los eventos de Kafka (AsyncAPI).
- `postman/`: colección y entorno de Postman para verificar las funcionalidades.
