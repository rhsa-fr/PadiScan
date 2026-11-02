#!/usr/bin/env python3
"""Unduh Paddy Doctor asli dari Kaggle ke MyDrive/padicheck/data_raw.

Kenapa Kaggle: mirror Hugging Face yang dipakai proyek lama hanya memuat 10 kelas / 10.407
citra. Dataset asli (kompetisi) berisi 13 kelas / 16.225 citra. Skrip ini mengambil versi
Kaggle supaya jumlah kelas sesuai laporan.

Sumber default : https://www.kaggle.com/datasets/imbikramsaha/paddy-doctor
                 (CC0 Public Domain, 1.043 MB, mirror kompetisi resolusi penuh 480x640)
Alternatif     : --competition paddy-disease-classification
                 (butuh "accept rules" di halaman kompetisi, kalau tidak akan 403)

Kredensial (pilih salah satu):
  1. Colab Secrets: simpan KAGGLE_USERNAME dan KAGGLE_KEY, lalu aktifkan "Notebook access"
  2. Environment variable KAGGLE_USERNAME / KAGGLE_KEY
  3. Berkas kaggle.json (default ~/.kaggle/kaggle.json, atau --kaggle-json PATH)

Pemakaian:
    !python download_kaggle_dataset.py                  # Colab, simpan ke Drive
    python download_kaggle_dataset.py --list-files      # lihat isi dataset, tanpa unduh
    python download_kaggle_dataset.py --out "D:\\Visikom\\data\\raw"

Sifat: idempoten (zip yang sudah lengkap dilewati), resume lewat .part, ekstrak otomatis,
lalu menghitung jumlah citra per kelas dari train.csv sebagai bukti isi.
"""

import argparse
import csv
import json
import os
import sys
import time
import zipfile
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

import requests

DEFAULT_OUT = "/content/drive/MyDrive/padicheck/data_raw"
DEFAULT_DATASET = "imbikramsaha/paddy-doctor"
COMPETITION = "paddy-disease-classification"
CHUNK = 1 << 20
UA = {"User-Agent": "visikom-kaggle-fetcher/1.0"}


def human(n: float) -> str:
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024 or unit == "GB":
            return f"{n:.1f} {unit}"
        n /= 1024
    return f"{n:.1f} GB"


def mount_drive_if_needed(out: Path) -> None:
    if not str(out).startswith("/content/drive"):
        return
    if Path("/content/drive/MyDrive").is_dir():
        return
    try:
        from google.colab import drive  # type: ignore

        print("Mount Google Drive ...")
        drive.mount("/content/drive")
    except ImportError as exc:
        raise SystemExit(f"Target {out} di /content/drive tetapi Drive belum ter-mount.") from exc


def load_credentials(args) -> tuple[str, str]:
    user = os.environ.get("KAGGLE_USERNAME")
    key = os.environ.get("KAGGLE_KEY") or os.environ.get("KAGGLE_API_TOKEN")

    if not (user and key):
        try:
            from google.colab import userdata  # type: ignore

            user = user or userdata.get("KAGGLE_USERNAME")
            key = key or userdata.get("KAGGLE_KEY")
        except Exception:
            pass

    if not (user and key):
        candidates = [Path(args.kaggle_json).expanduser()] if args.kaggle_json else [
            Path.home() / ".kaggle" / "kaggle.json",
            Path("/root/.kaggle/kaggle.json"),
            Path("/content/kaggle.json"),
        ]
        for path in candidates:
            if path.is_file():
                data = json.loads(path.read_text(encoding="utf-8"))
                user = user or data.get("username")
                key = key or data.get("key")
                print(f"Kredensial dibaca dari {path}")
                break
        if not (user and key) and args.kaggle_json:
            raise SystemExit(f"Berkas kaggle.json tidak ditemukan di {args.kaggle_json}")

    if not (user and key):
        raise SystemExit(
            "Kredensial Kaggle tidak ditemukan.\n"
            "  Pilih salah satu:\n"
            "  1. Colab Secrets: KAGGLE_USERNAME + KAGGLE_KEY (aktifkan Notebook access)\n"
            "  2. export KAGGLE_USERNAME=... KAGGLE_KEY=...\n"
            "  3. taruh kaggle.json di ~/.kaggle/kaggle.json\n"
            "  Ambil token di https://www.kaggle.com/settings -> API -> Create New Token"
        )
    return user, key


