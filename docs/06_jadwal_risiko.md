# 06 — Jadwal, Gerbang Keputusan, dan Risiko

## 6.1 Fase Kerja

| Fase | Isi | Estimasi | Keluaran kunci |
|---|---|---|---|
| 1 | Fondasi data: manifest, split, 60 citra validasi manual, label keparahan | 3–4 hari | `data/*`, `split_manifest.csv` |
| 2 | Segmentasi daun (ExG + Otsu + morfologi) + tuning | 5–7 hari | `leaf_segment.py`, `tabel_tuning_leaf.csv` |
| 3 | Deteksi lesi (Lab a\*) + uji negatif | 6–8 hari | `lesion_detect.py`, `tabel_tuning_lesion.csv` |
| 4 | Ablasi klasifikasi A/B/C, 3 seed | 7–10 hari | `hasil_ablasi.csv` |
| 5 | Evaluasi lapangan + keparahan | 5–7 hari | `eval_final.csv`, `korelasi_keparahan.csv` |
| 6 | TFLite + aplikasi + latensi | 4–6 hari | `.tflite`, APK, `tabel_latensi.csv` |
| 7 | Laporan | 5–7 hari (paralel sejak Fase 4) | dokumen BAB I–V |

Total ± 5–6 minggu bila berjalan lancar. Fase 1–3 adalah bagian yang tidak bisa dipotong karena
menjadi inti "pengolahan citra" proyek ini.

## 6.2 Gerbang Keputusan

Setiap gerbang harus diputuskan sebelum lanjut. Jangan menunda keputusan sampai akhir.

| Gerbang | Setelah | Pertanyaan | Jika "tidak" |
|---|---|---|---|
| G1 | Fase 1 | Apakah 60 mask manual dan label keparahan selesai dengan kappa ≥ 0,6? | Sederhanakan keparahan jadi 3 tingkat |
| G2 | Fase 2 | Apakah IoU daun mencapai target? | Analisis kegagalan, pilih konfigurasi terbaik, lanjut |
| G3 | Fase 3 | Apakah mask lesi punya nilai (uji negatif < 30%)? | Lepaskan modul keparahan, fokus ROI + klasifikasi |
| G4 | Fase 4 | Apakah B atau C lebih baik dari A? | Tetap laporkan; itu temuan, bukan kegagalan |
| G5 | Fase 5 | Apakah MAE keparahan ≤ 1 tingkat? | Sajikan keparahan sebagai 3 tingkat + rentang |

## 6.3 Risiko

| Risiko | Kemungkinan | Dampak | Mitigasi |
|---|---|---|---|
| Mask lesi berisik di foto lapangan | tinggi | IoU rendah, keparahan tidak akurat | laporkan IoU per kondisi; keparahan sebagai rentang |
| Label keparahan subjektif | sedang | klaim tidak sahih | dua penilai + kappa; turun ke 3 tingkat bila perlu |
| Segmentasi gagal saat latar padat | sedang | crop salah, akurasi turun | quality gate menolak, atau fallback ke seluruh bingkai |
| Waktu habis di Fase 3 | sedang | proyek tidak selesai | batas waktu keras 8 hari, lalu lanjut dengan a\* sederhana |
| Colab terputus | tinggi | pekerjaan hilang | checkpoint tiap epoch ke Drive, skrip idempoten, hash berkas dicatat |
| Dataset hanya 6 kelas | pasti | sulit dipublikasikan | sebutkan sebagai batasan; fokus pada metodologi |
| Overfit pada data latih kecil | sedang | akurasi lapangan jatuh | augmentasi skala + data lapangan, bukan augmentasi warna |

## 6.4 Aturan Waktu

1. Setiap fase punya **batas waktu keras**. Lewat batas → lanjut dengan hasil terbaik yang ada
   dan catat apa yang belum selesai.
2. Laporan ditulis **selama** pengerjaan (Fase 4 ke atas), bukan setelah semua selesai.
3. Setiap akhir fase: perbarui `README.md` (status) dan tulis log singkat berisi apa yang
   dikerjakan, angka terbaru, dan hambatan.

## 6.5 Definisi "Selesai" Proyek

- Pipeline segmentasi + deteksi lesi berjalan dan terukur (IoU dilaporkan).
- Ablasi A/B/C selesai dengan 3 seed dan hasil dilaporkan apa adanya.
- Model TFLite + aplikasi berjalan luring, latensi terukur.
- Laporan memuat semua angka dari `results/`, tabel dan gambar bernomor, dan batasan ditulis
  jujur.
