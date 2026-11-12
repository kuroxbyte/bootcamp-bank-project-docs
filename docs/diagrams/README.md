# Diagramas UML

Archivos de [draw.io](https://www.drawio.com/) (se abren en draw.io o diagrams.net).

| Archivo | Contenido |
|---|---|
| `solution-design.drawio` | Diagrama de componentes y despliegue de la solución: api-gateway (validación del JWT), microservicios, auth-service, debt-service, discovery-server (Eureka), config-server, config-repo, una instancia de MongoDB por microservicio, Kafka (tópicos de clientes, créditos, transacciones y deudas), Redis (caché de clientes y del estado de deuda), llamadas REST entre servicios y circuit breakers. |
| `sequence-diagrams.drawio` | Diagramas de secuencia, una página por microservicio: customer-service (crear y consultar cliente), auth-service (evento CustomerCreated, registro e inicio de sesión), api-gateway (validación del JWT y X-Customer-Id), account-service (abrir cuenta de ahorro; ahorro VIP y corriente PYME con requisito de tarjeta de crédito), debt-service (deuda vencida por eventos y bloqueo de nuevos productos), credit-service (otorgar crédito y tarjeta), transaction-service (retiro con su comisión por transacción, transferencia entre cuentas propias y a terceros, pago de créditos y tarjetas de terceros, consumo con tarjeta, saldo promedio diario y reportes), con sus caminos de error (401, 404, 422 y 503). Todas las peticiones pasan por el api-gateway y las llamadas entre servicios por un circuit breaker con timeout de 2 s. |

Mantenerlos actualizados cuando cambie el diseño o un flujo.
