# 02 — Pipeline Pengolahan Citra

Semua tahap di bawah ini adalah pengolahan citra klasik (OpenCV), tanpa deep learning. CNN baru
masuk setelah tahap 7.

```
foto asli
 1. white balance (gray-world)
 2. indeks vegetasi ExG = 2G − R − B
 3. Otsu pada ExG  →  mask kotor
 4. morfologi: opening lalu closing
 5. kontur terbesar  →  bounding box ROI (+margin)
 6. Lab kanal a*  →  kandidat lesi
 7. filter bentuk & luas lesi
 8. crop ROI → letterbox 224×224
 9. quality gate (blur, cahaya, rasio daun)
10. CNN → kelas penyakit + skor keparahan
```

## 2.1 White Balance (Gray-World)

**Masalah:** kamera berbeda menghasilkan cast warna berbeda; foto pagi kebiru-biruan, foto siang
kekuningan. Ambang warna apa pun menjadi tidak stabil antar perangkat.

**Metode:** asumsikan rata-rata kanal seharusnya sama (gray-world).

```
mean = (mean(R) + mean(G) + mean(B)) / 3
R' = R * mean / mean(R),  sama untuk G dan B
```

**Parameter:** tidak ada. **Biaya:** satu pass piksel, sangat murah.
**Catatan:** alternatifnya *white patch* (Max-RGB); pilih salah satu dan laporkan pengaruhnya ke
IoU (lihat `docs/04_eksperimen.md`).

## 2.2 Indeks Vegetasi ExG

**Masalah:** latar sawah juga hijau, sehingga ambang hijau biasa (HSV) tidak memisahkan daun dari
rumpun di belakangnya. Pada uji proyek sebelumnya, ambang HSV hanya mencapai skor 0,26–0,43.

**Metode:** *Excess Green* — menonjolkan kerapatan klorofil, bukan kecerahan.

```
r = R/(R+G+B), g = G/(R+G+B), b = B/(R+G+B)
ExG = 2g − r − b            (rentang −1..1, diskalakan ke 0..255)
```

Varian yang boleh diuji bila hasil kurang: `ExGR = ExG − 1.4·ExR`, dengan `ExR = 1.4r − g`.

**Parameter:** tidak ada selain pilihan normalisasi. **Biaya:** murah.

## 2.3 Otsu pada ExG

**Metode:** `cv2.threshold(exg, 0, 255, THRESH_BINARY + THRESH_OTSU)`.
Otsu memilih ambang yang memaksimalkan ragam antar-kelas, sehingga tidak perlu ambang manual per
foto.

**Parameter:** tidak ada. **Kegagalan yang mungkin:** foto dengan dua bidang besar (daun + tanah
kering) dapat membuat Otsu memilih ambang yang salah → ditangani oleh validasi kualitas tahap 9.

## 2.4 Operasi Morfologi

| Operasi | Kernel | Iterasi | Tujuan |
|---|---|---|---|
| opening | ellipse 5×5 | 2 | membuang bintik kecil (derau, tetesan air) |
| closing | ellipse 7×7 | 3 | menutup lubang di dalam daun (bayangan, lesi gelap) |

**Catatan:** nilai ini titik awal, bukan harga mati. Tuning 12–16 kombinasi dan simpan hasilnya
ke `results/tabel_tuning_leaf.csv` (kernel 3/5/7/9 × iterasi 1/2/3).

## 2.5 Kontur dan ROI

1. `findContours(RETR_EXTERNAL, CHAIN_APPROX_SIMPLE)`.
2. Ambil kontur dengan luas terbesar.
3. `boundingRect` → `(x, y, w, h)`.
4. Tambahkan margin 8% tiap sisi, lalu clamp ke ukuran gambar.
5. Tolak ROI jika lebar atau tinggi < 24 piksel (dianggap gagal).

**Keluaran:** kotak ROI + mask daun (dipakai untuk penekanan latar).

## 2.6 Deteksi Lesi di Ruang Lab

