#!/usr/bin/env python3
#
# Reformat USB CSV export as a simpler CSV, with cleaner values.
#
# Usage: ubs-reformat-csv.py FILE.csv
# Will generate FILE--out.csv

import sys
import os
import csv

# Files

in_path = sys.argv[1]
parts = os.path.splitext(in_path)
out_path = f'{parts[0]}--out.csv'

# Formatters

def fmt_date(s):
    d, m, y = s.split('.')
    return f'{y}-{m}-{d}'

def fmt_amount(s):
    return s.replace("'", '')

def fmt_ident(s):
    return s

# Columns of interest: order and formatters
COLUMNS = {
    #"Date d'évaluation",
    #'Relation bancaire',
    #'Portefeuille',
    #'Produit',
    #'IBAN',
    #'Monn.',
    #'Date du',
    #'Date au',
    #'Description',
    #'Date de transaction',
    #'Date de comptabilisation',
    'Date de valeur': fmt_date,
    #'Description 1',
    #'Description 2',
    #'Description 3',
    #'N° de transaction',
    #'Cours des devises du montant initial en montant du décompte',
    #'Sous-montant',
    #'Débit',
    #'Crédit',
    'Solde': fmt_amount,
    'Description 2': fmt_ident,
    'Description 3': fmt_ident,
    'Débit': fmt_amount,
    'Crédit': fmt_amount,
}

# Read input file
header = None
rows = []
with open(in_path, encoding="utf-8") as csvfile:
    csvfile.read(1)  # eat BOM
    reader = csv.reader(csvfile, delimiter=';', quotechar='"')
    for row in reader:
        if header is None:
            header = row
            continue
        row_as_dict = {k:v for k,v in dict(zip(header, row)).items()
                       if k in COLUMNS}
        # drop rows with too few values:
        if len([v for v in row_as_dict.values() if v]) <= 1:
            continue
        if set(row_as_dict.values()) == {''}: continue
        # keep and reformat rows of interest (as dict):
        new_row = {k:f(row_as_dict[k]) for k,f in COLUMNS.items()}
        rows.append(new_row)

# Process rows
new_header = COLUMNS.keys()
out_rows = []
for d in rows:
    row = [d[k] for k in new_header]
    out_rows.append(row)
out_rows.sort()  # assumes first cell is value date

# Write output file
with open(out_path, 'w', encoding="utf-8") as csvfile:
    writer = csv.writer(csvfile, quoting=csv.QUOTE_MINIMAL)
    writer.writerow(new_header)
    for row in out_rows:
        writer.writerow(row)
print('Wrote:', out_path)
