#!/usr/bin/env bash
# Ejecuta las pruebas de cada microservicio con JaCoCo y copia sus reportes a docs/coverage.
# Uso: scripts/coverage-report.sh   (desde la carpeta raíz de la solución)
set -euo pipefail

cd "$(dirname "$0")/.."
SERVICES=(customer-service account-service credit-service transaction-service auth-service
          debt-service yanki-service api-gateway config-server discovery-server)

for service in "${SERVICES[@]}"; do
    echo "== $service"
    (cd "$service" && ./mvnw -q -B verify)
    rm -rf "docs/coverage/$service"
    mkdir -p "docs/coverage/$service"
    cp -R "$service/target/site/jacoco/." "docs/coverage/$service/"
done

python3 -I scripts/coverage-summary.py docs/coverage > docs/coverage/README.md
echo "Resumen en docs/coverage/README.md"
