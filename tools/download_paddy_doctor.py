#!/usr/bin/env python3
"""Unduh dataset Paddy Doctor ke MyDrive/padicheck/data_raw (idempoten + terverifikasi).

Sumber : https://huggingface.co/datasets/anthony2261/paddy-disease-classification
Isi     : 10 kelas, 10.407 citra, 2 berkas parquet (kolom: image, label, variety, age)
Pinning : revision dikunci ke commit 2023-12-27 supaya split beku tetap sama tiap unduh.

Pemakaian di Colab (Drive otomatis di-mount):
    !python download_paddy_doctor.py

Pemakaian lokal / tanpa Drive:
    python download_paddy_doctor.py --out "D:\\Visikom\\data\\raw"

Cek tanpa mengunduh:
    python download_paddy_doctor.py --dry-run

Ekstrak citra (opsional, hanya 4 kelas yang dipakai Visikom, maks 400/kelas):
    python download_paddy_doctor.py --extract --limit-per-class 400

Catatan kejujuran: Paddy Doctor asli (Kaggle) berisi 16.225 citra / 13 kelas; mirror HF ini
hanya memuat 10 kelas / 10.407 citra. Skrip ini tidak menyembunyikan selisih itu, melainkan
mencatatnya di manifest.json.
"""

import argparse
import hashlib
import io
import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import requests

REPO = "anthony2261/paddy-disease-classification"
REVISION = "774edfc6bf92e9ca0ad29aeb5c1eccf4e9968182"  # 2023-12-27
FILES = [
    "data/train-00000-of-00002-a929229f3aaf7166.parquet",
    "data/train-00001-of-00002-4c2a20b9469e90df.parquet",
]

LABEL_NAMES = [
    "bacterial_leaf_blight",
    "bacterial_leaf_streak",
    "bacterial_panicle_blight",
    "blast",
    "brown_spot",
    "dead_heart",
    "downy_mildew",
    "hispa",
    "normal",
    "tungro",
]

# Empat kelas yang beririsan dengan taksonomi PadiCheck/Visikom (indeks label HF -> nama proyek).
VISIKOM_MAP = {
    0: "Bacterial Leaf Blight",
    3: "Leaf Blast",
    4: "Brown Spot",
    8: "Healthy",
}

CHUNK = 1 << 20
DEFAULT_OUT = "/content/drive/MyDrive/padicheck/data_raw"


def human(n: float) -> str:
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024 or unit == "GB":
            return f"{n:.1f} {unit}"
        n /= 1024
    return f"{n:.1f} GB"


def resolve_url(repo: str, revision: str, path: str) -> str:
    return f"https://huggingface.co/datasets/{repo}/resolve/{revision}/{path}"


def mount_drive_if_needed(out: Path) -> None:
    """Mount Google Drive hanya kalau target ada di /content/drive dan belum ter-mount."""
    if not str(out).startswith("/content/drive"):
        return
    if Path("/content/drive/MyDrive").is_dir():
        return
    try:
        from google.colab import drive  # type: ignore

        print("Mount Google Drive ...")
        drive.mount("/content/drive")
    except ImportError as exc:
        raise SystemExit(
            f"Target {out} ada di /content/drive tetapi Drive belum ter-mount dan bukan Colab."
        ) from exc


def remote_size(session: requests.Session, url: str) -> int:
    try:
        r = session.head(url, allow_redirects=True, timeout=60)
        if r.status_code == 200:
            return int(r.headers.get("content-length") or 0)
    except requests.RequestException:
        pass
    return 0


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(CHUNK), b""):
            h.update(chunk)
    return h.hexdigest()


def download(session: requests.Session, url: str, dest: Path, expected: int) -> None:
    """Unduh dengan resume lewat berkas .part, lalu rename atomik."""
    dest.parent.mkdir(parents=True, exist_ok=True)
    part = dest.with_name(dest.name + ".part")
    start = part.stat().st_size if part.exists() else 0
    if expected and start > expected:
        start = 0
        part.unlink()

    headers = {"Range": f"bytes={start}-"} if start else {}
    with session.get(url, headers=headers, stream=True, timeout=120) as r:
        r.raise_for_status()
        resumed = start > 0 and r.status_code == 206
        mode = "ab" if resumed else "wb"
        done = start if resumed else 0
        if not resumed:
            start = 0
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
    print()
    part.replace(dest)


def label_counts(paths: list[Path]) -> dict[str, int]:
    try:
        import pyarrow.parquet as pq  # type: ignore
    except ImportError:
        return {}
    counts: dict[str, int] = {}
    for p in paths:
        table = pq.read_table(p, columns=["label"])
        for value in table.column("label").to_pylist():
            name = LABEL_NAMES[value] if isinstance(value, int) and value < len(LABEL_NAMES) else str(value)
            counts[name] = counts.get(name, 0) + 1
    return counts


def extract_images(paths: list[Path], out_dir: Path, classes: set[str] | None, per_class: int) -> int:
    try:
        import pyarrow.parquet as pq  # type: ignore
        from PIL import Image  # type: ignore
    except ImportError as exc:
        raise SystemExit("Ekstraksi butuh pyarrow + pillow: pip install pyarrow pillow") from exc

    written: dict[str, int] = {}
    total = 0
    for p in paths:
        pf = pq.ParquetFile(p)
        for batch in pf.iter_batches(batch_size=200, columns=["image", "label"]):
            images = batch.column("image").to_pylist()
            labels = batch.column("label").to_pylist()
            for image, label in zip(images, labels):
                name = LABEL_NAMES[label] if isinstance(label, int) and label < len(LABEL_NAMES) else str(label)
                if classes and name not in classes:
                    continue
                if written.get(name, 0) >= per_class:
                    continue
                raw = image.get("bytes") if isinstance(image, dict) else image
                if not raw:
                    continue
                target = out_dir / name
                target.mkdir(parents=True, exist_ok=True)
                index = written.get(name, 0)
                with Image.open(io.BytesIO(raw)) as im:
                    im.convert("RGB").save(target / f"{name}_{index:05d}.jpg", quality=95)
                written[name] = index + 1
                total += 1
        if classes and all(written.get(c, 0) >= per_class for c in classes):
            break
    print("  ekstrak:", ", ".join(f"{k}={v}" for k, v in sorted(written.items())))
    return total


