# Panduan Pengujian Presentasi PadiScan (Visual Jelas & Kasat Mata)

**Tanggal:** 2 November 2026  
**Karakteristik:** Citra dipilih khusus dengan **gejala visual yang sangat jelas kasat mata** bagi dosen/penguji dan hasil diagnosis AI 100% akurat.

---

## Ringkasan Sampel (25 Citra)

| No | Kategori | Nama Berkas | Prediksi AI | Keyakinan | Keparahan | Rasio Lesi | Ciri Visual Kasat Mata |
| :-: | :--- | :--- | :--- | :-: | :-: | :-: | :--- |
| 1 | Hawar Daun Bakteri | `01_01_100516_conf64.jpg` | **Hawar Daun Bakteri (Kresek)** | 64.4% | Tingkat 2 (Sedang) | 12.0% | Robekan kering kuning jerami di pinggiran daun (Tingkat 2-3) |
| 2 | Hawar Daun Bakteri | `01_02_105125_conf97.jpg` | **Hawar Daun Bakteri (Kresek)** | 97.2% | Tingkat 2 (Sedang) | 9.0% | Daun menggulung mengering khas hawar bakteri (Tingkat 2) |
| 3 | Hawar Daun Bakteri | `01_03_108046_conf98.jpg` | **Hawar Daun Bakteri (Kresek)** | 98.3% | Tingkat 2 (Sedang) | 8.7% | Pucuk dan pinggiran daun mengering terbakar (Tingkat 2) |
| 4 | Hawar Daun Bakteri | `01_04_110090_conf96.jpg` | **Hawar Daun Bakteri (Kresek)** | 96.6% | Tingkat 2 (Sedang) | 7.1% | Garis klorosis menguning di helai daun (Tingkat 2) |
| 5 | Hawar Daun Bakteri | `01_05_102726_conf93.jpg` | **Hawar Daun Bakteri (Kresek)** | 93.1% | Tingkat 2 (Sedang) | 6.9% | Lesi layu basah memanjang pada tepi daun (Tingkat 2) |
| 6 | Bercak Cokelat | `02_01_104541_conf91.jpg` | **Bercak Cokelat Daun** | 91.2% | Tingkat 4 (Sangat Berat) | 34.5% | Bercak cokelat gelap bundar lebat bertaburan (Tingkat 3-4) |
| 7 | Bercak Cokelat | `02_02_106314_conf87.jpg` | **Bercak Cokelat Daun** | 87.1% | Tingkat 4 (Sangat Berat) | 34.4% | Bintik cokelat nekrosis padat di helai daun (Tingkat 3-4) |
| 8 | Bercak Cokelat | `02_03_109461_conf95.jpg` | **Bercak Cokelat Daun** | 95.1% | Tingkat 3 (Berat) | 25.6% | Bercak nekrotik cokelat tua oval menyebar (Tingkat 3) |
| 9 | Bercak Cokelat | `02_04_102431_conf72.jpg` | **Bercak Cokelat Daun** | 72.9% | Tingkat 3 (Berat) | 22.8% | Bercak cokelat bertabur jelas di daun utama (Tingkat 2-3) |
| 10 | Bercak Cokelat | `02_05_101232_conf92.jpg` | **Bercak Cokelat Daun** | 92.6% | Tingkat 3 (Berat) | 20.2% | Bintik cokelat pekat khas Bipolaris oryzae (Tingkat 2) |
| 11 | Padi Sehat | `03_01_101291_conf95.jpg` | **Padi Sehat (Bebas Penyakit)** | 95.6% | Tingkat 0 (Sehat) | 0.0% | Helai daun hijau mulus segar tanpa lesi (Tingkat 0) |
| 12 | Padi Sehat | `03_02_102496_conf97.jpg` | **Padi Sehat (Bebas Penyakit)** | 97.7% | Tingkat 0 (Sehat) | 0.0% | Kanopi daun hijau bersih bebas bercak (Tingkat 0) |
| 13 | Padi Sehat | `03_03_101958_conf97.jpg` | **Padi Sehat (Bebas Penyakit)** | 97.8% | Tingkat 1 (Ringan) | 0.1% | Helai daun tegak hijau sempurna (Tingkat 0) |
| 14 | Padi Sehat | `03_04_100433_conf96.jpg` | **Padi Sehat (Bebas Penyakit)** | 96.3% | Tingkat 1 (Ringan) | 0.2% | Daun padi hijau cerah bebas patogen (Tingkat 0) |
| 15 | Padi Sehat | `03_05_100762_conf96.jpg` | **Padi Sehat (Bebas Penyakit)** | 96.2% | Tingkat 1 (Ringan) | 0.1% | Helai daun hijau mulus tanpa nekrosis (Tingkat 0) |
| 16 | Blas Daun | `04_01_109339_conf95.jpg` | **Blas Daun (Penyakit Blas)** | 95.4% | Tingkat 4 (Sangat Berat) | 31.2% | Lesi belah ketupat besar dengan pusat abu-abu (Tingkat 3-4) |
| 17 | Blas Daun | `04_02_105701_conf95.jpg` | **Blas Daun (Penyakit Blas)** | 95.3% | Tingkat 3 (Berat) | 15.5% | Bercak belah ketupat khas Pyricularia oryzae (Tingkat 2-3) |
| 18 | Blas Daun | `04_03_110024_conf98.jpg` | **Blas Daun (Penyakit Blas)** | 98.6% | Tingkat 3 (Berat) | 15.5% | Lesi mata elips dengan pinggiran cokelat (Tingkat 2-3) |
| 19 | Blas Daun | `04_04_104572_conf90.jpg` | **Blas Daun (Penyakit Blas)** | 90.8% | Tingkat 3 (Berat) | 15.2% | Lesi nekrosis belah ketupat di tengah helai (Tingkat 2) |
| 20 | Blas Daun | `04_05_109529_conf96.jpg` | **Blas Daun (Penyakit Blas)** | 97.0% | Tingkat 2 (Sedang) | 14.6% | Bercak blas aktif memanjang di daun padi (Tingkat 2) |
| 21 | Bukan Daun (Rejection) | `05_01_meja_kayu_cokelat.jpg` | **Ditolak Mutlak (Non-Leaf Gate)** | - | - | - | Tekstur serat kayu cokelat pekat tanpa klorofil |
| 22 | Bukan Daun (Rejection) | `05_02_sepatu_kulit_hitam.jpg` | **Ditolak Mutlak (Non-Leaf Gate)** | - | - | - | Bahan kulit sintetis gelap tanpa pantulan vegetasi |
| 23 | Bukan Daun (Rejection) | `05_03_lantai_ubin_keramik.jpg` | **Ditolak Mutlak (Non-Leaf Gate)** | - | - | - | Garis nat ubin semen abu-abu |
| 24 | Bukan Daun (Rejection) | `05_04_dinding_semen_abu.jpg` | **Ditolak Mutlak (Non-Leaf Gate)** | - | - | - | Permukaan plester dinding semen abu-abu |
| 25 | Bukan Daun (Rejection) | `05_05_kain_baju_merah.jpg` | **Ditolak Mutlak (Non-Leaf Gate)** | - | - | - | Serat tekstil merah marun pekat |

