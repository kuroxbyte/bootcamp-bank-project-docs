# Diagramas UML

Archivos de [draw.io](https://www.drawio.com/) (se abren en draw.io o diagrams.net).

| Archivo | Contenido |
|---|---|
| `solution-design.drawio` | Diagrama de componentes y despliegue de la solución: api-gateway, microservicios, discovery-server (Eureka), config-server, config-repo, una instancia de MongoDB por microservicio, llamadas REST entre servicios y circuit breakers. |
| `sequence-diagrams.drawio` | Diagramas de secuencia, una página por microservicio: customer-service (crear y consultar cliente), account-service (abrir cuenta de ahorro; ahorro VIP y corriente PYME con requisito de tarjeta de crédito), credit-service (otorgar crédito y tarjeta), transaction-service (retiro con su comisión por transacción, transferencia entre cuentas propias y a terceros, consumo con tarjeta, saldo promedio diario y reportes), con sus caminos de error (404, 422 y 503). Todas las peticiones pasan por el api-gateway y las llamadas entre servicios por un circuit breaker con timeout de 2 s. |

Mantenerlos actualizados cuando cambie el diseño o un flujo.
