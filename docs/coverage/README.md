# Reportes de cobertura (JaCoCo)

Generados con `scripts/coverage-report.sh` (`./mvnw verify` en cada microservicio) el 2026-11-16.
Cada carpeta tiene el reporte HTML completo: abrir `<servicio>/index.html` en el navegador.
No se miden el código generado por OpenAPI, las clases de configuración ni las clases
`*Application`; cada `pom.xml` exige al menos 80 % con la regla `check` de JaCoCo.
config-server y discovery-server solo tienen su clase `*Application`, por eso no muestran
porcentajes (sus pruebas verifican que el contexto arranca).

| Microservicio | Instrucciones | Ramas | Líneas | Métodos | Reporte |
|---|---:|---:|---:|---:|---|
| account-service | 99.0 % | 95.5 % | 98.8 % | 100.0 % | [index.html](account-service/index.html) |
| api-gateway | 100.0 % | 100.0 % | 100.0 % | 100.0 % | [index.html](api-gateway/index.html) |
| auth-service | 100.0 % | 100.0 % | 100.0 % | 100.0 % | [index.html](auth-service/index.html) |
| config-server | — | — | — | — | [index.html](config-server/index.html) |
| credit-service | 99.1 % | 96.2 % | 99.4 % | 98.2 % | [index.html](credit-service/index.html) |
| customer-service | 97.9 % | 100.0 % | 98.2 % | 97.6 % | [index.html](customer-service/index.html) |
| debt-service | 99.3 % | 94.3 % | 99.4 % | 98.0 % | [index.html](debt-service/index.html) |
| discovery-server | — | — | — | — | [index.html](discovery-server/index.html) |
| transaction-service | 99.7 % | 97.7 % | 99.9 % | 99.2 % | [index.html](transaction-service/index.html) |
| yanki-service | 99.6 % | 99.1 % | 99.5 % | 99.5 % | [index.html](yanki-service/index.html) |