**Masalah:** lesi tidak berwarna hijau, tetapi bisa cokelat, kuning, atau abu-abu. Ambang Hue di
HSV tidak menangkap rentang itu dengan rapi.

**Metode:** ruang CIELab. Pada OpenCV, nilai netral `a* = 128`; daun sehat (hijau) berada di
`a* < 128`, lesi cokelat/kuning berada di `a* > 128`.

1. Konversi BGR → Lab.
2. Ambang awal `a* > 132`.
3. Batasi pada area mask daun (lesi hanya dihitung di dalam daun).
4. Buang komponen dengan luas < 0,2% luas daun atau `solidity < 0,3` (bentuk berbenang dianggap
   bayangan/urat daun).

**Parameter yang di-tuning:** ambang `a*` (128–140), luas minimum, solidity. Simpan ke
`results/tabel_tuning_lesion.csv`.

**Fitur yang dihitung per citra (tahap 7):**

| Fitur | Kegunaan |
|---|---|
| `lesion_area_ratio` | rasio luas lesi / luas daun → dasar skor keparahan |
| `blob_count` | jumlah bercak terpisah |
| `mean_a_star` | intensitas kecokelatan rata-rata di dalam lesi |
| `lesion_entropy` | keberagaman tekstur di dalam lesi |
| `leaf_area_ratio` | luas daun / luas bingkai → deteksi "terlalu jauh" |

## 2.7 Crop dan Letterbox

- Crop memakai kotak ROI dari tahap 2.5.
- Resize **letterbox**: skala seragam (`INTER_AREA` untuk pengecilan) lalu padding simetris ke
  224×224. Jangan stretch, jangan center-crop — keduanya terbukti merusak pada proyek sebelumnya.
- Normalisasi ke `[−1, 1]` dilakukan **di dalam model** (`Rescaling(1/127.5, −1)`), supaya
  aplikasi cukup mengirim piksel 0–255.

## 2.8 Quality Gate

Dihitung dari citra asli, sebelum crop.

| Pemeriksaan | Ambang | Pesan ke pengguna |
|---|---|---|
| Ketajaman (varians Laplacian) | < 60 | "Foto buram, tahan kamera lebih stabil" |
| Kecerahan rata-rata | < 40 atau > 225 | "Pencahayaan terlalu gelap/terang" |
| Rasio luas daun | < 6% bingkai | "Terlalu jauh, dekatkan kamera ke daun" |
| Keyakinan model | < 0,6 | "Tidak yakin, coba foto ulang" |

Ambang ini berasal dari pengalaman proyek sebelumnya (61,2% prediksi salah tetap punya
keyakinan ≥ 0,6, sehingga ambang keyakinan saja tidak cukup). Nilai final ditetapkan setelah
pengukuran di Fase 5.

## 2.9 Yang Tidak Dipakai dan Alasannya

| Teknik | Alasan ditinggalkan |
|---|---|
| CLAHE global | menaikkan kontras latar juga; terukur menurunkan akurasi 1,06–1,77 poin |
| Penumpukan tepi Canny | menghapus tekstur permukaan daun; turun 3,55 poin |
| Unsharp mask / penajaman | memperkuat derau dan tekstur latar |
| Ambang HSV hijau | gagal memisahkan daun dari rumpun (skor 0,26–0,43) |
| Jitter hue/saturasi | menghapus sinyal pembeda utama (cokelat vs kekuningan) |
| Degradasi sintetis sebagai pengganti data lapangan | turun ke 14,33% pada uji lapangan |

## 2.10 Urutan Implementasi

`src/preprocess.py` (2.1–2.3, 2.7, 2.8) → `src/leaf_segment.py` (2.4–2.5) →
`src/lesion_detect.py` (2.6) → `src/features.py` (fitur) → dipakai oleh `src/train.py`.

Setiap modul wajib punya fungsi tunggal yang menerima `np.ndarray` BGR dan mengembalikan hasil
plus metadata (mask, kotak, status kualitas), agar bisa diuji per fungsi.
