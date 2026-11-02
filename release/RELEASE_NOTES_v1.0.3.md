# Catatan Rilis PadiScan v1.0.3

**Tanggal Rilis:** 2 November 2026  
**Fokus:** Perbaikan Overconfidence & Penolakan Mutlak Citra Bukan Daun

---

### Perubahan Utama:

1. **Penghapusan Penajaman Temperatur (Temperature Scaling $T=0.65$):**
   - Menghapus fungsi eksponensial buatan yang sebelumnya memompa probabilitas mendekati 100%.
   - Model kini menampilkan probabilitas **Softmax murni bawaan TFLite** apa adanya tanpa inflasi buatan.

2. **Penolakan Mutlak Citra Bukan Daun (Hard Non-Leaf Gate):**
   - Menghapus celah tombol bypass *"Tetap Analisis"*.
   - Jika citra dideteksi bukan daun padi (klorofil $ExG \le 0$ atau luas vegetasi $< 6\%$), sistem **menolak mutlak** analisis dengan modal informasi tunggal *"Ambil Foto Daun Ulang"*.
   - Mencegah halusinasi model memvonis objek non-daun (meja, sandal, pakaian, wajah) sebagai penyakit tanaman padi.

---

### Berkas Unduhan:

| Berkas | Ukuran | Arsitektur Target |
| :--- | :--- | :--- |
| `PadiScan-v1.0.3-arm64-v8a.apk` | 29.9 MB | 64-bit ARM (`arm64-v8a`) — Mayoritas HP Modern |
| `PadiScan-v1.0.3-armeabi-v7a.apk` | 25.5 MB | 32-bit ARM (`armeabi-v7a`) — HP Model Lama |
