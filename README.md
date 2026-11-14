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
| `debt-service` | Deuda vencida de cada cliente (solo eventos, sin API; registrado en Eureka) | 8086 |
| `yanki-service` | Monedero móvil Yanki: pagos con el número de celular (solo eventos con los demás servicios) | 8087 |

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
| debt-service | `debt-db` | `debt_db` | 27022 |
| yanki-service | `yanki-db` | `yanki_db` | 27023 |

Fuera de Docker, cada servicio usa por defecto su instancia en `localhost` con ese puerto
(se cambia con `MONGODB_URI`).

Además levanta Kafka (modo KRaft, puerto 9092; los contenedores usan `kafka:29092`) y Redis
(puerto 6379).

Los puertos publicados en el host se pueden cambiar con `CUSTOMER_DB_PORT`, `ACCOUNT_DB_PORT`,
`CREDIT_DB_PORT`, `TRANSACTION_DB_PORT`, `AUTH_DB_PORT`, `DEBT_DB_PORT`, `YANKI_DB_PORT`, `KAFKA_PORT`,
`REDIS_PORT`,
`API_GATEWAY_PORT`, `DISCOVERY_SERVER_PORT`, `CONFIG_SERVER_PORT`, `CUSTOMER_SERVICE_PORT`,
`ACCOUNT_SERVICE_PORT`, `CREDIT_SERVICE_PORT`, `TRANSACTION_SERVICE_PORT`, `AUTH_SERVICE_PORT`,
`DEBT_SERVICE_PORT` y `YANKI_SERVICE_PORT`.

Para las pruebas de punta a punta con Postman se agrega `docker-compose.e2e.yml`, que adelanta dos
días la fecha con que debt-service evalúa las deudas (ver `postman/README.md`):

```bash
docker compose -f docker-compose.yml -f docker-compose.e2e.yml up --build
```

El gateway y las llamadas entre servicios encuentran los servicios en Eureka (discovery-server):
un servicio que arranca o se reinicia vuelve a estar disponible en unos 5 segundos. Para ejecutar
los servicios fuera de Docker también hay que levantar discovery-server.

Las llamadas entre servicios y las rutas del gateway usan circuit breaker (Resilience4j) con un
timeout de 2 segundos; si un servicio no responde a tiempo, falla o tiene su circuito abierto, se
responde 503.

En Docker, config-server lee los archivos de `config-repo` montados en solo lectura (perfil
`native`). Al ejecutarlo localmente, los lee desde el repositorio git (rama `main`).

## Pruebas y cobertura

Cada microservicio ejecuta sus pruebas unitarias, Checkstyle y JaCoCo con `./mvnw verify`. El reporte
de cobertura de todos está en [`docs/coverage`](docs/coverage/README.md); se regenera con:

```bash
scripts/coverage-report.sh
```

## Autenticación con JWT

1. Crear el cliente: `POST /api/v1/customers` (público).
2. Registrar su usuario: `POST /api/v1/auth/register` con `customerId`, `username` y `password`
   (público). auth-service conoce al cliente por el evento `CustomerCreated` de Kafka; si se acaba
   de crear, puede tardar unos segundos.
3. Iniciar sesión: `POST /api/v1/auth/login` (público). Devuelve un JWT RS256 de 1 hora cuyo claim
   `sub` es el id del cliente y cuyo claim `roles` es `["CUSTOMER"]`.
4. Las demás peticiones envían `Authorization: Bearer <token>`. El API Gateway valida firma,
   vencimiento y emisor con la clave pública de config-repo; sin token o con uno inválido responde
   401, y con un rol que no permite la ruta, 403. El gateway descarta cualquier `X-Customer-Id` o
   `X-Wallet-Id` que mande el cliente y envía a los servicios el del token.

Los empleados del banco obtienen un token con rol `ADMIN` en `POST /api/v1/auth/admin-login`. El
usuario y el cifrado BCrypt de su contraseña están en config-repo (`auth.admin`); en desarrollo son
`admin` / `Admin2026!` y en otro entorno se reemplazan con `ADMIN_USERNAME` y `ADMIN_PASSWORD_HASH`.
El gateway envía a los servicios `X-Admin-Id` con el usuario del empleado (y descarta el que mande el
cliente).

Los dueños de un monedero Yanki obtienen su token con `POST /api/v1/auth/wallet-users` (celular y
contraseña) y `POST /api/v1/auth/wallet-login`: `sub` es el id del monedero y `roles` es
`["WALLET"]`. Ese token solo sirve para `/api/v1/yanki/**`; el de cliente, para las demás rutas.

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

