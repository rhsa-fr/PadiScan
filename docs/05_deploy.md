# 05 — Deployment: TensorFlow Lite dan Aplikasi

## 5.1 Konversi Model

1. Simpan model terbaik sebagai `.keras`.
2. Konversi ke TensorFlow Lite dengan kuantisasi **float16** (bobot 32-bit → 16-bit).
3. Verifikasi **paritas**: jalankan model Keras dan TFLite pada seluruh data uji, bandingkan
   argmax dan selisih probabilitas.
4. Catat ukuran berkas.

**Target:**

| Metrik | Target | Cara ukur |
|---|---|---|
| Ukuran `.tflite` | < 15 MB | ukuran berkas |
| Paritas argmax | 100% identik | perbandingan per gambar |
| Selisih probabilitas maksimum | < 0,01 | selisih absolut |
| Akurasi TFLite vs Keras | sama | evaluasi ulang di TFLite |

Angka acuan proyek sebelumnya: 8,51 MB, paritas 100%, selisih 0,0000.

## 5.2 Spesifikasi Aplikasi

Fitur minimum:

1. **Kamera / galeri** → ambil satu foto.
2. **Quality gate** sebelum inferensi: blur, pencahayaan, rasio daun. Jika gagal, tampilkan
   panduan, jangan memaksa memberi diagnosis.
3. **Hasil klasifikasi**: kelas + keyakinan, dengan pesan "tidak yakin" bila < 0,6.
4. **Skor keparahan** 0–4 beserta rentangnya.
5. **Visualisasi**: overlay mask daun, mask lesi, dan kotak ROI; opsional Grad-CAM.
6. **Luring penuh**: tidak ada permintaan jaringan.

Yang **tidak** dibuat: login, riwayat awan, berbagi ke server, rekomendasi pestisida.

## 5.3 Alur di Perangkat

```
foto (0-255, BGR/RGB)
  → quality gate (OpenCV di perangkat)
  → segmentasi daun + crop ROI
  → letterbox 224×224
  → TFLite (float16)
  → kelas + probabilitas
  → skor keparahan dari rasio luas lesi
  → tampilkan hasil + overlay
```

Catatan teknis:

- Normalisasi `[−1, 1]` ada **di dalam model**, aplikasi cukup mengirim 0–255.
- Ukuran input harus persis 224×224×3 dan tipe `float32`.
- Segmentasi di perangkat memakai parameter yang sama dengan pelatihan; simpan sebagai konstanta
  di satu berkas konfigurasi agar tidak menyimpang.

## 5.4 Pengukuran Latensi

- Ukur 100 inferensi per perangkat, buang 10 pemanasan pertama.
- Laporkan **median** dan **p95**, bukan rata-rata saja.
- Minimal dua perangkat dengan kelas berbeda (mis. menengah dan murah).
- Target: median < 2 detik untuk satu siklus penuh (segmentasi + inferensi + render overlay).

Keluaran: `results/tabel_latensi.csv` (perangkat, versi Android, median, p95, ukuran APK).

## 5.5 Kriteria Selesai Fase Deployment

- [ ] `.tflite` < 15 MB dan paritas 100%.
- [ ] Aplikasi berjalan tanpa jaringan (uji mode pesawat).
- [ ] Quality gate menolak foto buram/gelap/terlalu jauh (diuji dengan 10 foto sengaja buruk).
- [ ] Overlay mask tampil dan sesuai dengan hasil segmentasi.
- [ ] Latensi terukur di ≥ 2 perangkat.
- [ ] Hasil di perangkat sama dengan hasil di Colab untuk 20 gambar uji yang sama.
