# Data Registry — Visikom

Berkas citra asli **tidak disimpan di git**, melainkan di Google Drive: `MyDrive/padicheck/data_raw/`.

## Berkas Dataset Mentah di Google Drive

| Berkas | Ukuran | Sumber | Isi |
|---|---|---|---|
| `main_rice_leaf_aug.zip` | 1.015 MB | PadiCheck | 3.829 citra, 6 kelas (nama ber-spasi), sudah diaugmentasi |
| `extra_rice_leaf_disease.zip` | 196 MB | PadiCheck | 5.932 citra, 4 kelas (tanpa spasi di nama folder) |
| `paddy_doctor.zip` | 1.043,5 MB | Kaggle (`imbikramsaha/paddy-doctor`) | 13.876 citra (10.407 `train_images`, 3.469 `test_images`), 10 kelas berlabel |
| `manifest_paddy_doctor.json` | 1,3 KB | Hasil verifikasi unduhan | Metadata, SHA-256, breakdown kelas |

### SHA-256 Verifikasi
- `paddy_doctor.zip`: `876d323f37decef1a27e4b3f6fd2402d3c0781eefa9135b67e153d0b9af72509`

## Empat Kelas Irisan untuk Uji Eksternal (Paddy Doctor)
Dari 10 kelas berlabel di `train.csv` Paddy Doctor, 4 kelas beririsan dengan taksonomi Visikom:
1. `bacterial_leaf_blight` -> Bacterial Leaf Blight: 479 citra (kuota 300 terpenuhi)
2. `brown_spot` -> Brown Spot: 965 citra (kuota 300 terpenuhi)
3. `normal` -> Healthy: 1.764 citra (kuota 300 terpenuhi)
4. `blast` -> Leaf Blast: 1.738 citra (kuota 300 terpenuhi)

Total 1.200 citra uji lapangan diambil 300 per kelas menggunakan stratified sampling (SEED 42) dan dibekukan.
