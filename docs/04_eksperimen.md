# 04 — Desain Eksperimen

## 4.1 Prinsip

Semua konfigurasi memakai **data latih, pembagian, seed, dan hiperparameter yang identik**.
Yang berubah hanya perlakuan pengolahan citra. Tanpa ini, perbedaan akurasi tidak bisa
diatribusikan.

## 4.2 Eksperimen 1 — Segmentasi Daun (Fase 2)

**Pertanyaan:** seberapa baik ExG + Otsu + morfologi memisahkan daun dari latar?

**Perlakuan yang dibandingkan (grid tuning):**

| Faktor | Nilai yang diuji |
|---|---|
| metode ambang | Otsu pada ExG, Otsu pada ExGR, Otsu pada HSV-S (pembanding negatif) |
| kernel opening | 3, 5, 7 |
| iterasi closing | 1, 2, 3 |
| margin ROI | 0%, 5%, 8%, 12% |

Batas maksimum 24 kombinasi agar waktu tuning terkendali.

**Metrik:** IoU dan Dice terhadap 60 mask manual, dilaporkan **per kelompok** (daun jelas / latar
ramai / lapangan), bukan hanya rata-rata keseluruhan.

**Kriteria selesai:**
- IoU median ≥ 0,80 untuk daun jelas.
- IoU median ≥ 0,55 untuk foto lapangan.
- Bila tidak tercapai: tulis analisis kegagalan (contoh wajib disertakan) dan lanjut dengan
  konfigurasi terbaik yang ada.

**Keluaran:** `results/tabel_tuning_leaf.csv`, `results/iou_per_kelompok.csv`,
`docs/gambar/kegagalan_segmentasi.png`.

## 4.3 Eksperimen 2 — Deteksi Lesi (Fase 3)

**Pertanyaan:** apakah ambang Lab a\* cukup untuk menemukan lesi, dan seberapa sering ia salah?

**Grid tuning:** ambang `a*` (128–140, langkah 2), luas minimum (0,1% / 0,2% / 0,5% luas daun),
solidity minimum (0,2 / 0,3 / 0,5).

**Metrik:**
- IoU mask lesi terhadap penandaan manual (hanya pada citra berlesi).
- **Uji negatif:** pada citra kelas Healthy, berapa persen luas daun yang salah ditandai lesi.
  Target: < 30%.

**Kriteria selesai:** keduanya terukur dan dilaporkan. Target IoU realistis ≥ 0,35; jika lebih
rendah, tetap dilaporkan dan keparahan disajikan sebagai rentang, bukan angka tunggal.

**Keluaran:** `results/tabel_tuning_lesion.csv`, `results/uji_negatif_healthy.csv`.

## 4.4 Eksperimen 3 — Ablasi Klasifikasi (Fase 4)

Tiga konfigurasi, masing-masing 3 seed (42, 7, 2024):

| Kode | Masukan model | Perlakuan pengolahan citra |
|---|---|---|
| **A** | 224×224×3 | letterbox saja (baseline, setara model lama) |
| **B** | 224×224×3 | crop ROI daun + letterbox |
| **C** | 224×224×3 | crop ROI + latar di luar mask daun diganti warna netral (128,128,128) |

Alasan C tetap 3 kanal: bobot *pretrained* pada konvulsi pertama tetap bisa dipakai. Varian
4 kanal (mask lesi sebagai kanal tambahan) hanya dikerjakan bila waktu tersisa, dan dilaporkan
terpisah sebagai perluasan.

**Model:** MobileNetV2 (ImageNet, `include_top=False`), GAP → Dropout 0,4 → Dense(6 softmax),
`Rescaling(1/127.5, −1)`, label smoothing 0,15, Adam, dua tahap (15 epoch LR 1e-3 dengan backbone
beku, lalu 30 epoch LR 1e-4 dengan 30 lapisan terakhir dibuka).

**Augmentasi (sama untuk A/B/C):** flip horizontal, kecerahan ±18, kontras 0,85–1,20,
zoom-out 0,80–1,00. **Tanpa** jitter hue/saturasi.

**Metrik:** akurasi validasi, akurasi uji internal, akurasi uji lapangan, F1 macro, metrik per
kelas, confusion matrix. Laporkan rata-rata ± simpangan baku antar-seed.

**Kriteria selesai:** selisih B−A dan C−A dinyatakan **bermakna atau tidak** (bukan hanya
angkanya), dengan mempertimbangkan simpangan baku antar-seed.

**Estimasi waktu komputasi:** ±15–20 menit per run pada T4 → 9 run ≈ 3 jam.

**Keluaran:** `results/hasil_ablasi.csv`, `results/per_kelas_ablasi.csv`.

## 4.5 Eksperimen 4 — Evaluasi Lapangan dan Keparahan (Fase 5)

1. Evaluasi A, B, C (model seed terbaik) pada 1.200 citra lapangan beku, dengan quality gate
   aktif dan nonaktif (dua angka, laporkan keduanya).
2. Skor keparahan dari `lesion_area_ratio` → bandingkan dengan `severity_labels.csv`.
3. Metrik: MAE, korelasi Spearman, dan confusion 5 tingkat.

**Kriteria selesai:** MAE ≤ 1 tingkat, dan bila tidak tercapai, analisis penyebab dilaporkan.

**Keluaran:** `results/eval_final.csv`, `results/korelasi_keparahan.csv`.

## 4.6 Metrik dan Cara Menghitungnya

| Metrik | Rumus | Dipakai untuk |
|---|---|---|
| IoU | luas irisan / luas gabungan | kualitas mask |
| Dice | 2·irisan / (luas A + luas B) | pelengkap IoU |
| Akurasi | benar / total | gambaran umum |
| F1 macro | rata-rata F1 tiap kelas | performa seimbang antar kelas |
| MAE | rata-rata \|prediksi − label\| | keparahan |
| Cohen's kappa | kesepakatan terkoreksi peluang | keandalan label manual |

## 4.7 Aturan Pelaporan Hasil

1. Setiap angka di laporan harus berasal dari `results/*.csv`; sebutkan nama berkasnya di
   keterangan tabel.
2. Hasil negatif tetap dilaporkan (contoh dari proyek lama: CLAHE dan Canny menurunkan akurasi).
3. Jangan memilih seed terbaik lalu melaporkannya sebagai hasil tunggal tanpa menyebut
   rata-rata antar-seed.
4. Perbedaan di bawah simpangan baku antar-seed tidak boleh disebut "lebih baik".