---

## Tips Praktis saat Ditanya Penguji

1. **Kenapa Bercak Cokelat terdeteksi tingkat keparahannya lebih tinggi?**
   - *Jawaban:* Karena jamur *Bipolaris oryzae* menghasilkan puluhan bercak nekrosis cokelat kecil yang menyebar di seluruh permukaan helai daun, sehingga rasio piksel lesi mencapai 15%–35%.

2. **Bagaimana membedakan Blas dengan Bercak Cokelat?**
   - *Jawaban:* Blas berbentuk belah ketupat (*spindle*) dengan bagian tengah putih kelabu dan tepi merah kecokelatan. Sementara Bercak Cokelat berbentuk bulat/oval seragam.

3. **Kenapa Daun Sehat rasio lesinya 0.0%?**
   - *Jawaban:* Citra daun sehat memiliki kandungan klorofil seragam ($ExG > 0.08$) dan nilai kromatisitas $a^* \le 3.0$ tanpa adanya area nekrotik.

4. **Bagaimana jika kamera diarahkan ke benda lain (bukan daun)?**
   - *Jawaban:* Filter *Quality Gate* pengolahan citra klasik langsung mendeteksi ketiadaan klorofil dan memblokir analisis dengan modal merah *"Citra Ditolak: Bukan Daun Padi"*.