## Pagos de terceros

Un cliente puede pagar créditos y tarjetas de otros clientes del banco con
`POST /api/v1/credits/{creditId}/payments/third-party` y
`POST /api/v1/credit-cards/{creditCardId}/payments/third-party` (si el producto es propio, 422; los
pagos propios siguen en `/payments`). El pago no se descuenta de ninguna cuenta, guarda quién pagó
(`payerCustomerId`) y reduce la deuda del dueño del producto: el evento del pago lleva al dueño como
cliente, así un tercero también puede saldar una deuda vencida.

## Tarjetas de débito

account-service emite tarjetas de débito asociadas a cuentas del cliente (`/api/v1/debit-cards`): una
cuenta principal, de la que salen los pagos, y otras cuentas asociadas. Cada cuenta puede estar en
una sola tarjeta y un cliente puede tener varias; no se emite a clientes con deuda vencida. Se puede
asociar otra cuenta y cambiar la principal.

account-service publica cada tarjeta en `debit-card-events`; transaction-service guarda su copia
(MongoDB + Redis) y procesa los pagos con `POST /api/v1/debit-cards/{debitCardId}/payments`: el pago
sale de la cuenta principal como movimiento `DEBIT_CARD_PAYMENT`, con las reglas y la comisión de un
retiro. `GET /api/v1/reports/debit-cards/{debitCardId}/last-movements` devuelve los últimos 10 pagos
con la tarjeta.

## Monedero Yanki

yanki-service es un monedero móvil para cualquier persona, cliente o no del banco. Un monedero se
crea con documento (DNI, CEX o pasaporte), celular, IMEI y correo (`POST /api/v1/yanki/wallets`,
público); hay uno por celular. Los pagos se envían con solo el celular del destino
(`POST /api/v1/yanki/payments`).

- Sin tarjeta, el monedero tiene su propio saldo: un pago entre dos monederos sin tarjeta se completa
  al instante (201).
- Un cliente del banco autoriza su tarjeta de débito para un monedero
  (`POST /api/v1/yanki/debit-card-links`, token de cliente) y el dueño del monedero la confirma
  (`POST /api/v1/yanki/debit-card-links/{linkId}/confirm`). El saldo del monedero se transfiere a la
  cuenta principal de la tarjeta y, desde entonces, los pagos se cargan y abonan en esa cuenta. Un
  monedero tiene una sola tarjeta y una tarjeta está en un solo monedero.
- Si interviene una cuenta, el pago queda pendiente (202) y se completa por eventos (saga):
  yanki-service pide el cargo o el abono en `yanki-operations`; transaction-service lo registra
  (`YANKI_PAYMENT_SENT` como un retiro, `YANKI_PAYMENT_RECEIVED` como un depósito) y responde en
  `yanki-operation-results`. Si el destino rechaza el abono, el cargo se devuelve
  (`YANKI_PAYMENT_REVERSAL`, sin reglas ni comisión) y el pago queda `REJECTED` con el motivo.
- yanki-service no llama a la API REST de otros servicios: conoce las tarjetas por
  `debit-card-events` (copia en MongoDB con caché en Redis) y publica `WalletCreated` en
  `yanki-events` para que auth-service registre el acceso del monedero.

## Administración y bajas (CRUD)

Cada entidad de negocio tiene Create, FindAll, Update y Delete. Las bajas son lógicas: el registro
guarda su fecha de baja (o el estado `CLOSED` en un monedero), deja de listarse, responde 404 y ya no
acepta operaciones; su historial de movimientos se conserva.

| Entidad | Listar | Modificar (`PUT`) | Dar de baja (`DELETE`) |
|---|---|---|---|
| Cliente | `GET /api/v1/customers` (ADMIN) | ADMIN: nombre y perfil; el cliente: solo su nombre | ADMIN, sin cuentas, créditos ni tarjetas activos |
| Cuenta | `GET /api/v1/accounts` (cliente) | ADMIN: condiciones de su tipo (mantenimiento —obligatorio, 0 en PYME—, titulares y firmantes; límite de movimientos y promedio VIP; día del plazo fijo) | ADMIN, con saldo 0 y sin tarjeta de débito |
| Tarjeta de débito | `GET /api/v1/debit-cards` (cliente) | El cliente: asociar cuentas y cambiar la principal | ADMIN; sus cuentas quedan libres |
| Crédito | `GET /api/v1/credits` (cliente) | ADMIN: fecha de vencimiento | ADMIN, pagado por completo |
| Tarjeta de crédito | `GET /api/v1/credit-cards` (cliente) | ADMIN: límite (no menor que la deuda) y día de pago | ADMIN, sin deuda |
| Monedero Yanki | `GET /api/v1/yanki/wallet` (dueño) | El dueño: IMEI y correo | El dueño, sin pagos pendientes y con saldo propio 0 |