def list_dataset_files(ref: str, max_pages: int = 3) -> int:
    """Tampilkan isi dataset lewat endpoint publik (tanpa kredensial).

    Daftar berkas dipaginasi ~100 per halaman; dataset ini punya >16 ribu berkas, jadi
    pembacaan dibatasi `max_pages` dan hasilnya bersifat contoh struktur, bukan hitungan penuh.
    """
    token = None
    pages = 0
    dirs: Counter = Counter()
    total_bytes = 0
    truncated = False
    while True:
        url = f"https://www.kaggle.com/api/v1/datasets/list/{ref}"
        if token:
            url += f"?pageToken={requests.utils.quote(token)}"
        r = requests.get(url, headers=UA, timeout=60)
        if r.status_code != 200:
            print(f"  ! gagal membaca daftar berkas: HTTP {r.status_code}")
            return 1
        j = r.json()
        for f in j.get("datasetFiles") or []:
            name = f.get("name") or ""
            total_bytes += int(f.get("totalBytes") or 0)
            parts = name.split("/")
            if len(parts) >= 2:
                dirs["/".join(parts[:2])] += 1
        token = j.get("nextPageTokenNullable")
        pages += 1
        if not token:
            break
        if pages >= max_pages:
            truncated = True
            break
    print(
        f"Contoh struktur ({pages} halaman, {sum(dirs.values())} berkas dibaca, "
        f"{human(total_bytes)}):"
    )
    for name, n in sorted(dirs.items())[:30]:
        print(f"  {name}  ({n} berkas)")
    if truncated:
        print("  ... daftar masih berlanjut (>16 ribu berkas). Pakai --max-pages untuk memperbanyak.")
    return 0


def download(session: requests.Session, url: str, dest: Path, auth: tuple[str, str]) -> int:
    dest.parent.mkdir(parents=True, exist_ok=True)
    part = dest.with_name(dest.name + ".part")
    start = part.stat().st_size if part.exists() else 0
    headers = dict(UA)
    if start:
        headers["Range"] = f"bytes={start}-"

    with session.get(url, headers=headers, auth=auth, stream=True, timeout=180, allow_redirects=True) as r:
        if r.status_code in (401, 403):
            raise SystemExit(
                f"Kaggle menolak (HTTP {r.status_code}). Periksa KAGGLE_USERNAME/KAGGLE_KEY.\n"
                "Kalau memakai --competition, buka halaman kompetisinya dan klik "
                "'I Understand and Accept' dulu (aturan kompetisi harus diterima lewat web)."
            )
        r.raise_for_status()
        expected = int(r.headers.get("content-length") or 0)
        resumed = start > 0 and r.status_code == 206
        if not resumed and start:
            print("  server tidak mendukung resume, mulai dari awal")
            start = 0
        if expected and resumed:
            expected += start
        mode = "ab" if resumed else "wb"
        done = start
        last = 0.0
        with open(part, mode) as fh:
            for chunk in r.iter_content(CHUNK):
                if not chunk:
                    continue
                fh.write(chunk)
                done += len(chunk)
                if time.time() - last > 1.0:
                    last = time.time()
                    pct = f" ({done * 100 / expected:.0f}%)" if expected else ""
                    print(f"\r    {human(done)} / {human(expected)}{pct}   ", end="", flush=True)
        if not expected:
            print(f"\r    {human(done)}   ", end="", flush=True)
    print()
    size = part.stat().st_size
    part.replace(dest)
    return size


def extract(zip_path: Path, out_dir: Path, flatten: bool) -> Path:
    out_dir.mkdir(parents=True, exist_ok=True)
    skip_marks = ("__MACOSX/", "/.ipynb_checkpoints/", ".ipynb_checkpoints/")
    with zipfile.ZipFile(zip_path) as zf:
        members = [m for m in zf.infolist() if not any(s in m.filename for s in skip_marks)]
        total = sum(m.file_size for m in members if not m.is_dir())
        print(f"  {len(members)} entri, {human(total)} setelah ekstrak")
        done = 0
        last = 0.0
        for m in members:
            zf.extract(m, out_dir)
            done += m.file_size
            if time.time() - last > 2.0:
                last = time.time()
                print(f"\r    {human(done)} / {human(total)}   ", end="", flush=True)
        print()

    if flatten:
        entries = [p for p in out_dir.iterdir() if p.name != "__MACOSX"]
        if len(entries) == 1 and entries[0].is_dir():
            root = entries[0]
            for child in list(root.iterdir()):
                target = out_dir / child.name
                if not target.exists():
                    child.rename(target)
            try:
                root.rmdir()
            except OSError:
                pass
            print(f"  struktur dirapikan: isi {root.name}/ dipindah ke {out_dir.name}/")
    return out_dir


def summarize(data_dir: Path) -> dict:
    """Hitung citra per kelas dari train.csv kalau ada, kalau tidak dari struktur folder."""
    info: dict = {"train_csv": None, "classes": {}, "total": 0}
    csvs = sorted(data_dir.rglob("train.csv")) + sorted(data_dir.rglob("Train.csv"))
    if csvs:
        path = csvs[0]
        info["train_csv"] = str(path)
        counts: Counter = Counter()
        with open(path, newline="", encoding="utf-8") as fh:
            reader = csv.DictReader(fh)
            field = next((f for f in (reader.fieldnames or []) if f.lower() == "label"), None)
            for row in reader:
                if field:
                    counts[row[field]] += 1
        info["classes"] = dict(sorted(counts.items()))
        info["total"] = sum(counts.values())
    else:
        image_root = next((p for p in data_dir.rglob("train_images") if p.is_dir()), None)
        if image_root:
            counts = {}
            for d in sorted(p for p in image_root.iterdir() if p.is_dir()):
                n = sum(1 for _ in d.glob("*.jpg"))
                counts[d.name] = n
            info["classes"] = counts
            info["total"] = sum(counts.values())
            info["train_csv"] = None
    return info


