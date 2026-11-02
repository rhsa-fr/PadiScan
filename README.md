# PadiScan (Visikom) — Sistem Cerdas Deteksi Penyakit & Tingkat Keparahan Lesi Daun Padi

[![Flutter](https://img.shields.io/badge/Flutter-3.35.2-02569B?logo=flutter)](https://flutter.dev)
[![TensorFlow Lite](https://img.shields.io/badge/TensorFlow_Lite-float16_4.32MB-FF6F00?logo=tensorflow)](https://www.tensorflow.org/lite)
[![Akurasi Lapangan](https://img.shields.io/badge/Akurasi_Lapangan-88.75%25-success)](results/eval_terpadu_1200.csv)
[![Lisensi](https://img.shields.io/badge/Lisensi-MIT-green.svg)](LICENSE)

> **PadiScan** adalah aplikasi visi komputer terpadu dan klasifikasi cerdas *on-device* untuk mendeteksi penyakit daun padi, mengukur rasio luas lesi nekrotik, menentukan skor keparahan (0–4), serta memvalidasi kelayakan citra (*Quality Gate*) secara instan tanpa ketergantungan koneksi internet (*full offline*).

---

## 🌾 Latar Belakang & Pendekatan Arsitektur

Proyek sistem pakar tanaman padi umumnya hanya menerapkan klasifikasi citra utuh (*black-box CNN*) tanpa pengolahan citra (*image processing*). Hal ini membuat informasi morfologi penyakit—seperti bentuk lesi, sebaran bercak, dan persentase kerusakan helai daun—tidak dapat diukur secara kuantitatif.

**PadiScan memecahkan masalah ini dengan Arsitektur Dual-Branch:**

```
                                  [ Input Citra Daun Padi ]
                                              │
                ┌─────────────────────────────┴─────────────────────────────┐
                ▼                                                           ▼
     [ Cabang Visi Komputer Klasik ]                               [ Cabang Klasifikasi CNN ]
     1. Gray-World White Balance                                   1. Konversi Raw RGB Canonical
     2. Excess Green (ExG = 2g - r - b)                            2. Resizing Linear 224x224
     3. Binarisasi Otomatis Otsu                                   3. MobileNetV2 (TFLite float16)
     4. Morfologi Closing (Radius 6)                               4. Softmax Probability (6 Kelas)
     5. Ekstraksi Kontur & Bounding Box                            5. Prediksi Kelas & Keyakinan
     6. Segmentasi Lesi (CIELab a* > 4.0)                                   │
     7. Perhitungan Rasio Luas Lesi                                         │
     8. Skor Keparahan (Tingkat 0 - 4)                                      │
     9. Quality Gate (Blur, Cahaya, Luas)                                   │
                │                                                           │
                └─────────────────────────────┬─────────────────────────────┘
                                              ▼
                             [ Layar Diagnosis PadiScan ]
                  • Kelas Penyakit & Keyakinan (%)
                  • Skor Keparahan 0–4 & Rasio Lesi (%)
                  • Visualisasi Toggle: Foto Asli vs Mask Lesi
                  • Status Quality Gate
                  • Rekomendasi Tindakan Agronomi Lapangan
```

---

## 📊 Hasil Evaluasi & Benchmark

Pengujian model dilakukan pada **1.200 citra uji lapangan beku (*frozen field test set*)** dari dataset *Paddy Doctor* (300 citra/kelas, seimbang). Data uji diverifikasi bebas bocor menggunakan perceptual hash **dHash64** terhadap seluruh data latih.

### Ringkasan Metrik Klasifikasi

| Metrik | Nilai Capaian | Keterangan |
|---|:---:|---|
| **Akurasi Lapangan (Semua 1.200 Citra)** | **88,75%** | **+4,00 poin** di atas baseline model lama (84,75%) |
| **Akurasi Lapangan (Lolos Quality Gate, n=962)** | **87,84%** | Citra dengan fokus tajam & jarak optimal |
| **Tingkat Lolos Quality Gate** | **80,17%** | 238 citra ditolak karena daun terlalu jauh (<6% bingkai) |
| **Ukuran Model Edge (TFLite float16)** | **4,32 MB** | Ringan, hemat RAM, latensi < 45 ms di perangkat mobile |

### Laporan Kinerja per Kelas (*Classification Report*)

| Kelas Penyakit | Presisi | Recall | F1-Score | Jumlah Sampel |
|---|:---:|:---:|:---:|:---:|
| **Leaf Blast (Blas Daun)** | **0,90** | **0,97** | **0,93** | 300 |
| **Brown Spot (Bercak Cokelat)** | **0,91** | **0,91** | **0,91** | 300 |
| **Healthy (Tanaman Sehat)** | **0,79** | **1,00** | **0,88** | 300 |
| **Bacterial Leaf Blight (Hawar/BLB)** | **1,00** | **0,68** | **0,81** | 300 |
| **Rata-rata Makro (Macro Avg)** | **0,90** | **0,89** | **0,88** | 1.200 |
| **Rata-rata Tertimbang (Weighted Avg)** | **0,90** | **0,89** | **0,88** | 1.200 |

*Data lengkap pengujian per citra tercatat di berkas [`results/eval_terpadu_1200.csv`](results/eval_terpadu_1200.csv).*

---

## 📱 Fitur Aplikasi Mobile PadiScan

Aplikasi dibangun dengan framework **Flutter** dan **tflite_flutter** untuk performa *native* penuh:

1. **Pemindai Kamera dengan AI Reticle Animasi:**
   - *Laser scan line* bergerak kontinu memindai permukaan daun.
   - HUD *Quality Gate* real-time: indikator fokus ketajaman, kecerahan, dan jarak daun.
   - Tombol bidik dengan animasi *breathing pulse ring*.
2. **Layar Diagnosis & Keparahan Lesi:**
   - Nama penyakit, taksonomi latin, dan *confidence gauge* beranimasi.
   - *Toggle button*: **[Foto Asli]** vs **[Mask Deteksi Lesi]** (menyorot bercak penyakit berwarna oranye-merah terang).
   - Bar tingkat keparahan 5 segmen (Tingkat 0: Sehat, 1: Ringan $\le 5\%$, 2: Sedang 5–15%, 3: Berat 15–30%, 4: Sangat Berat $> 30\%$).
3. **Rekomendasi Tindakan Agronomi:**
   - Rekomendasi pengendalian kimiawi terarah (fungisida/bakterisida terdaftar).
   - Pengaturan nutrisi (pengurangan Urea, penambahan Kalium KCL).
   - Manajemen tata kelola air berselang (*intermittent irrigation*).
   - Tombol langsung menghubungi Petugas Penyuluh Lapangan (PPL).
4. **Pusat Edukasi & Ensiklopedia:**
   - Katalog digital 6 penyakit daun padi beserta foto makro gejala dan tingkat risiko.
   - Panduan artikel lapangan untuk budidaya tahan penyakit.
5. **Riwayat & Monitoring Lahan:**
   - Ringkasan statistik petak sawah (Total scan, Terinfeksi, Sehat).
   - Penyimpanan riwayat lokal (*offline storage* via `SharedPreferences` + berkas gambar persisten).

---

## 📂 Struktur Repositori

```
D:\Visikom/
├── app/                            # Proyek Flutter Mobile App (PadiScan)
│   ├── assets/models/              # Model TFLite float16 terpasang
│   ├── lib/
│   │   ├── main.dart               # Entry point aplikasi
│   │   ├── models/                 # Model data diagnosis & riwayat
│   │   ├── screens/                # 5 layar antarmuka pengguna
│   │   ├── services/               # Classifier TFLite, CV pipeline, History
│   │   ├── theme/                  # Desain sistem & palet warna
│   │   └── widgets/                # Logo vector, animated reticle, shutter
│   └── test/                       # Unit test CV pipeline & serialisasi data
├── data/
│   └── field_test_1200.csv         # Manifest 1.200 citra uji lapangan beku
├── docs/                           # Dokumentasi teknis lengkap (01 s.d. 08)
├── models/
│   ├── visikom_mobilenetv2_trained.keras   # Model pelatihan Keras
│   └── visikom_mobilenetv2_float16.tflite  # Model inferensi edge (4.32 MB)
├── results/
│   ├── eval_cv_pipeline_1200.csv  # Hasil Quality Gate & lesi klasik
│   └── eval_terpadu_1200.csv      # Hasil evaluasi terpadu 1.200 citra
├── tools/
│   └── generate_notebook.py        # Generator notebook Colab
├── ui_design/                      # Desain referensi HTML & tangkapan layar Stitch
└── visikom_pipeline_lengkap.ipynb  # Notebook pelatihan & evaluasi Google Colab
```

---

## 🚀 Panduan Memulai

### 1. Menjalankan Notebook Pelatihan (Google Colab)
1. Unggah berkas `visikom_pipeline_lengkap.ipynb` ke Google Colab.
2. Pastikan *runtime* menggunakan GPU (T4 GPU).
3. Sambungkan Google Drive, lalu jalankan seluruh sel secara berurutan.
4. Model `.keras`, berkas `.tflite`, dan tabel CSV akan otomatis tersimpan di folder `MyDrive/visikom/`.

### 2. Menjalankan / Membangun Aplikasi Flutter (PadiScan)
Pastikan Flutter SDK (>= 3.30) dan Android SDK sudah terpasang di komputer Anda.

```bash
# Pindah ke direktori aplikasi
cd app

# Unduh seluruh dependensi paket
flutter pub get

# Jalankan pengujian unit
flutter test

# Jalankan aplikasi di perangkat Android yang terhubung
flutter run

# Membangun berkas APK Release untuk instalasi
flutter build apk --release
```

Berkas APK hasil kompilasi akan berada di:
`app/build/app/outputs/flutter-apk/app-release.apk`

---

## 📦 Unduhan APK Rilis

Berkas APK mandiri yang siap diinstal langsung ke perangkat Android petani/penyuluh tanpa perlu setup komputer dapat diunduh pada tab [**Releases**](../../releases):

| Berkas Unduhan | Ukuran | Arsitektur Target | Keterangan |
|---|:---:|:---:|---|
| [**PadiScan-v1.0.0-arm64-v8a.apk**](../../releases/download/v1.0.0/PadiScan-v1.0.0-arm64-v8a.apk) | **29,1 MB** | **ARM64 (v8a)** | **Rekomendasi Utama** untuk 99% HP Android modern (RAM $\ge$ 3GB) |
| [**PadiScan-v1.0.0-armeabi-v7a.apk**](../../releases/download/v1.0.0/PadiScan-v1.0.0-armeabi-v7a.apk) | **24,7 MB** | **ARM 32-bit (v7a)** | Untuk HP Android generasi lama |
| [**PadiScan-v1.0.0-release.apk**](../../releases/download/v1.0.0/PadiScan-v1.0.0-release.apk) | 74,1 MB | Universal (Semua ABI) | Berisi semua arsitektur (arm64, armv7, x86_64) |
| [**visikom_mobilenetv2_float16.tflite**](../../releases/download/v1.0.0/visikom_mobilenetv2_float16.tflite) | 4,32 MB | TFLite Runtime | Model bobot AI float16 untuk deployment edge |

---

## 📝 Sitasi & Rujukan

1. **Paddy Doctor Dataset**: P. Kumar dkk., *Paddy Doctor: A Large-Scale Visual Dataset for Paddy Disease Recognition*, ICCV Workshop 2023.
2. **MobileNetV2**: M. Sandler dkk., *MobileNetV2: Inverted Residuals and Linear Bottlenecks*, CVPR 2018.
3. **Vegetation Index**: D. M. Woebbecke dkk., *Color Indices for Weed Identification Under Various Soil, Residue, and Lighting Conditions*, Trans. ASAE 1995.
