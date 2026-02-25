#!/usr/bin/env python3
"""Create a compressed pg_dump backup of the hospital_db.

Usage:
  python create_backup.py --out backups/backup_hospital.dump

Defaults read from environment or fall back to sensible defaults.
"""
import os
import subprocess
import argparse
from pathlib import Path
from datetime import datetime
import shutil


def find_pg_dump():
    # prefer pg_dump in PATH, otherwise try the default install location on Windows
    pg = shutil.which('pg_dump')
    if pg:
        return pg
    candidate = Path(r"C:\Program Files\PostgreSQL\17\bin\pg_dump.exe")
    if candidate.exists():
        return str(candidate)
    raise FileNotFoundError('pg_dump not found: add PostgreSQL bin to PATH or install pg_dump')


def main():
    p = argparse.ArgumentParser(description='Create pg_dump backup for hospital_db')
    p.add_argument('--out', '-o', help='Output file', default=None)
    p.add_argument('--host', default=os.getenv('PGHOST', 'localhost'))
    p.add_argument('--port', default=os.getenv('PGPORT', '5432'))
    p.add_argument('--db', default=os.getenv('PGDATABASE', 'hospital_db'))
    p.add_argument('--user', default=os.getenv('PGUSER', 'postgres'))
    p.add_argument('--password', default=os.getenv('PGPASSWORD', '1379'))
    args = p.parse_args()

    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    default_out = Path('backups') / f'backup_hospital_{timestamp}.dump'
    out_path = Path(args.out) if args.out else default_out
    out_path.parent.mkdir(parents=True, exist_ok=True)

    try:
        pg_dump = find_pg_dump()
    except FileNotFoundError as e:
        print('ERROR:', e)
        raise

    cmd = [pg_dump, '-U', args.user, '-h', args.host, '-p', str(args.port), '-d', args.db, '-F', 'c', '-f', str(out_path)]

    env = os.environ.copy()
    env['PGPASSWORD'] = args.password

    print('Running:', ' '.join(cmd))
    try:
        subprocess.run(cmd, check=True, env=env)
    except subprocess.CalledProcessError as e:
        print('pg_dump failed:', e)
        raise

    print('Backup created at', out_path)


if __name__ == '__main__':
    main()
