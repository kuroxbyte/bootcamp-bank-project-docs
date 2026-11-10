# Diagramas UML

Archivos de [draw.io](https://www.drawio.com/) (se abren en draw.io o diagrams.net).

| Archivo | Contenido |
|---|---|
| `solution-design.drawio` | Diagrama de componentes y despliegue de la solución: api-gateway, microservicios, discovery-server (Eureka), config-server, config-repo, MongoDB, llamadas REST entre servicios y circuit breakers. |
| `sequence-diagrams.drawio` | Diagramas de secuencia, una página por microservicio: customer-service (crear y consultar cliente), account-service (abrir cuenta de ahorro), credit-service (otorgar crédito y tarjeta), transaction-service (retiro y consumo con tarjeta), con sus caminos de error (404, 422 y 503). Todas las peticiones pasan por el api-gateway y las llamadas entre servicios por un circuit breaker con timeout de 2 s. |

Mantenerlos actualizados cuando cambie el diseño o un flujo.
