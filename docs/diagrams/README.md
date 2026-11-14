# Diagramas UML

Cada tipo de diagrama tiene su carpeta con el archivo fuente de [draw.io](https://www.drawio.com/) (se abre en draw.io o diagrams.net) y una imagen SVG por página:

```text
docs/diagrams/
├── solution-design/     solution-design.drawio + SVG
├── sequence-diagrams/   sequence-diagrams.drawio + un SVG por flujo
└── class-diagrams/      class-diagrams.drawio + un SVG por microservicio
```

| Fuente | Contenido |
|---|---|
| [`solution-design/solution-design.drawio`](solution-design/solution-design.drawio) | Diagrama de componentes y despliegue de la solución: api-gateway (validación del JWT y autorización por rol), microservicios, auth-service, debt-service, yanki-service, discovery-server (Eureka), config-server, config-repo, una instancia de MongoDB por microservicio, Kafka (tópicos de clientes, créditos, transacciones, tarjetas de débito, deudas y Yanki), Redis (caché de clientes, monederos, estado de deuda, tarjetas de débito y celular → monedero), llamadas REST entre servicios (incluidas las consultas de saldo, deuda y productos para las bajas del CRUD) y circuit breakers. |
| [`class-diagrams/class-diagrams.drawio`](class-diagrams/class-diagrams.drawio) | Diagramas de clases UML, una página por microservicio con su modelo de dominio (paquete `domain/model`): records, clases, interfaces y enumeraciones con sus atributos y métodos públicos, herencia (cuentas de account-service), implementación (reglas de movimientos de transaction-service) y asociaciones. Se regenera desde el código cuando cambia el dominio. |
| [`sequence-diagrams/sequence-diagrams.drawio`](sequence-diagrams/sequence-diagrams.drawio) | Diagramas de secuencia, una página por microservicio: customer-service (crear y consultar cliente), auth-service (evento CustomerCreated, registro e inicio de sesión), api-gateway (validación del JWT, roles CUSTOMER y WALLET, X-Customer-Id y X-Wallet-Id), account-service (abrir cuenta de ahorro; ahorro VIP y corriente PYME con requisito de tarjeta de crédito), debt-service (deuda vencida por eventos y bloqueo de nuevos productos), credit-service (otorgar crédito y tarjeta), account-service y transaction-service (tarjeta de débito: emisión y pago desde la cuenta principal), yanki-service (monedero y acceso, pago con saga por eventos y asociación de tarjeta con traspaso del saldo), transaction-service (retiro con su comisión por transacción, transferencia entre cuentas propias y a terceros, pago de créditos y tarjetas de terceros, consumo con tarjeta, saldo promedio diario, cobro mensual de comisiones de mantenimiento y de promedio diario mínimo VIP, y reportes) y las bajas lógicas del CRUD (rol ADMIN: baja de cuenta con consulta del saldo y baja de cliente con consulta de sus productos y evento CustomerClosed), con sus caminos de error (401, 404, 422 y 503). Todas las peticiones pasan por el api-gateway y las llamadas entre servicios por un circuit breaker con timeout de 2 s. |

## Imágenes

Los SVG se regeneran desde los `.drawio` con `scripts/export-diagrams.sh` (requiere draw.io
Desktop).

### Diseño de la solución

- [01-diseno-de-la-solucion](solution-design/01-diseno-de-la-solucion.svg)

### Diagramas de secuencia

- [01-customer-service](sequence-diagrams/01-customer-service.svg)
- [02-auth-service-registro-e-inicio-de-sesion](sequence-diagrams/02-auth-service-registro-e-inicio-de-sesion.svg)
- [03-api-gateway-peticion-autenticada](sequence-diagrams/03-api-gateway-peticion-autenticada.svg)
- [04-account-service](sequence-diagrams/04-account-service.svg)
- [05-account-service-vip-y-pyme](sequence-diagrams/05-account-service-vip-y-pyme.svg)
- [06-tarjeta-de-debito](sequence-diagrams/06-tarjeta-de-debito.svg)
- [07-yanki-monedero-y-acceso](sequence-diagrams/07-yanki-monedero-y-acceso.svg)
- [08-yanki-pago-saga](sequence-diagrams/08-yanki-pago-saga.svg)
- [09-yanki-asociar-tarjeta](sequence-diagrams/09-yanki-asociar-tarjeta.svg)
- [10-debt-service-deuda-vencida](sequence-diagrams/10-debt-service-deuda-vencida.svg)
- [11-credit-service](sequence-diagrams/11-credit-service.svg)
- [12-transaction-service-retiro](sequence-diagrams/12-transaction-service-retiro.svg)
- [13-transaction-service-transferencia](sequence-diagrams/13-transaction-service-transferencia.svg)
- [14-transaction-service-pago-de-terceros](sequence-diagrams/14-transaction-service-pago-de-terceros.svg)
- [15-transaction-service-consumo](sequence-diagrams/15-transaction-service-consumo.svg)
- [16-transaction-service-promedio-diario](sequence-diagrams/16-transaction-service-promedio-diario.svg)
- [17-transaction-service-comisiones-mensuales](sequence-diagrams/17-transaction-service-comisiones-mensuales.svg)
- [18-transaction-service-reportes](sequence-diagrams/18-transaction-service-reportes.svg)
- [19-bajas-logicas-crud](sequence-diagrams/19-bajas-logicas-crud.svg)

### Diagramas de clases

- [01-customer-service](class-diagrams/01-customer-service.svg)
- [02-account-service](class-diagrams/02-account-service.svg)
- [03-credit-service](class-diagrams/03-credit-service.svg)
- [04-transaction-service](class-diagrams/04-transaction-service.svg)
- [05-auth-service](class-diagrams/05-auth-service.svg)
- [06-debt-service](class-diagrams/06-debt-service.svg)
- [07-yanki-service](class-diagrams/07-yanki-service.svg)

Mantenerlos actualizados cuando cambie el diseño o un flujo.
