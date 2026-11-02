# PadiScan v1.0.0 — Rilis Perdana Sistem Cerdas Deteksi Penyakit Daun Padi

## 🌟 Sorotan Utama Rilis

**PadiScan v1.0.0** adalah aplikasi visi komputer lapangan *on-device* (luring penuh) untuk diagnosis penyakit tanaman padi dan penilaian tingkat keparahan lesi nekrotik.

- **Akurasi Lapangan Uji Beku:** **88,75%** pada 1.200 citra lapangan nyata (Paddy Doctor).
- **Model Edge Ringan:** MobileNetV2 terkuantisasi float16 berukuran **4,32 MB** dengan latensi inferensi < 45 ms.
- **Arsitektur Dual-Branch:**
  - **Cabang CV Klasik:** Excess Green (ExG), Binarisasi Otomatis Otsu, Morfologi Closing, segmentasi lesi ruang warna CIELab $a^* > 4.0$, dan penilaian tingkat keparahan (0–4).
  - **Cabang CNN MobileNetV2:** Prediksi 6 kelas penyakit daun padi dengan tensor RGB canonical $224\times224$.
- **Quality Gate Real-time:** Menapis citra buram (Laplacian variance < 60), pencahayaan ekstrem (< 40 atau > 225), dan jarak objek terlalu jauh (< 6% luas frame).

---

## 📱 Fitur Aplikasi (5 Layar Utama)

1. **Pemindai Kamera & AI Reticle Animasi:**
   - Garis laser pemindai hijau bergerak kontinu (*laser radar scan line*).
   - HUD Quality Gate real-time: status Fokus, Cahaya, dan Jarak daun.
   - Tombol bidik kamera dengan animasi *breathing pulse ring*.
2. **Diagnosis & Tingkat Keparahan:**
   - Nama penyakit, taksonomi latin, dan *confidence gauge* beranimasi.
   - Toggle visualisasi: **[Foto Asli]** vs **[Mask Deteksi Lesi]** (menyorot bercak penyakit).
   - Indikator bar keparahan 5 segmen (Tingkat 0: Sehat, 1: Ringan, 2: Sedang, 3: Berat, 4: Sangat Berat).
3. **Rekomendasi Tindakan Agronomi:**
   - Rekomendasi pengendalian kimiawi spesifik (bahan aktif & dosis fungisida/bakterisida).
   - Rekomendasi kultur teknis (pengurangan Urea, penambahan Kalium KCL).
   - Manajemen pengairan berselang (*intermittent irrigation*).
   - Tombol cepat menghubungi Penyuluh Lapangan (PPL).
4. **Pusat Edukasi & Ensiklopedia:**
   - Katalog 6 penyakit daun padi beserta foto makro gejala dan tingkat risiko.
   - Panduan artikel lapangan untuk budidaya tahan penyakit.
5. **Riwayat & Monitoring Lahan:**
   - Ringkasan statistik petak sawah (Total scan, Terinfeksi, Sehat).
   - Penyimpanan lokal luring (*offline storage* tanpa internet).

---

## 📊 Kinerja per Kelas pada 1.200 Citra Uji Lapangan

| Kelas Penyakit | Presisi | Recall | F1-Score | Sampel |
|---|:---:|:---:|:---:|:---:|
| **Leaf Blast (Blas Daun)** | 0,90 | 0,97 | 0,93 | 300 |
| **Brown Spot (Bercak Cokelat)** | 0,91 | 0,91 | 0,91 | 300 |
| **Healthy (Tanaman Sehat)** | 0,79 | 1,00 | 0,88 | 300 |
| **Bacterial Leaf Blight (Hawar/BLB)** | 1,00 | 0,68 | 0,81 | 300 |
| **Rata-rata Makro** | **0,90** | **0,89** | **0,88** | 1.200 |

---

## 📥 Berkas Aset Instalasi

| Berkas | Ukuran | Arsitektur Target | Keterangan |
|---|---|---|---|
| `PadiScan-v1.0.0-release.apk` | ~25–35 MB | Android 6.0+ (ARM64 / ARMv7) | APK mandiri siap pasang di HP Android |
| `visikom_mobilenetv2_float16.tflite` | 4,32 MB | TFLite Runtime | Model bobot AI float16 untuk deployment edge |
| `eval_terpadu_1200.csv` | 148 KB | CSV | Data ground truth evaluasi 1.200 citra |

---

## 📲 Panduan Instalasi APK di HP Android

1. Unduh berkas `PadiScan-v1.0.0-release.apk`.
2. Buka berkas APK di file manager ponsel Android Anda.
3. Jika muncul peringatan *"Install from unknown sources"*, pilih **Izinkan (Allow)**.
4. Buka aplikasi **PadiScan**, berikan izin kamera, dan aplikasi siap digunakan di tengah sawah tanpa koneksi internet.