def main() -> int:
    ap = argparse.ArgumentParser(description="Unduh Paddy Doctor dari Kaggle ke data_raw.")
    ap.add_argument("--out", default=DEFAULT_OUT, help=f"folder tujuan (default: {DEFAULT_OUT})")
    ap.add_argument("--dataset", default=DEFAULT_DATASET, help="owner/slug dataset Kaggle")
    ap.add_argument("--competition", default=None, help=f"unduh lewat kompetisi, mis. {COMPETITION}")
    ap.add_argument("--kaggle-json", default=None, help="path kaggle.json")
    ap.add_argument("--list-files", action="store_true", help="tampilkan isi dataset lalu keluar")
    ap.add_argument("--max-pages", type=int, default=3, help="batas halaman saat --list-files")
    ap.add_argument("--no-extract", action="store_true", help="hanya simpan zip")
    ap.add_argument("--keep-structure", action="store_true", help="jangan rapikan folder akar zip")
    ap.add_argument("--force", action="store_true", help="unduh ulang walau zip sudah ada")
    args = ap.parse_args()

    if args.list_files:
        return list_dataset_files(args.competition or args.dataset, args.max_pages)

    raw_dir = Path(args.out).expanduser().resolve()
    mount_drive_if_needed(raw_dir)
    zip_dir = raw_dir / "kaggle"
    zip_dir.mkdir(parents=True, exist_ok=True)

    if args.competition:
        slug = args.competition
        url = f"https://www.kaggle.com/api/v1/competitions/data/download-all/{slug}"
    else:
        slug = args.dataset
        url = f"https://www.kaggle.com/api/v1/datasets/download/{slug}"

    print(f"Tujuan : {raw_dir}")
    print(f"Sumber : Kaggle {slug}")
    print(f"URL    : {url}")

    user, key = load_credentials(args)
    print(f"Akun   : {user}")
    session = requests.Session()

    zip_path = zip_dir / f"{slug.replace('/', '__')}.zip"
    if zip_path.exists() and not args.force:
        print(f"  = zip sudah ada ({human(zip_path.stat().st_size)}), unduhan dilewati")
    else:
        print("  + mengunduh ...")
        size = download(session, url, zip_path, (user, key))
        print(f"  zip tersimpan: {zip_path} ({human(size)})")
        if not zipfile.is_zipfile(zip_path):
            print("  ! berkas bukan zip yang sah (mungkin respons error disimpan)")
            return 2

    data_dir = raw_dir / "paddy_doctor"
    if not args.no_extract:
        marker = data_dir / ".extracted"
        if marker.exists() and not args.force:
            print(f"  = {data_dir} sudah diekstrak, dilewati")
        else:
            print("  + mengekstrak ...")
            extract(zip_path, data_dir, flatten=not args.keep_structure)
            marker.write_text(datetime.now(timezone.utc).isoformat(timespec="seconds"), encoding="utf-8")

    info = summarize(data_dir)
    if info["classes"]:
        print(f"  kelas: {len(info['classes'])}, citra: {info['total']}")
        for name, n in info["classes"].items():
            print(f"    {name:<32} {n}")
        if info["total"] != 16225:
            print(f"  ! jumlah {info['total']} != 16.225 (cakupan bisa berbeda dari kompetisi asli)")
    else:
        print("  ! train.csv / train_images tidak ditemukan, isi folder tidak dikenali")

    manifest = {
        "source": f"https://www.kaggle.com/{'competitions/' + slug if args.competition else 'datasets/' + slug}",
        "kind": "competition" if args.competition else "dataset",
        "slug": slug,
        "zip": str(zip_path),
        "zip_bytes": zip_path.stat().st_size if zip_path.exists() else None,
        "data_dir": str(data_dir),
        "fetched_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "train_csv": info["train_csv"],
        "classes": info["classes"],
        "total_images": info["total"],
        "catatan": (
            "Dataset Kaggle ini adalah mirror kompetisi paddy-disease-classification. "
            "Split beku proyek lama (SEED=42, 300/kelas) dibuat dari mirror Hugging Face, "
            "bukan dari sini, sehingga uid tidak sama; himpunan gambarnya harus didefinisikan "
            "ulang dan disimpan sebagai zip + sha256."
        ),
    }
    manifest_path = raw_dir / "manifest_kaggle.json"
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"  manifest -> {manifest_path}")
    print("Selesai.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