def main() -> int:
    ap = argparse.ArgumentParser(description="Unduh Paddy Doctor ke data_raw.")
    ap.add_argument("--out", default=DEFAULT_OUT, help=f"folder tujuan (default: {DEFAULT_OUT})")
    ap.add_argument("--repo", default=REPO)
    ap.add_argument("--revision", default=REVISION, help="commit hash HF; pakai 'main' kalau ingin ikut HEAD")
    ap.add_argument("--dry-run", action="store_true", help="hanya cek tautan dan ukuran")
    ap.add_argument("--force", action="store_true", help="unduh ulang walau sudah ada")
    ap.add_argument("--extract", action="store_true", help="ekstrak citra dari parquet")
    ap.add_argument("--classes", default=None, help="daftar kelas (dipisah koma); default 4 kelas Visikom")
    ap.add_argument("--limit-per-class", type=int, default=400, help="batas citra per kelas saat ekstrak")
    args = ap.parse_args()

    raw_dir = Path(args.out).expanduser().resolve()
    mount_drive_if_needed(raw_dir)
    raw_dir.mkdir(parents=True, exist_ok=True)
    print(f"Tujuan : {raw_dir}")
    print(f"Sumber : {args.repo} @ {args.revision[:12]}")

    session = requests.Session()
    session.headers.update({"User-Agent": "visikom-dataset-fetcher/1.0"})

    plan = []
    for rel in FILES:
        url = resolve_url(args.repo, args.revision, rel)
        size = remote_size(session, url)
        if size == 0 and not args.dry_run:
            print(f"  ! tidak bisa membaca ukuran {rel} (lanjut dengan progres tanpa persen)")
        plan.append((rel, url, Path(rel).name, size))
        print(f"  {Path(rel).name}  {human(size) if size else 'ukuran tidak diketahui'}")

    if args.dry_run:
        print("Dry run selesai, tidak ada berkas yang diunduh.")
        return 0

    manifest_path = raw_dir / "manifest.json"
    previous = {}
    if manifest_path.exists():
        try:
            old = json.loads(manifest_path.read_text(encoding="utf-8"))
            previous = {f["name"]: f.get("sha256") for f in old.get("files", [])}
        except (json.JSONDecodeError, KeyError):
            previous = {}

    entries = []
    for rel, url, name, size in plan:
        dest = raw_dir / name
        if dest.exists() and not args.force and size and dest.stat().st_size == size:
            digest = sha256_file(dest)
            if previous.get(name) in (None, digest):
                print(f"  = {name} sudah lengkap, dilewati")
                entries.append({"name": name, "path": rel, "bytes": dest.stat().st_size,
                                "sha256": digest, "url": url, "status": "skipped"})
                continue
        print(f"  + mengunduh {name}")
        download(session, url, dest, size)
        digest = sha256_file(dest)
        actual = dest.stat().st_size
        if size and actual != size:
            print(f"  ! ukuran tidak cocok: {actual} vs {size}")
        entries.append({"name": name, "path": rel, "bytes": actual,
                        "sha256": digest, "url": url, "status": "downloaded"})
        print(f"    sha256 {digest}")

    parquet_paths = [raw_dir / e["name"] for e in entries]
    counts = label_counts(parquet_paths)

    manifest = {
        "dataset": args.repo,
        "source_page": f"https://huggingface.co/datasets/{args.repo}",
        "revision": args.revision,
        "fetched_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "files": entries,
        "label_names": LABEL_NAMES,
        "label_counts": counts,
        "total_rows": sum(counts.values()) if counts else None,
        "visikom_map": {str(k): v for k, v in VISIKOM_MAP.items()},
        "catatan": (
            "Paddy Doctor asli (Kaggle) berisi 16.225 citra / 13 kelas; mirror HF ini memuat "
            "10 kelas / 10.407 citra. Split beku proyek lama (SEED=42, 300/kelas) bergantung "
            "pada urutan baris parquet, jadi revision wajib dipin seperti di manifest ini."
        ),
    }
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"  manifest -> {manifest_path}")

    if counts and sum(counts.values()) != 10407:
        print(f"  ! jumlah baris {sum(counts.values())}, bukan 10.407 seperti yang diharapkan")

    if args.extract:
        classes = set(VISIKOM_MAP.values())
        if args.classes:
            classes = {c.strip() for c in args.classes.split(",") if c.strip()}
        wanted = set()
        for idx, name in enumerate(LABEL_NAMES):
            if name in classes or VISIKOM_MAP.get(idx) in classes:
                wanted.add(name)
        print(f"Ekstrak citra ke {raw_dir / 'images'} (kelas: {', '.join(sorted(wanted))}) ...")
        n = extract_images(parquet_paths, raw_dir / "images", wanted, args.limit_per_class)
        print(f"  {n} citra ditulis")

    print("Selesai.")
    print(f"  data_raw : {raw_dir}")
    print("  langkah berikutnya: bangun split beku (SEED=42, 300/kelas) lalu simpan sebagai zip + sha256")
    return 0


if __name__ == "__main__":
    sys.exit(main())
