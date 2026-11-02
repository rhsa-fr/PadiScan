# 07 — Rujukan

Dua kategori: (a) rujukan metodologis yang akan dipakai di laporan, (b) aset dari proyek
sebelumnya yang dipakai ulang.

## 7.1 Rujukan Metodologis

**Status: perlu verifikasi DOI sebelum masuk daftar pustaka.** Judul dan tahun di bawah ini
adalah rujukan klasik yang relevan; metadata (volume, halaman, DOI) wajib dicek ke penerbit,
bukan disalin dari situs agregator.

| Topik | Rujukan | Dipakai di |
|---|---|---|
| Otsu thresholding | Otsu, N. (1979). "A Threshold Selection Method from Gray-Level Histograms." *IEEE Trans. Systems, Man, and Cybernetics*. | `02_pipeline.md` §2.3 |
| Indeks vegetasi ExG | Woebbecke, D. M., Meyer, G. E., Von Bargen, K., & Mortensen, D. A. (1995). "Color Indices for Weed Identification Under Various Soil, Residue, and Lighting Conditions." *Transactions of the ASAE*. | `02_pipeline.md` §2.2 |
| Verifikasi indeks warna | Meyer, G. E., & Camargo Neto, J. (2008). "Verification of color vegetation indices for automated crop imaging applications." *Computers and Electronics in Agriculture*. | `02_pipeline.md` §2.2 |
| Ruang warna CIELab | Literatur pengolahan citra (buku teks), mis. Gonzalez & Woods, *Digital Image Processing*. | `02_pipeline.md` §2.6 |
| Morfologi & kontur | Buku teks pengolahan citra yang sama | `02_pipeline.md` §2.4–2.5 |
| MobileNetV2 | Sandler dkk. (2018), CVPR — DOI `10.1109/CVPR.2018.00474` (sudah terverifikasi) | `04_eksperimen.md` §4.4 |
| Kuantisasi TFLite | Jacob dkk. (2018), CVPR — DOI `10.1109/CVPR.2018.00286` (sudah terverifikasi) | `05_deploy.md` §5.1 |
| Label smoothing | Müller dkk. (2019) — DOI `10.48550/arXiv.1906.02629` (sudah terverifikasi) | `04_eksperimen.md` §4.4 |
| Keparahan penyakit daun (skala) | Cari publikasi fitopatologi yang memakai skala 0–4 atau persentase luas lesi; **belum ada**, wajib dicari sebelum label keparahan dipakai | `03_data.md` §3.4 |

**Catatan:** definisi skor keparahan pada `03_data.md` §3.4 saat ini dibuat sendiri. Secara
akademik lebih kuat bila merujuk skala baku (mis. skala IRRI atau skala keparahan penyakit
tanaman yang sudah dipublikasikan). Cari rujukannya sebelum Fase 1 selesai.

## 7.2 Aset dari Proyek Sebelumnya

| Aset | Lokasi | Boleh dipakai ulang? |
|---|---|---|
| Split berbasis pHash | proyek lama (`docs/split_manifest.csv`) | **ya**, dengan pemeriksaan ulang jumlah dan irisan |
| Daftar 1.200 citra lapangan beku | proyek lama (`padicheck_runs/fase8_external/`) | **ya**, justru harus sama agar hasil bisa dibandingkan |
| Model MobileNetV2 terlatih | `padicheck_v7.tflite` (8,51 MB) | ya, sebagai titik awal konfigurasi A |
| Skrip augmentasi skala | `train_field.py` (`_zoom_out_pad`, `field_degrade`) | ya, tanpa jitter warna |
| Parameter yang sudah ditolak | CLAHE, Canny, blur, jitter warna | tidak dipakai, tapi **tetap dirujuk** sebagai alasan di laporan |

## 7.3 Yang Tidak Boleh Dirujuk

- Blog pertanian, situs penjual jasa skripsi, Wikipedia, keluaran model bahasa.
- Angka yang tidak punya berkas sumber.
- Rujukan yang belum pernah dibuka isinya (boleh disebut judulnya, tapi jangan dikutip
  kalimatnya).

## 7.4 Aturan Sitasi di Laporan

1. Nomor dalam kurung siku `[1]`, gaya IEEE.
2. Setiap klaim angka milik orang lain wajib bertanda sitasi.
3. Bila memakai tautan, gunakan tautan yang membuka sumber di halaman yang tepat. Untuk sumber
   HTML, tautan dapat menyorot kalimat tertentu (`#:~:text=`); untuk jurnal berbayar, tandai
   "halaman saja".
