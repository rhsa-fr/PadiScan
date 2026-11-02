# Panduan Pengujian Presentasi PadiScan (100% Unseen Test Set)

**Tanggal:** 2 November 2026  
**Integritas Data:** Semua 20 citra daun diambil murni dari **`field_test_1200.csv`** (himpunan uji beku yang **tidak pernah masuk ke data training** model).

---

## Ringkasan Sampel (25 Citra)

| No | Kategori | Nama Berkas | Prediksi AI | Keyakinan | Keparahan | Rasio Lesi | Ciri Visual Kasat Mata |
| :-: | :--- | :--- | :--- | :-: | :-: | :-: | :--- |
| 1 | Hawar Daun Bakteri | `01_01_100516_conf64.jpg` | **Hawar Daun Bakteri (Kresek)** | 64.4% | Tingkat 2 (Sedang) | 12.0% | Robekan kering kuning jerami di pinggiran daun (Tingkat 2-3) |
| 2 | Hawar Daun Bakteri | `01_02_108046_conf98.jpg` | **Hawar Daun Bakteri (Kresek)** | 98.3% | Tingkat 2 (Sedang) | 8.7% | Pucuk dan pinggiran daun mengering terbakar (Tingkat 2) |
| 3 | Hawar Daun Bakteri | `01_03_101649_conf70.jpg` | **Hawar Daun Bakteri (Kresek)** | 70.4% | Tingkat 2 (Sedang) | 7.0% | Daun menggulung mengering khas hawar bakteri (Tingkat 2) |
| 4 | Hawar Daun Bakteri | `01_04_102726_conf93.jpg` | **Hawar Daun Bakteri (Kresek)** | 93.1% | Tingkat 2 (Sedang) | 6.9% | Lesi layu basah memanjang pada tepi daun (Tingkat 2) |
| 5 | Hawar Daun Bakteri | `01_05_107493_conf99.jpg` | **Hawar Daun Bakteri (Kresek)** | 99.5% | Tingkat 2 (Sedang) | 6.9% | Garis klorosis menguning di helai daun (Tingkat 2) |
| 6 | Bercak Cokelat | `02_01_104541_conf91.jpg` | **Bercak Cokelat Daun** | 91.2% | Tingkat 4 (Sangat Berat) | 34.5% | Bercak cokelat gelap bundar lebat bertaburan (Tingkat 3-4) |
| 7 | Bercak Cokelat | `02_02_102431_conf72.jpg` | **Bercak Cokelat Daun** | 72.9% | Tingkat 3 (Berat) | 22.8% | Bercak cokelat bertabur jelas di daun utama (Tingkat 2-3) |
| 8 | Bercak Cokelat | `02_03_106289_conf89.jpg` | **Bercak Cokelat Daun** | 89.9% | Tingkat 3 (Berat) | 19.9% | Bercak nekrotik cokelat tua oval menyebar (Tingkat 3) |
| 9 | Bercak Cokelat | `02_04_108096_conf92.jpg` | **Bercak Cokelat Daun** | 92.6% | Tingkat 2 (Sedang) | 13.0% | Bintik cokelat pekat khas Bipolaris oryzae (Tingkat 2) |
| 10 | Bercak Cokelat | `02_05_107511_conf85.jpg` | **Bercak Cokelat Daun** | 85.5% | Tingkat 2 (Sedang) | 8.2% | Bintik nekrosis bundar merata di helai daun (Tingkat 2) |
| 11 | Padi Sehat | `03_01_102496_conf97.jpg` | **Padi Sehat (Bebas Penyakit)** | 97.7% | Tingkat 0 (Sehat) | 0.0% | Kanopi daun hijau bersih bebas bercak (Tingkat 0) |
| 12 | Padi Sehat | `03_02_100762_conf96.jpg` | **Padi Sehat (Bebas Penyakit)** | 96.2% | Tingkat 1 (Ringan) | 0.1% | Helai daun hijau mulus tanpa nekrosis (Tingkat 0) |
| 13 | Padi Sehat | `03_03_101414_conf93.jpg` | **Padi Sehat (Bebas Penyakit)** | 93.7% | Tingkat 1 (Ringan) | 0.5% | Helai daun tegak hijau segar (Tingkat 0) |
| 14 | Padi Sehat | `03_04_107161_conf97.jpg` | **Padi Sehat (Bebas Penyakit)** | 97.4% | Tingkat 1 (Ringan) | 1.3% | Daun padi hijau cerah bebas patogen (Tingkat 0) |
| 15 | Padi Sehat | `03_05_108222_conf92.jpg` | **Padi Sehat (Bebas Penyakit)** | 92.3% | Tingkat 1 (Ringan) | 1.7% | Daun hijau mulus vegetasi prima (Tingkat 0) |
| 16 | Blas Daun | `04_01_108418_conf94.jpg` | **Blas Daun (Penyakit Blas)** | 94.0% | Tingkat 2 (Sedang) | 12.2% | Lesi belah ketupat besar dengan pusat abu-abu (Tingkat 2-3) |
| 17 | Blas Daun | `04_02_108867_conf89.jpg` | **Blas Daun (Penyakit Blas)** | 89.3% | Tingkat 2 (Sedang) | 7.4% | Bercak belah ketupat khas Pyricularia oryzae (Tingkat 2) |
| 18 | Blas Daun | `04_03_109751_conf90.jpg` | **Blas Daun (Penyakit Blas)** | 90.6% | Tingkat 2 (Sedang) | 5.5% | Lesi mata elips dengan pinggiran cokelat (Tingkat 2) |
| 19 | Blas Daun | `04_04_102706_conf92.jpg` | **Blas Daun (Penyakit Blas)** | 92.5% | Tingkat 1 (Ringan) | 4.4% | Lesi nekrosis belah ketupat di tengah helai (Tingkat 2) |
| 20 | Blas Daun | `04_05_109724_conf89.jpg` | **Blas Daun (Penyakit Blas)** | 89.5% | Tingkat 1 (Ringan) | 3.2% | Bercak blas aktif memanjang di daun padi (Tingkat 2) |
| 21 | Bukan Daun (Rejection) | `05_01_meja_kayu_cokelat.jpg` | **Ditolak Mutlak (Non-Leaf Gate)** | - | - | - | Tekstur serat kayu cokelat pekat tanpa klorofil |
| 22 | Bukan Daun (Rejection) | `05_02_sepatu_kulit_hitam.jpg` | **Ditolak Mutlak (Non-Leaf Gate)** | - | - | - | Bahan kulit sintetis gelap tanpa pantulan vegetasi |
| 23 | Bukan Daun (Rejection) | `05_03_lantai_ubin_keramik.jpg` | **Ditolak Mutlak (Non-Leaf Gate)** | - | - | - | Garis nat ubin semen abu-abu |
| 24 | Bukan Daun (Rejection) | `05_04_dinding_semen_abu.jpg` | **Ditolak Mutlak (Non-Leaf Gate)** | - | - | - | Permukaan plester dinding semen abu-abu |
| 25 | Bukan Daun (Rejection) | `05_05_kain_baju_merah.jpg` | **Ditolak Mutlak (Non-Leaf Gate)** | - | - | - | Serat tekstil merah marun pekat |