Para verificar las reglas, customer-service consulta los productos del cliente en account-service y
credit-service, y account-service y credit-service consultan el saldo o la deuda en
transaction-service (REST con circuit breaker; 503 si no responden). Las bajas y modificaciones se
publican en Kafka (`CustomerUpdated`, `CustomerClosed`, `CreditUpdated`, `CreditCardUpdated`,
`CreditClosed`, `CreditCardClosed`, `DebitCardClosed` y `WalletClosed`): auth-service elimina el
acceso de clientes y monederos dados de baja, debt-service recalcula la deuda con las nuevas fechas,
y transaction-service y yanki-service dejan de usar la tarjeta de débito dada de baja (el monedero
que la tenía vuelve a usar su propio saldo).

Una cuenta, crédito o tarjeta dado de baja no cuenta para los límites por cliente (por ejemplo, una
sola cuenta de ahorro personal). El celular de un monedero dado de baja queda libre: el monedero lo
guarda aparte (`closedPhone`) y se puede crear un monedero nuevo con ese celular. Si el
`WalletCreated` del nuevo llega a auth-service antes que el `WalletClosed` del anterior, auth-service
reemplaza igual la copia y el acceso de ese celular.

Al arrancar, account-service y yanki-service ponen los índices de MongoDB al día con sus
anotaciones (`IndexMigration`): si un índice existe con otras opciones (`unique` o `sparse`), lo
recrean. Así, una base de datos existente recibe sin pasos manuales los índices dispersos de
`debit_cards.accountIds` y `wallets.phone`. En estos dos servicios la creación automática de
índices de Spring está desactivada (no puede modificar un índice existente y registraba un error),
así que la migración es la que crea todos sus índices; si se desactiva con
`mongodb.index-migration.on-startup=false`, los índices no se crean.

## Comisiones mensuales

El día 1 de cada mes a las 00:15 (`MONTHLY_FEES_CRON`), transaction-service cobra el mes anterior a
todas las cuentas, que lista con el endpoint interno de account-service:

- `MAINTENANCE_FEE`: la comisión de mantenimiento de cada cuenta corriente (la PYME no tiene).
- `MINIMUM_AVERAGE_FEE`: si una cuenta de ahorro VIP no alcanzó su promedio diario mínimo del mes,
  una comisión de 15.00 (`MINIMUM_AVERAGE_FEE`).

Las comisiones llevan fecha del día 1 y nunca dejan el saldo negativo: si no alcanza, se cobra lo que
haya. El cobro no se repite para la misma cuenta y mes. No cuentan como transacciones del cliente
(límite de movimientos, día del plazo fijo, transacciones sin comisión), pero aparecen en los
movimientos y en el reporte por producto.

## Deuda vencida

Un cliente con deuda vencida en algún producto de crédito no puede adquirir otro producto: abrir una
cuenta, recibir un crédito o una tarjeta responde 422.

- Crédito: al otorgarlo se indican `amount` y `dueDate` (posterior a hoy); desde el día siguiente
  al vencimiento, el saldo pendiente (monto menos pagos) es deuda vencida.
- Tarjeta: tiene un `paymentDueDay` (1 a 28); los consumos de un mes se pagan hasta ese día del
  mes siguiente. Pasado ese día, lo que los pagos no cubren es deuda vencida.
- credit-service publica `CreditGranted` y `CreditCardGranted` (`credit-events`); transaction-service
  publica los pagos y consumos (`transaction-events`).
- debt-service consume esos tópicos, calcula la deuda de cada cliente al llegar cada evento y en una
  revisión diaria (00:05, `DEBT_EVALUATION_CRON`), y publica `CustomerDebtStatusChanged`
  (`debt-events`) solo cuando el cliente pasa a tener deuda vencida o deja de tenerla.
- account-service y credit-service guardan ese estado en su MongoDB con caché en Redis
  (`debt-status:{customerId}`) y lo consultan al abrir productos, sin llamar a otro servicio. Después
  de un pago, el bloqueo se levanta cuando llega el evento (normalmente en menos de un segundo).

## Documentación

- `docs/diagrams/`: diagramas UML en draw.io (diseño de la solución y diagramas de secuencia).
- `docs/events/asyncapi.yaml`: contrato de los eventos de Kafka (AsyncAPI).
- `postman/`: colección y entorno de Postman para verificar las funcionalidades.
