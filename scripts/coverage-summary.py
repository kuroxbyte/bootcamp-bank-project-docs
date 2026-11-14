"""Escribe en la salida estándar el resumen de cobertura a partir de los jacoco.csv de cada servicio."""
import csv
import datetime
import os
import sys

base = sys.argv[1]
COUNTERS = [('INSTRUCTION', 'Instrucciones'), ('BRANCH', 'Ramas'), ('LINE', 'Líneas'),
            ('METHOD', 'Métodos')]


def pct(covered, missed):
    total = covered + missed
    return '—' if total == 0 else '%.1f %%' % (100.0 * covered / total)


rows = []
for service in sorted(os.listdir(base)):
    path = os.path.join(base, service, 'jacoco.csv')
    if not os.path.isfile(path):
        continue
    totals = {name: [0, 0] for name, _ in COUNTERS}
    with open(path) as f:
        for row in csv.DictReader(f):
            for name, _ in COUNTERS:
                totals[name][0] += int(row[name + '_COVERED'])
                totals[name][1] += int(row[name + '_MISSED'])
    rows.append((service, totals))

print('# Reportes de cobertura (JaCoCo)\n')
print('Generados con `scripts/coverage-report.sh` (`./mvnw verify` en cada microservicio) el %s.'
      % datetime.date.today().isoformat())
print('Cada carpeta tiene el reporte HTML completo: abrir `<servicio>/index.html` en el navegador.')
print('No se miden el código generado por OpenAPI, las clases de configuración ni las clases')
print('`*Application`; cada `pom.xml` exige al menos 80 % con la regla `check` de JaCoCo.')
print('config-server y discovery-server solo tienen su clase `*Application`, por eso no muestran')
print('porcentajes (sus pruebas verifican que el contexto arranca).\n')
print('| Microservicio | ' + ' | '.join(label for _, label in COUNTERS) + ' | Reporte |')
print('|---|' + '---:|' * len(COUNTERS) + '---|')
for service, totals in rows:
    cells = [pct(*totals[name]) for name, _ in COUNTERS]
    print('| %s | %s | [index.html](%s/index.html) |' % (service, ' | '.join(cells), service))
