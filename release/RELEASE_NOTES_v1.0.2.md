# Catatan Rilis PadiScan v1.0.2

**Tanggal Rilis:** 2 November 2026  
**Target:** Sentra Padi Indramayu & Petani Indonesia  

---

### Fitur Baru & Peningkatan Utama

1. **Visualisasi Interaktif 4-Tahap Pengolahan Citra Digital (Visi Komputer):**
   - Layar hasil diagnosis (`DiagnosisScreen`) kini dilengkapi tombol alih interaktif 4 tahap pengolahan citra:
     - **Tahap 1 (Foto Asli):** Citra RGB asli langsung dari sensor kamera.
     - **Tahap 2 (Indeks Klorofil ExG):** Citra monokromatik transformasi Excess Green $(2G - R - B)$ untuk mengisolasi spektrum klorofil dan menekan latar tanah/air.
     - **Tahap 3 (Mask Daun):** Segmentasi biner helai daun hasil ambang batas otomatis Otsu dan penutupan morfologi (*morphological closing* $r=6$).
     - **Tahap 4 (Peta Lesi):** Visualisasi sebaran bercak lesi nekrotik cokelat/merah (CIELab $a^* > 4.0$) dan klorosis hawar menguning.
   - Dilengkapi kartu penjelasan algoritma dan rumus matematis per tahap secara transparan.

2. **Validasi & Penolakan Otomatis Citra Bukan Daun (Non-Leaf Gate):**
   - Citra dianalisis spektrum klorofilnya secara kuantitatif ($ExG > 0.05$ minimal 5% luas bidang bidik).
   - Objek non-daun (meja, sepatu, wajah, lantai, ruangan) dicegat secara otomatis dengan modal peringatan *"Bukan Daun Padi Terdeteksi"* dan tombol *"Foto Ulang"*, mencegah halusinasi model CNN.

3. **Decision Fusion (Pencegahan Hawar/Kresek Terabaikan Sehat):**
   - Mengatasi kelemahan MobileNetV2 pada sampel Hawar Daun Bakteri (BLB) lapangan.
   - Aturan arbitrase otomatis membatalkan prediksi "Sehat" jika cabang visi komputer mendeteksi adanya bercak lesi aktif pada daun ($> 1.0\%$).

4. **Nomenklatur Penyakit Bahasa Petani Indonesia:**
   - Seluruh hasil prediksi, statistik riwayat lahan, dan kartu rekomendasi menggunakan istilah baku petani lokal:
     - *Hawar Daun Bakteri (Kresek)*
     - *Bercak Cokelat Daun*
     - *Blas Daun (Penyakit Blas)*
     - *Padi Sehat (Bebas Penyakit)*
     - *Hawar Daun Bergaris (Scald)*
     - *Busuk Pelepah Daun*

5. **Kalibrasi Keyakinan (Temperature Scaling $T=0.65$):**
   - Mengatasi depresi skor keyakinan akibat *label smoothing* 0.15 saat pelatihan, menghasilkan rentang keyakinan realistis (70%–95%) pada kelas penyakit yang dominan.

---

### Berkas Unduhan Rilis

| Nama Berkas | Ukuran | Arsitektur Target | Keterangan |
| :--- | :--- | :--- | :--- |
| `PadiScan-v1.0.2-arm64-v8a.apk` | 29.9 MB | 64-bit ARM (`arm64-v8a`) | Rekomendasi (99% HP Android modern) |
| `PadiScan-v1.0.2-armeabi-v7a.apk` | 25.5 MB | 32-bit ARM (`armeabi-v7a`) | Perangkat Android lama / spek hemat |
| `visikom_mobilenetv2_float16.tflite` | 4.45 MB | On-Device TFLite | Model terpadu float16 |
