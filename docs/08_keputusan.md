# 08 — Keputusan yang Harus Diambil

Empat hal di bawah ini menentukan bentuk proyek. Jangan mulai Fase 1 sebelum dijawab, karena
jawabannya mengubah jumlah pekerjaan.

## K1 — Apakah modul keparahan (0–4) dikerjakan?

| | Ikut | Tidak ikut |
|---|---|---|
| Pekerjaan tambahan | pelabelan 60 citra × 2 penilai, kappa, evaluasi MAE | tidak ada |
| Kekuatan laporan | ada kontribusi baru, beda dari proyek klasifikasi biasa | lebih cepat, tapi mirip proyek lama |
| Risiko | label subjektif; bila kappa rendah harus turun ke 3 tingkat | laporan terasa tipis |

**Rekomendasi:** ikut, karena ini yang membedakan proyek ini dari proyek sebelumnya.

## K2 — Dataset

| Opsi | Kelebihan | Kekurangan |
|---|---|---|
| PadiCheck + Paddy Doctor (seperti rencana) | data lapangan sudah ada dan sudah dibekukan; hasil bisa dibandingkan dengan proyek lama | hanya 6 kelas, foto lapangan hanya 4 kelas |
| Paddy Doctor penuh (13 kelas) | lebih kaya, lebih publikabel | 9 kelas tanpa padanan di PadiCheck; segmentasi lesi beda-beda karakter |

**Rekomendasi:** tetap PadiCheck + Paddy Doctor.

## K3 — Aplikasi

| Opsi | Kelebihan | Kekurangan |
|---|---|---|
| Lanjutkan app lama | cepat, TFLite sudah terbukti | harus menambah overlay mask & skor keparahan |
| App minimal baru | bersih, sesuai kebutuhan | makan 4–6 hari |

**Rekomendasi:** lanjutkan app lama, tambahkan layar hasil baru.

## K4 — Tenggat

Menentukan pemadatan jadwal:

| Sisa waktu | Yang dipadatkan |
|---|---|
| ≥ 6 minggu | jalankan semua fase seperti di `06_jadwal_risiko.md` |
| 4–5 minggu | Fase 2–3 dipadatkan jadi 8 hari total; tuning dikurangi jadi 12 kombinasi |
| ≤ 3 minggu | lewati modul keparahan; fokus segmentasi + ablasi A/B + deployment |

---

## Format Keputusan

Setelah dijawab, pindahkan ke tabel di bawah agar jadi catatan resmi proyek.

| Kode | Keputusan | Tanggal | Alasan |
|---|---|---|---|
| K1 | | | |
| K2 | | | |
| K3 | | | |
| K4 | | | |

## Keputusan Teknis yang Sudah Tetap (tidak perlu dibahas ulang)

| Hal | Keputusan | Dasar |
|---|---|---|
| Metode segmentasi | ExG + Otsu + morfologi | ambang HSV gagal pada latar hijau (skor 0,26–0,43) |
| Ruang warna untuk lesi | CIELab kanal a\* | lesi tidak hijau; a\* memisahkan cokelat dari hijau |
| Penskalaan citra | letterbox | stretch dan center-crop menurunkan akurasi |
| Augmentasi warna | hanya kecerahan & kontras | jitter hue/saturasi menghapus sinyal label |
| Arsitektur | MobileNetV2 + TFLite float16 | 8,51 MB, paritas 100% pada proyek sebelumnya |
