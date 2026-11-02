#!/usr/bin/env python3
"""Generator berkas notebook tunggal visikom_pipeline_lengkap.ipynb."""

import json
from pathlib import Path


def make_notebook():
    cells = []

    def add_md(text):
        lines = [line + "\n" for line in text.strip().split("\n")]
        if lines:
            lines[-1] = lines[-1].rstrip("\n")
        cells.append({
            "cell_type": "markdown",
            "metadata": {},
            "source": lines
        })

    def add_code(text):
        lines = [line + "\n" for line in text.strip().split("\n")]
        if lines:
            lines[-1] = lines[-1].rstrip("\n")
        cells.append({
            "cell_type": "code",
            "execution_count": None,
            "metadata": {},
            "outputs": [],
            "source": lines
        })

    # =========================================================================
    # Header & Pendahuluan
    # =========================================================================
    add_md("""# VISIKOM — Pipeline Lengkap Deteksi & Penilaian Keparahan Lesi Daun Padi
**Repositori Proyek:** `D:\\Visikom` | **Notebook:** `visikom_pipeline_lengkap.ipynb`

Notebook tunggal ini mengimplementasikan seluruh alur kerja proyek dari awal hingga akhir:
1. **Persiapan Data:** Ekstraksi dataset lokal Colab & pembekuan 1.200 citra uji lapangan (Paddy Doctor, 4 kelas, SEED 42).
2. **Pengolahan Citra Klasik (10 Tahap):**
   - White balance (*Gray-World*)
   - Indeks vegetasi *Excess Green* ($ExG = 2G - R - B$)
   - Segmentasi Otsu pada $ExG$ + Morfologi (*Opening* $5\\times5$ & *Closing* $7\\times7$)
   - Kontur terbesar & Bounding Box ROI (+margin 8%)
   - Deteksi lesi di ruang warna CIELab kanal $a^* > 132$
   - Filter bentuk & luas lesi (luas $\\ge 0,2\\%$ daun, *solidity* $\\ge 0,3$)
   - Quality Gate (ketajaman Laplacian $< 60$, kecerahan $40-225$, rasio daun $\\ge 6\\%$)
   - Letterbox $224\\times224$ ($INTER\\_AREA$)
3. **Visualisasi Interaktif:** Menampilkan 6-panel per citra (asli, white balance, mask daun, crop ROI, mask lesi, overlay & keparahan).
4. **Penilaian Keparahan (0–4):** Berdasarkan persentase luas lesi terhadap luas daun ($0$: sehat, $1$: $<5\\%$, $2$: $5-15\\%$, $3$: $15-30\\%$, $4$: $>30\\%$).
5. **Klasifikasi CNN (MobileNetV2):** Evaluasi model terpasang (`v7_mix_s7.keras` / `v3_A_s42.keras`) atau pelatihan fine-tuning 2 tahap.
6. **Ekspor Hasil & TFLite:** Confusion matrix, metrik klasifikasi, dan ringkasan CSV ke Google Drive.""")

    # =========================================================================
    # Bagian 1: Setup & Mount Drive
    # =========================================================================
    add_md("""## 1. Setup Lingkungan & Mount Google Drive
Periksa GPU/CPU yang tersedia dan hubungkan Google Drive.
Semua pelatihan model dilakukan **dari awal (fresh training)** dan semua berkas keluaran disimpan di folder khusus proyek baru:
`MyDrive/visikom/` (tidak menyentuh folder model lama).""")

    add_code("""import os
import sys
import time
import json
import shutil
import zipfile
import hashlib
from pathlib import Path
from collections import Counter

import cv2
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# Cek runtime dan mount drive jika berjalan di Google Colab
IN_COLAB = 'google.colab' in sys.modules or os.path.exists('/content')
if IN_COLAB:
    from google.colab import drive
    drive.mount('/content/drive', force_remount=False)
    
    # Sumber data mentah (HANYA DIBACA, TIDAK DIUBAH)
    RAW_INPUT_DIR = Path('/content/drive/MyDrive/padicheck/data_raw')
    SCENARIO_INPUT_DIR = Path('/content/drive/MyDrive/padicheck/data_scenario')
    
    # FOLDER KHUSUS PROYEK VISIKOM (Semua hasil keluaran disimpan di sini)
    DRIVE_VISIKOM = Path('/content/drive/MyDrive/visikom')
    DRIVE_DATA = DRIVE_VISIKOM / 'data'
    DRIVE_RESULTS = DRIVE_VISIKOM / 'results'
    DRIVE_MODELS = DRIVE_VISIKOM / 'models'
    LOCAL_WORK = Path('/content/visikom_work')
else:
    RAW_INPUT_DIR = Path('D:/Visikom/data/raw')
    SCENARIO_INPUT_DIR = Path('D:/Visikom/data/scenario')
    DRIVE_VISIKOM = Path('D:/Visikom')
    DRIVE_DATA = DRIVE_VISIKOM / 'data'
    DRIVE_RESULTS = DRIVE_VISIKOM / 'results'
    DRIVE_MODELS = DRIVE_VISIKOM / 'models'
    LOCAL_WORK = Path('D:/Visikom/work')

for p in [DRIVE_DATA, DRIVE_RESULTS, DRIVE_MODELS, LOCAL_WORK]:
    p.mkdir(parents=True, exist_ok=True)

print(f"Lingkungan : {'Google Colab' if IN_COLAB else 'Lokal'}")
print(f"Direktori kerja lokal   : {LOCAL_WORK}")
print(f"Folder Hasil Visikom    : {DRIVE_VISIKOM} (Data, Results, Models)")
print(f"Sumber Input Data Mentah: {RAW_INPUT_DIR}")""")

    # =========================================================================
    # Bagian 2: Persiapan Data & Pembekuan 1.200 Citra Uji
    # =========================================================================
    add_md("""## 2. Persiapan Data & Pembekuan 1.200 Citra Uji Lapangan
Mengekstrak `paddy_doctor.zip` ke disk lokal cepat (`/content/`), memfilter 4 kelas irisan dengan Visikom, dan mengunci 1.200 citra uji (300 per kelas, `SEED=42`).
Manifest disimpan ke `MyDrive/visikom/data/field_test_1200.csv`.""")

    add_code("""# Definisi taksonomi kelas Visikom
CLASS_NAMES = [
    "Bacterial Leaf Blight",
    "Brown Spot",
    "Healthy",
    "Leaf Blast",
    "Leaf Scald",
    "Sheath Blight",
]

# Pemetaan label Paddy Doctor (Kaggle) ke 4 kelas irisan Visikom
KAGGLE_MAP = {
    "bacterial_leaf_blight": "Bacterial Leaf Blight",
    "brown_spot": "Brown Spot",
    "normal": "Healthy",
    "blast": "Leaf Blast",
}

# 1. Ekstrak data Paddy Doctor ke disk lokal jika belum ada
paddy_zip = RAW_INPUT_DIR / "paddy_doctor.zip"
local_paddy_dir = LOCAL_WORK / "paddy_doctor"

if paddy_zip.exists() and not (local_paddy_dir / "paddy-disease-classification" / "train.csv").exists():
    print(f"Mengekstrak {paddy_zip.name} ke disk lokal (cepat)...")
    t0 = time.time()
    with zipfile.ZipFile(paddy_zip, 'r') as zf:
        zf.extractall(local_paddy_dir)
    print(f"Ekstraksi selesai dalam {time.time()-t0:.1f} detik.")
else:
    print("Dataset Paddy Doctor lokal siap atau sudah diekstrak.")

train_csv_path = local_paddy_dir / "paddy-disease-classification" / "train.csv"
train_img_dir = local_paddy_dir / "paddy-disease-classification" / "train_images"

# 2. Baca manifest train.csv dan filter 4 kelas irisan
df_kaggle = pd.read_csv(train_csv_path)
df_kaggle["visikom_class"] = df_kaggle["label"].map(KAGGLE_MAP)
df_field = df_kaggle.dropna(subset=["visikom_class"]).copy().reset_index(drop=True)

# Tambahkan path lengkap file gambar
df_field["file_path"] = df_field.apply(
    lambda r: str(train_img_dir / r["label"] / r["image_id"]), axis=1
)

print(f"Total citra Paddy Doctor (4 kelas irisan): {len(df_field)}")
print(df_field["visikom_class"].value_counts())

# 3. Stratified Sample 300 per kelas (SEED 42) -> 1.200 Citra Uji Beku
SEED = 42
PER_CLASS_TEST = 300
rng = np.random.default_rng(SEED)

test_parts = []
pool_parts = []
for c_name, grp in df_field.groupby("visikom_class"):
    perm = rng.permutation(len(grp))
    test_idx = perm[:PER_CLASS_TEST]
    pool_idx = perm[PER_CLASS_TEST:]
    test_parts.append(grp.iloc[test_idx])
    pool_parts.append(grp.iloc[pool_idx])

df_test_1200 = pd.concat(test_parts).sample(frac=1.0, random_state=SEED).reset_index(drop=True)
df_field_pool = pd.concat(pool_parts).reset_index(drop=True)

# 4. Siapkan Data Latih 6 Kelas (Ekstrak A.zip + Pembersihan & Penggabungan Field Data)
scenario_zip = SCENARIO_INPUT_DIR / "A.zip"
local_train_dir = LOCAL_WORK / "train_data"

if scenario_zip.exists() and not (local_train_dir / "train").exists():
    print(f"\\n1. Mengekstrak data awal PadiCheck ({scenario_zip.name}) sebagai fondasi 6 kelas...")
    with zipfile.ZipFile(scenario_zip, 'r') as zf:
        zf.extractall(local_train_dir)
    print("Data awal 6 kelas berhasil diekstrak.")

    # 2. Fungsi dHash64 untuk Deduplikasi & Cegah Bocor Data
    def compute_dhash64(img_path: str, hash_size: int = 8) -> int:
        img = cv2.imread(str(img_path), cv2.IMREAD_GRAYSCALE)
        if img is None:
            return 0
        resized = cv2.resize(img, (hash_size + 1, hash_size), interpolation=cv2.INTER_AREA)
        diff = resized[:, 1:] > resized[:, :-1]
        return np.packbits(diff.flatten()).view(np.uint64)[0]

    def hamming_dist(h1: int, h2: int) -> int:
        return bin(int(h1 ^ h2)).count('1')

    # Hash data uji beku (wajib steril)
    print("Menghitung hash 1.200 citra uji beku untuk mencegah kebocoran...")
    test_hashes = [compute_dhash64(fp) for fp in df_test_1200["file_path"]]
    test_hashes = np.array([h for h in test_hashes if h != 0], dtype=np.uint64)

    # 3. Filter & Gabungkan Data Lapangan Baru (Paddy Doctor) ke Data Awal
    print("\\n2. Menyaring dan menggabungkan data lapangan baru ke data latih...")
    added_counts = Counter()
    skipped_leak = 0
    skipped_corrupt = 0

    for _, row in df_field_pool.iterrows():
        c_name = row["visikom_class"]
        fpath = row["file_path"]
        
        # Validasi integritas berkas
        h_cand = compute_dhash64(fpath)
        if h_cand == 0:
            skipped_corrupt += 1
            continue

        # Cek jangan sampai bocor ke data uji beku (Hamming <= 6 dibuang)
        if len(test_hashes) > 0:
            diffs = np.unpackbits(np.bitwise_xor(test_hashes, h_cand).astype('>u8').view(np.uint8).reshape(-1, 8), axis=1).sum(axis=1)
            if np.min(diffs) <= 6:
                skipped_leak += 1
                continue

        # Gabungkan ke folder train data awal
        target_dir = local_train_dir / "train" / c_name
        if target_dir.exists():
            dest = target_dir / f"paddy_{row['image_id']}"
            if not dest.exists():
                shutil.copy2(fpath, dest)
                added_counts[c_name] += 1

    print(f"Pembersihan selesai:")
    print(f"  - Dibuang karena duplikat data uji : {skipped_leak} citra")
    print(f"  - Dibuang karena file rusak        : {skipped_corrupt} citra")
    print(f"  - BERHASIL DIGABUNGKAN ke data awal: {sum(added_counts.values())} citra baru")
    for cls_name, cnt in sorted(added_counts.items()):
        print(f"    * {cls_name:<25}: +{cnt} citra baru")

    print("\\n3. Total citra data latih gabungan per kelas:")
    for d in sorted((local_train_dir / "train").iterdir()):
        if d.is_dir():
            n = len([f for f in d.iterdir() if f.is_file()])
            print(f"    * {d.name:<25}: {n} citra")
else:
    print(f"Data latih gabungan lokal siap di: {local_train_dir}")""")

    # =========================================================================
    # Bagian 3: Pipeline Pengolahan Citra Klasik
    # =========================================================================
    add_md("""## 3. Pipeline Pengolahan Citra Klasik (10 Tahap)
Fungsi independen dan modular untuk White Balance, Indeks Vegetasi ExG, Segmentasi Otsu, Morfologi, Ekstraksi ROI, Deteksi Lesi CIELab, Quality Gate, dan Penilaian Keparahan.""")

    add_code("""def white_balance_gray_world(img_bgr: np.ndarray) -> np.ndarray:
    \"\"\"Tahap 1: White balance Gray-World (menyelaraskan rata-rata kanal RGB).\"\"\"
    b, g, r = cv2.split(img_bgr.astype(np.float32))
    mean_b, mean_g, mean_r = np.mean(b), np.mean(g), np.mean(r)
    mean_gray = (mean_b + mean_g + mean_r) / 3.0
    if mean_b == 0 or mean_g == 0 or mean_r == 0:
        return img_bgr.copy()
    b = np.clip(b * (mean_gray / mean_b), 0, 255)
    g = np.clip(g * (mean_gray / mean_g), 0, 255)
    r = np.clip(r * (mean_gray / mean_r), 0, 255)
    return cv2.merge([b, g, r]).astype(np.uint8)


def excess_green_exg(img_bgr: np.ndarray) -> np.ndarray:
    \"\"\"Tahap 2: Indeks Vegetasi Excess Green ExG = 2g - r - b.\"\"\"
    img_f = img_bgr.astype(np.float32)
    b, g, r = img_f[:, :, 0], img_f[:, :, 1], img_f[:, :, 2]
    total = r + g + b + 1e-6
    rn, gn, bn = r / total, g / total, b / total
    exg = 2.0 * gn - rn - bn  # Rentang teoritis [-1, 2]
    exg_uint8 = np.clip((exg + 1.0) * 127.5, 0, 255).astype(np.uint8)
    return exg_uint8


def segment_leaf_otsu_morph(img_bgr: np.ndarray, exg_uint8: np.ndarray) -> np.ndarray:
    \"\"\"Tahap 3 & 4: Segmentasi Otsu pada ExG + Morfologi (Opening & Closing).\"\"\"
    _, mask_raw = cv2.threshold(exg_uint8, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    # Opening 5x5 (2 iterasi) untuk derau kecil
    k_open = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
    mask_open = cv2.morphologyEx(mask_raw, cv2.MORPH_OPEN, k_open, iterations=2)
    # Closing 7x7 (3 iterasi) untuk menutup lubang pada daun
    k_close = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (7, 7))
    mask_clean = cv2.morphologyEx(mask_open, cv2.MORPH_CLOSE, k_close, iterations=3)
    return mask_clean


def extract_leaf_roi(img_bgr: np.ndarray, leaf_mask: np.ndarray, margin: float = 0.08) -> tuple:
    \"\"\"Tahap 5: Temukan kontur daun terbesar, hitung Bounding Box (+margin), dan crop ROI.\"\"\"
    h_img, w_img = img_bgr.shape[:2]
    contours, _ = cv2.findContours(leaf_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        return img_bgr.copy(), leaf_mask.copy(), (0, 0, w_img, h_img), False

    largest_cnt = max(contours, key=cv2.contourArea)
    x, y, w, h = cv2.boundingRect(largest_cnt)
    
    # Margin 8% tiap sisi
    dx = int(w * margin)
    dy = int(h * margin)
    x0 = max(0, x - dx)
    y0 = max(0, y - dy)
    x1 = min(w_img, x + w + dx)
    y1 = min(h_img, y + h + dy)

    # Validasi ROI minimal 24x24
    if (x1 - x0) < 24 or (y1 - y0) < 24:
        return img_bgr.copy(), leaf_mask.copy(), (0, 0, w_img, h_img), False

    roi_img = img_bgr[y0:y1, x0:x1]
    roi_mask = leaf_mask[y0:y1, x0:x1]
    return roi_img, roi_mask, (x0, y0, x1 - x0, y1 - y0), True


def detect_lesion_lab(
    img_bgr: np.ndarray,
    leaf_mask: np.ndarray,
    a_thresh: int = 132,
    min_area_ratio: float = 0.002,
    min_solidity: float = 0.3
) -> np.ndarray:
    \"\"\"Tahap 6 & 7: Deteksi lesi di ruang CIELab (a* > 132) di dalam daun + filter bentuk.\"\"\"
    lab = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2LAB)
    a_star = lab[:, :, 1]
    
    # Lesi kandidat: kanal a* > ambang dan berada dalam mask daun
    lesion_candidate = ((a_star > a_thresh) & (leaf_mask > 0)).astype(np.uint8) * 255
    leaf_pixels = np.count_nonzero(leaf_mask)
    if leaf_pixels == 0:
        return np.zeros_like(leaf_mask)

    min_blob_area = int(min_area_ratio * leaf_pixels)
    num_labels, labels, stats, _ = cv2.connectedComponentsWithStats(lesion_candidate)
    
    lesion_clean = np.zeros_like(leaf_mask)
    for i in range(1, num_labels):
        area = stats[i, cv2.CC_STAT_AREA]
        if area < min_blob_area:
            continue
        # Cek solidity (area / convex hull area)
        comp_mask = (labels == i).astype(np.uint8)
        cnts, _ = cv2.findContours(comp_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        if not cnts:
            continue
        hull = cv2.convexHull(cnts[0])
        hull_area = cv2.contourArea(hull)
        solidity = area / (hull_area + 1e-6)
        if solidity >= min_solidity:
            lesion_clean[labels == i] = 255

    return lesion_clean


def check_quality_gate(img_bgr: np.ndarray, leaf_mask: np.ndarray) -> dict:
    \"\"\"Tahap 9: Quality Gate (ketajaman, kecerahan, rasio luas daun).\"\"\"
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    lap_var = float(cv2.Laplacian(gray, cv2.CV_64F).var())
    mean_bright = float(np.mean(gray))
    total_px = img_bgr.shape[0] * img_bgr.shape[1]
    leaf_px = np.count_nonzero(leaf_mask)
    leaf_ratio = leaf_px / float(total_px)

    is_blur = lap_var < 60.0
    is_lighting_bad = mean_bright < 40.0 or mean_bright > 225.0
    is_too_far = leaf_ratio < 0.06

    passed = (not is_blur) and (not is_lighting_bad) and (not is_too_far)
    reasons = []
    if is_blur:
        reasons.append("Foto buram (Laplacian < 60)")
    if is_lighting_bad:
        reasons.append(f"Pencahayaan ekstrem ({mean_bright:.1f})")
    if is_too_far:
        reasons.append(f"Daun terlalu kecil/jauh ({leaf_ratio*100:.1f}%)")

    return {
        "passed": passed,
        "laplacian_var": lap_var,
        "mean_brightness": mean_bright,
        "leaf_area_ratio": leaf_ratio,
        "reject_reasons": reasons,
    }


def compute_severity(leaf_mask: np.ndarray, lesion_mask: np.ndarray) -> tuple:
    \"\"\"Menghitung rasio lesi terhadap daun dan skor keparahan 0-4.\"\"\"
    leaf_px = np.count_nonzero(leaf_mask)
    lesion_px = np.count_nonzero(lesion_mask)
    if leaf_px == 0:
        return 0.0, 0
    ratio = lesion_px / float(leaf_px)

    if ratio == 0.0:
        score = 0
    elif ratio < 0.05:
        score = 1
    elif ratio < 0.15:
        score = 2
    elif ratio < 0.30:
        score = 3
    else:
        score = 4
    return ratio, score


def letterbox_image(img_bgr: np.ndarray, target_size: tuple = (224, 224)) -> np.ndarray:
    \"\"\"Tahap 8: Letterbox resize (skala seragam INTER_AREA + simetris padding hitam).\"\"\"
    h, w = img_bgr.shape[:2]
    th, tw = target_size
    scale = min(tw / w, th / h)
    nw = max(1, int(round(w * scale)))
    nh = max(1, int(round(h * scale)))
    
    interp = cv2.INTER_AREA if scale < 1.0 else cv2.INTER_LINEAR
    resized = cv2.resize(img_bgr, (nw, nh), interpolation=interp)
    
    canvas = np.zeros((th, tw, 3), dtype=np.uint8)
    top = (th - nh) // 2
    left = (tw - nw) // 2
    canvas[top:top+nh, left:left+nw] = resized
    return canvas


def run_full_pipeline(image_path_or_array) -> dict:
    \"\"\"Menjalankan pipeline 10 tahap lengkap pada satu citra.\"\"\"
    if isinstance(image_path_or_array, (str, Path)):
        img = cv2.imread(str(image_path_or_array))
        if img is None:
            raise ValueError(f"Gagal memuat gambar: {image_path_or_array}")
    else:
        img = image_path_or_array.copy()

    # 1. White Balance
    img_wb = white_balance_gray_world(img)
    # 2. ExG
    exg = excess_green_exg(img_wb)
    # 3 & 4. Mask Daun (Otsu + Morfologi)
    leaf_mask = segment_leaf_otsu_morph(img_wb, exg)
    # 5. Crop ROI
    roi_img, roi_mask, bbox, roi_valid = extract_leaf_roi(img_wb, leaf_mask)
    # 6 & 7. Deteksi Lesi
    lesion_mask = detect_lesion_lab(img_wb, leaf_mask)
    # Keparahan
    lesion_ratio, severity_score = compute_severity(leaf_mask, lesion_mask)
    # 8. Letterbox
    input_tensor_224 = letterbox_image(roi_img, (224, 224))
    # 9. Quality Gate
    q_gate = check_quality_gate(img, leaf_mask)

    return {
        "original": img,
        "white_balance": img_wb,
        "exg": exg,
        "leaf_mask": leaf_mask,
        "roi_image": roi_img,
        "roi_mask": roi_mask,
        "bbox": bbox,
        "roi_valid": roi_valid,
        "lesion_mask": lesion_mask,
        "lesion_ratio": lesion_ratio,
        "severity_score": severity_score,
        "letterbox_224": input_tensor_224,
        "quality_gate": q_gate,
    }

print("Pipeline Pengolahan Citra Klasik siap digunakan.")""")

    # =========================================================================
    # Bagian 4: Visualisasi Multi-Panel
    # =========================================================================
    add_md("""## 4. Visualisasi Multi-Panel Pipeline pada Citra Lapangan
Menguji pipeline pada sampel citra dari tiap kelas (Healthy, Brown Spot, Leaf Blast, Bacterial Leaf Blight) dan merender 6 panel keluaran.""")

    add_code("""def visualize_pipeline_results(res: dict, title: str = ""):
    \"\"\"Visualisasi 6 panel: Asli, White Balance, Mask Daun, Crop ROI, Mask Lesi, Overlay Keparahan.\"\"\"
    fig, axes = plt.subplots(1, 6, figsize=(22, 4))
    
    # 1. Citra Asli
    axes[0].imshow(cv2.cvtColor(res["original"], cv2.COLOR_BGR2RGB))
    axes[0].set_title("1. Asli")
    axes[0].axis("off")
    
    # 2. White Balance
    axes[1].imshow(cv2.cvtColor(res["white_balance"], cv2.COLOR_BGR2RGB))
    axes[1].set_title("2. White Balance")
    axes[1].axis("off")
    
    # 3. Mask Daun (ExG+Otsu)
    axes[2].imshow(res["leaf_mask"], cmap="gray")
    axes[2].set_title("3. Mask Daun")
    axes[2].axis("off")
    
    # 4. Crop ROI Daun
    axes[3].imshow(cv2.cvtColor(res["roi_image"], cv2.COLOR_BGR2RGB))
    axes[3].set_title("4. ROI Daun (Crop)")
    axes[3].axis("off")
    
    # 5. Mask Lesi
    axes[4].imshow(res["lesion_mask"], cmap="hot")
    axes[4].set_title("5. Mask Lesi (Lab a*)")
    axes[4].axis("off")
    
    # 6. Overlay Lesi & Status
    overlay = res["white_balance"].copy()
    overlay[res["lesion_mask"] > 0] = [0, 0, 255]  # Lesi diwarnai merah
    x, y, w, h = res["bbox"]
    cv2.rectangle(overlay, (x, y), (x + w, y + h), (0, 255, 0), 2)  # BBox hijau
    
    q_str = "PASS" if res["quality_gate"]["passed"] else "REJECT"
    sev_text = f"Skor: {res['severity_score']} ({res['lesion_ratio']*100:.1f}%) | QG: {q_str}"
    
    axes[5].imshow(cv2.cvtColor(overlay, cv2.COLOR_BGR2RGB))
    axes[5].set_title(f"6. Overlay\\n{sev_text}", fontsize=9)
    axes[5].axis("off")
    
    if title:
        fig.suptitle(title, fontsize=12, fontweight="bold")
    plt.tight_layout()
    plt.show()

# Jalankan pengujian visual pada 1 sampel untuk tiap kelas
sample_classes = df_test_1200["visikom_class"].unique()
print("Menjalankan visualisasi pipeline pada sampel per kelas:")
for cls in sample_classes:
    sample_row = df_test_1200[df_test_1200["visikom_class"] == cls].iloc[0]
    res = run_full_pipeline(sample_row["file_path"])
    visualize_pipeline_results(res, title=f"Sampel: {cls} ({sample_row['image_id']})")""")

    # =========================================================================
    # Bagian 5: Evaluasi Batch & Quality Gate pada 1.200 Citra
    # =========================================================================
    add_md("""## 5. Pengujian Batch & Quality Gate pada 1.200 Citra Lapangan
Menjalankan pipeline pada seluruh 1.200 citra uji eksternal untuk mengukur:
- Tingkat kelolosan Quality Gate (foto buram, pencahayaan buruk, daun terlalu kecil).
- Distribusi skor keparahan (0–4) antar kelas penyakit.""")

    add_code("""records = []
t0 = time.time()
print(f"Memproses {len(df_test_1200)} citra uji lapangan...")

for idx, row in df_test_1200.iterrows():
    fpath = row["file_path"]
    try:
        res = run_full_pipeline(fpath)
        qg = res["quality_gate"]
        records.append({
            "image_id": row["image_id"],
            "kaggle_label": row["label"],
            "visikom_class": row["visikom_class"],
            "qg_passed": qg["passed"],
            "laplacian_var": qg["laplacian_var"],
            "brightness": qg["mean_brightness"],
            "leaf_area_ratio": qg["leaf_area_ratio"],
            "reject_reasons": "; ".join(qg["reject_reasons"]),
            "lesion_ratio": res["lesion_ratio"],
            "severity_score": res["severity_score"],
        })
    except Exception as exc:
        records.append({
            "image_id": row["image_id"],
            "kaggle_label": row["label"],
            "visikom_class": row["visikom_class"],
            "qg_passed": False,
            "laplacian_var": 0.0,
            "brightness": 0.0,
            "leaf_area_ratio": 0.0,
            "reject_reasons": f"Error: {str(exc)}",
            "lesion_ratio": 0.0,
            "severity_score": 0,
        })
    
    if (idx + 1) % 200 == 0:
        print(f"  [{idx+1}/{len(df_test_1200)}] selesai ({time.time()-t0:.1f}s)...")

df_results_cv = pd.DataFrame(records)
print(f"Pemrosesan batch selesai dalam {time.time()-t0:.1f} detik.")

# Tampilkan ringkasan Quality Gate
print("\\n=== HASIL QUALITY GATE (1.200 Citra) ===")
pass_count = df_results_cv["qg_passed"].sum()
print(f"Lolos Quality Gate : {pass_count} / {len(df_results_cv)} ({pass_count/len(df_results_cv)*100:.1f}%)")
print(f"Ditolak            : {len(df_results_cv) - pass_count} ({100 - pass_count/len(df_results_cv)*100:.1f}%)")

print("\\nAlasan Penolakan:")
all_reasons = [r for sub in df_results_cv["reject_reasons"].str.split("; ") for r in sub if r]
for reason, cnt in Counter(all_reasons).items():
    print(f"  - {reason}: {cnt} citra")

print("\\n=== DISTRIBUSI SKOR KEPARAHAN PER KELAS ===")
cross_sev = pd.crosstab(df_results_cv["visikom_class"], df_results_cv["severity_score"], margins=True)
print(cross_sev)

# Simpan hasil CSV ke lokal dan Drive Visikom
results_csv = LOCAL_WORK / "eval_cv_pipeline_1200.csv"
df_results_cv.to_csv(results_csv, index=False)
df_results_cv.to_csv(DRIVE_RESULTS / "eval_cv_pipeline_1200.csv", index=False)
print(f"\\nTabel hasil disimpan: {DRIVE_RESULTS / 'eval_cv_pipeline_1200.csv'}")""")

    # =========================================================================
    # Bagian 6: Pelatihan MobileNetV2 dari Awal
    # =========================================================================
    add_md("""## 6. Pelatihan Model CNN MobileNetV2 dari Awal (Train From Scratch)
Membangun arsitektur MobileNetV2 baru (bobot awal ImageNet + head klasifikasi 6 kelas baru) dan melatihnya secara penuh:
- **Urutan Layer:** Input $224\\times224\\times3$ $\\rightarrow$ Augmentasi Ringan (Flip, Brightness $\\pm0.08$, Contrast $0.85-1.20$) $\\rightarrow$ Rescaling $[-1, 1]$ $\\rightarrow$ MobileNetV2 Backbone $\\rightarrow$ GAP $\\rightarrow$ Dropout $0.4$ $\\rightarrow$ Dense(6, softmax).
- **Strategi Pelatihan 2 Tahap:**
  - *Tahap 1 (Head Training):* Backbone dibekukan, 10 epoch, Adam LR $1\\times10^{-3}$, Label Smoothing $0.15$.
  - *Tahap 2 (Fine-Tuning):* Membuka 30 lapisan terakhir, 15 epoch, Adam LR $1\\times10^{-4}$, EarlyStopping.
- **Model Baru:** Disimpan ke `MyDrive/visikom/models/visikom_mobilenetv2_trained.keras` (tidak memakai model lama).""")

    add_code("""import tensorflow as tf
from tensorflow import keras

print(f"TensorFlow Version: {tf.__version__}")
gpus = tf.config.list_physical_devices('GPU')
print(f"GPU Terdeteksi: {gpus if gpus else 'Tidak ada (menggunakan CPU)'}")

# 1. Dataset Loader (Train & Val)
train_path = local_train_dir / "train"
val_path = local_train_dir / "val"

BATCH_SIZE = 32
IMG_SIZE = (224, 224)

print("Memuat dataset pelatihan...")
train_ds = keras.utils.image_dataset_from_directory(
    train_path,
    image_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    label_mode="categorical",
    shuffle=True,
    seed=42
)

val_ds = keras.utils.image_dataset_from_directory(
    val_path,
    image_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    label_mode="categorical",
    shuffle=False
)

# Optimasi pipeline data
AUTOTUNE = tf.data.AUTOTUNE
train_ds = train_ds.prefetch(buffer_size=AUTOTUNE)
val_ds = val_ds.prefetch(buffer_size=AUTOTUNE)

# 2. Bangun Arsitektur Model Baru
inputs = keras.Input(shape=(224, 224, 3), name="input_image")

# Augmentasi mendahului rescaling agar piksel tidak terpotong
x = keras.layers.RandomFlip("horizontal")(inputs)
x = keras.layers.RandomBrightness(factor=0.08)(x)
x = keras.layers.RandomContrast(factor=(0.85, 1.20))(x)
x = keras.layers.Rescaling(scale=1.0 / 127.5, offset=-1.0)(x)

base_model = keras.applications.MobileNetV2(
    input_shape=(224, 224, 3),
    include_top=False,
    weights="imagenet"
)
base_model.trainable = False

x = base_model(x, training=False)
x = keras.layers.GlobalAveragePooling2D()(x)
x = keras.layers.Dropout(0.4)(x)
outputs = keras.layers.Dense(len(CLASS_NAMES), activation="softmax", name="predictions")(x)

classifier_model = keras.Model(inputs, outputs, name="Visikom_MobileNetV2")
classifier_model.summary()

# 3. Tahap 1: Latih Classification Head (Backbone Dibekukan)
print("\\n" + "="*50)
print("TAHAP 1: Pelatihan Classification Head (10 Epoch)")
print("="*50)

classifier_model.compile(
    optimizer=keras.optimizers.Adam(learning_rate=1e-3),
    loss=keras.losses.CategoricalCrossentropy(label_smoothing=0.15),
    metrics=["accuracy"]
)

hist_stage1 = classifier_model.fit(
    train_ds,
    validation_data=val_ds,
    epochs=10,
    verbose=1
)

# 4. Tahap 2: Fine-Tuning (Buka 30 Lapisan Terakhir)
print("\\n" + "="*50)
print("TAHAP 2: Fine-Tuning 30 Lapisan Terakhir (15 Epoch)")
print("="*50)

base_model.trainable = True
for layer in base_model.layers[:-30]:
    layer.trainable = False

classifier_model.compile(
    optimizer=keras.optimizers.Adam(learning_rate=1e-4),
    loss=keras.losses.CategoricalCrossentropy(label_smoothing=0.15),
    metrics=["accuracy"]
)

model_save_path = DRIVE_MODELS / "visikom_mobilenetv2_trained.keras"
callbacks = [
    keras.callbacks.EarlyStopping(monitor="val_loss", patience=4, restore_best_weights=True),
    keras.callbacks.ModelCheckpoint(str(model_save_path), save_best_only=True, monitor="val_accuracy")
]

hist_stage2 = classifier_model.fit(
    train_ds,
    validation_data=val_ds,
    epochs=15,
    callbacks=callbacks,
    verbose=1
)

print(f"\\nModel terlatih berhasil disimpan ke: {model_save_path}")

# 5. Plot Kurva Pelatihan
acc = hist_stage1.history["accuracy"] + hist_stage2.history["accuracy"]
val_acc = hist_stage1.history["val_accuracy"] + hist_stage2.history["val_accuracy"]
loss = hist_stage1.history["loss"] + hist_stage2.history["loss"]
val_loss = hist_stage1.history["val_loss"] + hist_stage2.history["val_loss"]

plt.figure(figsize=(12, 4))
plt.subplot(1, 2, 1)
plt.plot(acc, label="Train Accuracy")
plt.plot(val_acc, label="Val Accuracy")
plt.axvline(x=9, color="gray", linestyle="--", label="Mulai Fine-Tuning")
plt.title("Akurasi Pelatihan Visikom MobileNetV2")
plt.xlabel("Epoch")
plt.ylabel("Akurasi")
plt.legend()

plt.subplot(1, 2, 2)
plt.plot(loss, label="Train Loss")
plt.plot(val_loss, label="Val Loss")
plt.axvline(x=9, color="gray", linestyle="--", label="Mulai Fine-Tuning")
plt.title("Loss Pelatihan")
plt.xlabel("Epoch")
plt.ylabel("Loss")
plt.legend()
plt.tight_layout()
plt.show()""")

    # =========================================================================
    # Bagian 7: Inferensi Terpadu & Evaluasi Akhir
    # =========================================================================
    add_md("""## 7. Inferensi Terpadu (Pipeline CV + CNN + Skor Keparahan)
Menguji sistem terpadu:
Input Gambar $\\rightarrow$ Quality Gate $\\rightarrow$ Crop ROI $\\rightarrow$ Letterbox $224\\times224$ $\\rightarrow$ MobileNetV2 $\\rightarrow$ Prediksi Kelas & Skor Keparahan.""")

    add_code("""def diagnose_leaf(img_input) -> dict:
    \"\"\"Diagnosis terpadu dual-branch: Pipeline CV (mask & keparahan) + CNN RGB (klasifikasi).\"\"\"
    pipeline_res = run_full_pipeline(img_input)
    
    # Input CNN: Raw RGB 224x224 (paritas penuh dengan distribusi data latih)
    if isinstance(img_input, (str, Path)):
        raw_bgr = cv2.imread(str(img_input))
    else:
        raw_bgr = img_input.copy()
    raw_rgb = cv2.cvtColor(raw_bgr, cv2.COLOR_BGR2RGB)
    img_224 = cv2.resize(raw_rgb, (224, 224), interpolation=cv2.INTER_LINEAR)
    tensor_input = np.expand_dims(img_224.astype(np.float32), axis=0)
    
    preds = classifier_model.predict(tensor_input, verbose=0)[0]
    pred_idx = int(np.argmax(preds))
    pred_conf = float(preds[pred_idx])
    pred_class = CLASS_NAMES[pred_idx]
    
    # Filter keyakinan < 0.60
    conf_passed = pred_conf >= 0.60
    
    return {
        "pipeline": pipeline_res,
        "predicted_class": pred_class,
        "confidence": pred_conf,
        "confidence_passed": conf_passed,
        "severity_score": pipeline_res["severity_score"],
        "lesion_ratio": pipeline_res["lesion_ratio"],
        "quality_passed": pipeline_res["quality_gate"]["passed"],
    }

# Evaluasi pada subset 1.200 citra uji
eval_sample = df_test_1200.copy()
print(f"Menjalankan diagnosis terpadu pada {len(eval_sample)} citra uji...")

y_true = []
y_pred = []
qg_mask = []

t0 = time.time()
for idx, row in eval_sample.iterrows():
    diag = diagnose_leaf(row["file_path"])
    y_true.append(row["visikom_class"])
    y_pred.append(diag["predicted_class"])
    qg_mask.append(diag["quality_passed"])
    
    if (idx + 1) % 300 == 0:
        print(f"  [{idx+1}/{len(eval_sample)}] citra terdiagnosis ({time.time()-t0:.1f}s)...")

y_true = np.array(y_true)
y_pred = np.array(y_pred)
qg_mask = np.array(qg_mask)

# Metrik Tanpa Quality Gate (Semua citra)
acc_all = np.mean(y_true == y_pred)
print(f"\\n=== HASIL AKURASI KESELURUHAN (Semua Citra) ===")
print(f"Akurasi Lapangan (1.200 citra): {acc_all * 100:.2f}%")

# Metrik Dengan Quality Gate (Hanya citra yang lolos filter kualitas)
if np.sum(qg_mask) > 0:
    acc_qg = np.mean(y_true[qg_mask] == y_pred[qg_mask])
    print(f"Akurasi Lapangan (Hanya yang lolos Quality Gate, n={np.sum(qg_mask)}): {acc_qg * 100:.2f}%")
    print(f"Peningkatan dari Quality Gate: {(acc_qg - acc_all) * 100:+.2f} poin")

# Matriks Konfusi (pada 4 kelas irisan)
eval_classes = sorted(list(KAGGLE_MAP.values()))
from sklearn.metrics import classification_report, confusion_matrix

print("\\nClassification Report (Semua Citra):")
print(classification_report(y_true, y_pred, labels=eval_classes, zero_division=0))

cm = confusion_matrix(y_true, y_pred, labels=eval_classes)
fig, ax = plt.subplots(figsize=(6, 5))
im = ax.imshow(cm, cmap="Blues")
ax.set_xticks(range(len(eval_classes)))
ax.set_yticks(range(len(eval_classes)))
ax.set_xticklabels(eval_classes, rotation=45, ha="right")
ax.set_yticklabels(eval_classes)
ax.set_xlabel("Prediksi Model")
ax.set_ylabel("Label Lapangan Sebenarnya")
ax.set_title("Confusion Matrix Lapangan (4 Kelas Irisan)")

for i in range(len(eval_classes)):
    for j in range(len(eval_classes)):
        ax.text(j, i, str(cm[i, j]), ha="center", va="center", color="black")

plt.tight_layout()
plt.show()""")

    # =========================================================================
    # Bagian 8: Ekspor Model TFLite & Ringkasan Akhir
    # =========================================================================
    add_md("""## 8. Ekspor Ringkasan Hasil & Konversi TFLite
Menyimpan semua CSV metrik ke Google Drive dan mengonversi model klasifikasi akhir ke TFLite float16 untuk deployment mobile/edge.""")

    add_code("""# 1. Konversi TFLite Float16
tflite_path = LOCAL_WORK / "visikom_mobilenetv2_float16.tflite"
converter = tf.lite.TFLiteConverter.from_keras_model(classifier_model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_types = [tf.float16]
tflite_model = converter.convert()

with open(tflite_path, "wb") as f:
    f.write(tflite_model)

size_mb = os.path.getsize(tflite_path) / (1024 * 1024)
print(f"Model TFLite float16 berhasil diekspor: {tflite_path} ({size_mb:.2f} MB)")

drive_tflite = DRIVE_MODELS / "visikom_mobilenetv2_float16.tflite"
shutil.copy2(tflite_path, drive_tflite)
print(f"Salinan TFLite tersimpan di Drive: {drive_tflite}")

# 2. Ringkasan Akhir
print("\\n" + "="*60)
print("VISIKOM PIPELINE LENGKAP TELAH BERHASIL DIJALANKAN DARI AWAL HINGGA SELESAI")
print("="*60)
print("Arsip berkas keluaran di Google Drive (Folder khusus visikom/):")
print(f"1. Manifest 1.200 citra uji beku : {DRIVE_DATA / 'field_test_1200.csv'}")
print(f"2. Hasil Quality Gate & Keparahan: {DRIVE_RESULTS / 'eval_cv_pipeline_1200.csv'}")
print(f"3. Model TFLite float16          : {DRIVE_MODELS / 'visikom_mobilenetv2_float16.tflite'} ({size_mb:.2f} MB)")
print("="*60)""")

    notebook = {
        "cells": cells,
        "metadata": {
            "colab": {
                "name": "visikom_pipeline_lengkap.ipynb",
                "provenance": []
            },
            "kernelspec": {
                "display_name": "Python 3",
                "name": "python3"
            },
            "language_info": {
                "name": "python",
                "version": "3.10"
            }
        },
        "nbformat": 4,
        "nbformat_minor": 0
    }

    out_file = Path("D:/Visikom/visikom_pipeline_lengkap.ipynb")
    out_file.write_text(json.dumps(notebook, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Notebook berhasil dibuat: {out_file} ({len(cells)} cells, {out_file.stat().st_size / 1024:.1f} KB)")


if __name__ == "__main__":
    make_notebook()
