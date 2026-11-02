# 01 — Konsep dan Ruang Lingkup

## 1.1 Latar Belakang

Penyakit daun merupakan salah satu penyebab utama kehilangan hasil padi. Diagnosis di lapangan
masih bergantung pada pengalaman pengamat, sehingga hasilnya lambat dan tidak konsisten antar
pengamat. Model klasifikasi berbasis CNN sudah banyak dilaporkan mencapai akurasi tinggi pada
dataset terkontrol, tetapi angka itu tidak otomatis berlaku pada foto yang diambil petani.

Pengalaman proyek sebelumnya menunjukkan dua hal penting:

1. Model yang dilatih pada citra laboratorium (lesi memenuhi bingkai) **runtuh** ketika diuji
   pada foto lapangan: akurasi turun dari 93,06% menjadi 25,58%.
2. Pengolahan citra fotometrik (CLAHE, blur, penumpukan tepi Canny) justru **menurunkan**
   akurasi 6,38 poin pada dataset yang sama.

Penyebab utamanya bukan warna atau kontras, melainkan **skala dan komposisi bingkai**: pada data
latih lesi memenuhi gambar, sedangkan pada foto lapangan daun hanya menempati sebagian kecil
bingkai dengan latar sawah mendominasi. Bukti tambahan: akurasi model terbaik turun dari 84,75%
(daun 100% bingkai) menjadi 73,17% (70%), 42,83% (50%), dan 32,92% (25%).

Karena itu proyek ini menempatkan pengolahan citra **geometris** — bukan fotometrik — sebagai
inti: menemukan daun, memotongnya, dan mengukur lesinya.

## 1.2 Rumusan Masalah

1. Seberapa baik segmentasi klasik berbasis indeks vegetasi (ExG) dan morfologi memisahkan daun
   padi dari latar sawah, dan pada kondisi apa segmentasi itu gagal?
2. Apakah memotong citra ke area daun (ROI) dan menekan latar menaikkan akurasi klasifikasi
   dibanding CNN pada citra penuh?
3. Apakah rasio luas lesi yang dihitung otomatis sejalan dengan penilaian keparahan oleh
   pengamat manusia?

## 1.3 Tujuan

1. Membangun pipeline pengolahan citra yang dapat dijelaskan tahap demi tahap dan diukur
   kinerjanya (IoU), bukan hanya dipakai tanpa bukti.
2. Mengukur dampak informasi ROI dan mask terhadap akurasi klasifikasi melalui ablasi terkontrol.
3. Menghasilkan aplikasi luring yang menampilkan kelas penyakit, skor keparahan, dan visualisasi
   mask sebagai dasar kepercayaan pengguna.

## 1.4 Ruang Lingkup

**Termasuk:**

- Enam kelas: Bacterial Leaf Blight, Brown Spot, Healthy, Leaf Blast, Leaf Scald, Sheath Blight.
- Satu daun utama per foto.
- Segmentasi dan pengukuran lesi dengan pengolahan citra klasik (tanpa deep learning).
- Klasifikasi dengan CNN ringan (MobileNetV2), diekspor ke TensorFlow Lite.
- Aplikasi Android yang berjalan luring.

**Tidak termasuk:**

- Deteksi banyak daun dalam satu bingkai.
- Segmentasi lesi dengan deep learning (U-Net dan sejenisnya).
- Penentuan dosis, jenis pestisida, atau rekomendasi pengendalian.
- Backend server, basis data, atau akun pengguna.
- Diagnosis di luar enam kelas tersebut.

## 1.5 Kontribusi yang Diharapkan

1. **Pipeline pengolahan citra yang terukur**: setiap tahap punya parameter, alasan pemilihan,
   dan angka IoU, bukan sekadar "supaya gambar lebih jelas".
2. **Bukti kuantitatif** apakah ROI dan penekanan latar membantu klasifikasi pada dataset dengan
   latar rumpun — pertanyaan yang jarang dijawab dengan ablasi terkontrol.
3. **Skor keparahan yang dapat dipertanggungjawabkan**: didefinisikan operasional (persentase
   luas lesi terhadap luas daun) dan diuji kesepakatannya dengan penilaian manusia.

## 1.6 Batasan yang Diakui Sejak Awal

- Dataset publik, bukan pengambilan foto mandiri; variasi kamera dan lokasi terbatas.
- Label keparahan bersifat subjektif, sehingga dilaporkan sebagai rentang bila kesepakatan antar
  penilai rendah.
- Uji generalisasi ke lokasi baru di Indonesia belum tercakup.