---

## Bukti Bebas Kebocoran Data (Data Leakage Free)

1. **Split Beku Terisolasi:** 1.200 citra uji lapangan dipisahkan di awal menggunakan stratified random sampling (`SEED=42`) dan disimpan di `data/field_test_1200.csv`.
2. **Deduplikasi Hash dHash64:** Saat data training disusun, seluruh kandidat citra latih dicocokkan hash perseptualnya terhadap 1.200 citra uji. Jarak Hamming $\le 6$ dibuang otomatis untuk mencegah duplikasi citra mirip.
3. **Sampel Uji Presentasi:** 20 citra daun ini terverifikasi 100% berada di dalam `data/field_test_1200.csv`.

---

## Tips Praktis saat Ditanya Penguji

1. **Apakah citra uji ini pernah dipakai saat training?**
   - *Jawaban:* **Sama sekali tidak pernah.** Seluruh 20 citra daun berasal dari subset 1.200 citra uji beku terisolasi (`field_test_1200.csv`) yang telah diproteksi deduplikasi hash perceptual dHash64.

2. **Kenapa Bercak Cokelat terdeteksi tingkat keparahannya lebih tinggi?**
   - *Jawaban:* Jamur *Bipolaris oryzae* menghasilkan puluhan bercak nekrosis cokelat kecil yang menyebar di seluruh permukaan helai daun, sehingga rasio piksel lesi mencapai 15%–35%.

3. **Bagaimana membedakan Blas dengan Bercak Cokelat?**
   - *Jawaban:* Blas berbentuk belah ketupat (*spindle*) dengan bagian tengah putih kelabu dan tepi merah kecokelatan. Sementara Bercak Cokelat berbentuk bulat/oval seragam.

4. **Kenapa Daun Sehat rasio lesinya mendekati 0%?**
   - *Jawaban:* Citra daun sehat memiliki kandungan klorofil seragam ($ExG > 0.08$) dan nilai kromatisitas $a^* \le 3.0$ tanpa adanya area nekrotik.

5. **Bagaimana jika kamera diarahkan ke benda lain (bukan daun)?**
   - *Jawaban:* Filter *Quality Gate* pengolahan citra klasik langsung mendeteksi ketiadaan klorofil dan memblokir analisis dengan modal merah *"Citra Ditolak: Bukan Daun Padi"*.
