# 03 — Data, Pembagian, dan Protokol Pelabelan

## 3.1 Sumber Data

| Peran | Dataset | Jumlah | Catatan |
|---|---|---|---|
| Latih/validasi/uji internal | PadiCheck (Rice Disease Dataset + Rice Leaf Disease Images) | 3.758 citra unik | sudah dideduplikasi pHash |
| Uji eksternal | Paddy Doctor | 13.876 citra (10.407 berlabel, 10 kelas; 1.200 dipakai) | foto lapangan Kaggle, 4 kelas beririsan |

Komposisi PadiCheck setelah deduplikasi: 2.632 latih / 564 validasi / 562 uji, enam kelas.

Empat kelas Paddy Doctor yang beririsan dengan taksonomi proyek: Bacterial Leaf Blight,
Brown Spot, Healthy, Leaf Blast. Setiap kelas diambil 300 gambar → **1.200 citra uji beku**.

## 3.2 Aturan Pembagian Data

1. Pembagian memakai **Stratified Group K-Fold** dengan kelompok dari *perceptual hash*.
   Gambar yang mirip tidak boleh terpisah ke subset berbeda.
2. Rasio 70:15:15.
3. Data uji internal **dikunci** (`data/LOCKED.txt`) dan baru dibuka sekali di tahap evaluasi.
4. 1.200 citra lapangan **dibekukan lebih dulu** dan tidak boleh dipakai untuk apa pun selain
   evaluasi Fase 5.
5. Setiap penambahan data baru wajib melewati pemeriksaan duplikat terhadap data latih
   (pHash64, Hamming ≤ 6).

Kegagalan menjaga aturan ini membuat seluruh angka tidak sah — pada proyek sebelumnya, tanpa
deduplikasi 94% data latih akan berupa salinan hampir identik.

## 3.3 Data Validasi Manual untuk Segmentasi

Segmentasi tidak bisa dinilai tanpa *ground truth* mask. Karena pelabelan piksel penuh mahal,
dipakai 60 citra berstrata:

| Kelompok | Jumlah | Kriteria pemilihan |
|---|---|---|
| Daun jelas | 20 | satu daun besar, latar sederhana, kontras cukup |
| Latar ramai | 20 | banyak daun lain, bayangan, atau tanah |
| Foto lapangan | 20 | dari Paddy Doctor, resolusi asli, kondisi apa adanya |

**Cara melabeli:** alat bantu semi-otomatis (`tools/label_mask.py`) menjalankan pipeline lalu
menyimpan hasilnya; pelabel kemudian **memperbaiki** mask dengan kuas (tambah/hapus), bukan
menggambar dari nol. Target waktu: 3–5 menit per citra.

**Keluaran:** `data/eval_manual/<id>.png` (mask biner) + `data/eval_manual/index.csv`
(berisi id, kelompok, catatan kesulitan).

**Aturan:** citra validasi manual **tidak boleh** ikut data latih; ambil dari subset uji internal
dan uji lapangan.

## 3.4 Protokol Label Keparahan

Skor keparahan 0–4 didefinisikan operasional, supaya dua penilai menghasilkan angka yang mirip:

| Skor | Definisi (persentase luas lesi terhadap luas daun) |
|---|---|
| 0 | tidak ada lesi terlihat |
| 1 | < 5% |
| 2 | 5–15% |
| 3 | 15–30% |
| 4 | > 30% |

**Prosedur:**

1. Dua penilai menilai 60 citra yang sama, **tanpa** melihat hasil algoritma.
2. Penilai melihat citra pada ukuran tampilan tetap (misal 800 px) dan boleh memperbesar.
3. Hitung **Cohen's kappa**.
   - kappa ≥ 0,6 → label dipakai, ambil rata-rata dibulatkan.
   - kappa < 0,6 → sederhanakan menjadi 3 tingkat (ringan / sedang / berat) dan laporkan
     alasannya.
4. Simpan ke `data/severity_labels.csv`: `id, rater1, rater2, final, catatan`.

## 3.5 Berkas yang Harus Ada di `data/`

```
data/
├─ split_manifest.csv        # path, kelas, subset, group_id
├─ LOCKED.txt                # daftar id uji internal yang dikunci
├─ field_test_1200.csv       # daftar 1.200 citra lapangan (beku)
├─ eval_manual/index.csv     # 60 citra untuk validasi mask
├─ eval_manual/*.png         # mask manual
├─ severity_labels.csv       # skor 0-4 dari dua penilai
└─ README.md                 # cara mendapatkan ulang tiap berkas
```

Berkas citra **tidak** disimpan di repositori; hanya manifest dan daftar. Lokasi citra ditulis
di `data/README.md` (mis. folder Drive).

## 3.6 Pemeriksaan Wajib Sebelum Melatih

- [ ] Tidak ada irisan id antara train / val / test.
- [ ] Tidak ada duplikat pHash (Hamming ≤ 6) antar subset.
- [ ] 1.200 citra lapangan tidak muncul di manifest latih.
- [ ] 60 citra validasi manual tidak muncul di manifest latih.
- [ ] Jumlah per kelas pada tiap subset tercatat dan dilaporkan.
