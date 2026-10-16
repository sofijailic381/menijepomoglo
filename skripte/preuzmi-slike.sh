#!/usr/bin/env bash
# Preuzima sve slike sa menijepomoglo.rs u assets/img/ i prebacuje HTML na lokalne putanje.
# Pokretanje iz glavnog foldera sajta:   bash skripte/preuzmi-slike.sh
# Bezbedno je pokrenuti vise puta. Ako i jedna slika ne uspe, HTML se ne menja.
set -uo pipefail
cd "$(dirname "$0")/.."

BASE="https://www.menijepomoglo.rs/wp-content/uploads/"
PAGES="index.html klinicki.html zajednica.html bold.html"
DEST="assets/img"

# Spisak slika se cita direktno iz HTML-a, pa skripta prati svaku izmenu stranica.
paths=$(grep -ohE '20[0-9]{2}/[0-9]{2}/[A-Za-z0-9._-]+\.(webp|jpe?g|png|gif|svg|avif)' $PAGES | sort -u)

total=0
fail=0
for p in $paths; do
  total=$((total + 1))
  if curl -fsSL --retry 3 --create-dirs -A "Mozilla/5.0" -e "https://www.menijepomoglo.rs/" -o "$DEST/$p" "$BASE$p"; then
    echo "  OK      $p"
  else
    fail=$((fail + 1))
    echo "  GRESKA  $p"
  fi
done

if [ "$fail" -gt 0 ]; then
  echo "Neuspesno: $fail od $total slika. HTML nije menjan - sajt i dalje koristi slike sa menijepomoglo.rs."
  exit 1
fi

for f in $PAGES; do
  sed -i.bak 's#https://www\.menijepomoglo\.rs/wp-content/uploads/#assets/img/#g' "$f" && rm -f "$f.bak"
done
echo "Gotovo: $total slika u $DEST/, HTML prebacen na lokalne putanje."
