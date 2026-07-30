# ACARAKI — Game Design Document (Core)

> **Status:** Draft v1 · IGDX Bootcamp Final Project
> **Genre:** Endless puzzle / shop-management hybrid
> **Engine:** Godot 4.7
> **Platform:** PC (mouse-first), potensi mobile port

---

## 1. Judul & Premis

### Kenapa "Acaraki", bukan "Jamuverse"

**Acaraki** adalah istilah historis asli untuk profesi peracik jamu, tercatat dalam
**Prasasti Madhawapura** era Majapahit — bersama profesi lain seperti *abhasana*
(pembuat pakaian) dan *angawari* (pembuat kuali). Seorang acaraki wajib berdoa,
bermeditasi, dan berpuasa sebelum meracik, karena energi positif dipercaya
memengaruhi khasiat jamu.

Ini jauh lebih kuat daripada "Jamuverse":
- Satu kata judul = satu fakta sejarah yang langsung terpakai
- Pemain langsung punya *identitas peran*, bukan sekadar "penjual jamu"
- Ritual doa/puasa sebelum meracik bisa jadi mekanik nyata (lihat §7 Boon)

> **Judul lengkap:** **ACARAKI — Peracik Jamu Majapahit**

### Premis

Kamu adalah acaraki muda yang baru mewarisi kedai jamu almarhum gurumu di sebuah
kota pelabuhan Majapahit. Warisannya bukan cuma kedai — tapi **Serat Wulandari**,
kitab resep yang halamannya banyak hilang. Setiap hari, orang datang dengan
keluhan. Mereka tidak tahu jamu apa yang mereka butuhkan. **Kamu yang harus tahu.**

---

## 2. Fantasi Pemain

> *"Aku bisa membaca keluhan orang, dan aku tahu tanaman apa yang menyembuhkannya."*

Ini adalah fantasi **kompetensi seorang ahli herbal** — bukan fantasi jadi tukang
masak yang buru-buru. Perbedaan ini penting dan menentukan semua keputusan desain
di bawah.

**Konsekuensi desain:** kalau fantasinya adalah *tahu*, maka pengetahuan pemain
harus terus menerus jadi hal yang menentukan menang/kalah. Bukan cuma di 10 menit
pertama. Ini masalah utama yang dibahas di §4.

---

## 3. Core Loop

```
                    ┌─────────── HARI KE-N ───────────┐
                    │                                  │
   [Pagi]           │   [Siang — timer berjalan]        │        [Malam]
 Pilih Boon    →    │  Customer datang bergantian       │   →   Ringkasan hari
 (pakai duit)       │                                   │        Simpan/upgrade
                    │   ┌──────────────────────────┐   │
                    │   │ 1. Baca keluhan (dialog)  │   │
                    │   │ 2. Deduksi → buka Serat   │   │
                    │   │ 3. Pilih bahan (blocks)   │   │
                    │   │ 4. PUZZLE: isi kuali      │   │  ← core gameplay
                    │   │ 5. REBUS: atur api        │   │  ← core gameplay
                    │   │ 6. Sajikan → dapat duit   │   │
                    │   └──────────────────────────┘   │
                    │        (ulangi sampai timer 0)    │
                    └──────────────────────────────────┘
```

**Durasi target:**
- 1 customer = 45–75 detik
- 1 hari = 5 menit → ~5-7 customer
- 1 run = 7-10 hari → 35–50 menit

---

## 4. Analisis Jujur: Apakah Ini Fun & Edukatif?

Kamu minta penilaian jujur. Ini penilaian saya.

### ✅ Yang sudah kuat

**a. Puzzle-nya punya fondasi terbukti.** Waste Crusher sudah membuktikan
bin-packing dengan bentuk irregular itu memuaskan. Kita tidak berjudi di sini.

**b. Reframing potion itu cerdas, bukan gimmick.** RPG potion = *"benda ini
mengubah statusmu"*. Jamu = *"ramuan ini mengubah kondisi tubuhmu"*. Ini bukan
metafora yang dipaksakan — ini memang konsep yang sama. Pemain non-Indonesia
langsung paham, pemain Indonesia merasa budayanya diperlakukan setara dengan
fantasi Barat. Ini nilai jual utama untuk juri bootcamp.

**c. Ada dua sumber tekanan yang berbeda jenis.** Puzzle (spasial, tenang) dan
rebusan (temporal, panik). Kontras ini bikin ritme.

### ⚠️ Tiga masalah serius yang harus diselesaikan

#### Masalah #1 — Deduksi hanya seru SEKALI. Ini masalah terbesar.

Pemain melihat *"Aku mau berangkat perang"* → jawabannya brotowali. Menarik.
Tapi di hari ke-3, customer yang sama muncul, pemain sudah hafal. Fase deduksi
berubah dari **teka-teki** menjadi **delay**. Dan karena ini game *endless*,
pemain akan mengulang puluhan kali.

Ini fatal: **inti edukatifnya justru bagian yang paling cepat basi.**

**Solusi — Sistem Gejala Majemuk (Compound Symptom).**

Jangan petakan `customer → 1 jamu`. Petakan `customer → beberapa gejala`, dan
setiap **bahan** menangani gejala tertentu. Pemain tidak menghafal resep jadi,
tapi **menyusun** resep dari gejala.

> **Contoh:**
> *"Badanku panas, sendi-sendiku ngilu, dan aku harus tetap berjaga malam ini."*
>
> - `panas/demam` → **Brotowali** (antipiretik)
> - `sendi ngilu` → **Kencur** (anti-inflamasi, pereda nyeri)
> - `harus kuat/stamina` → **Beras Kencur** atau **Jahe Merah**
>
> Pemain menyusun 3 bahan ini ke dalam satu kuali. Kombinasinya bukan resep
> hafalan — ia dirakit dari pemahaman.

Karena gejala dikombinasikan secara prosedural, ruang kemungkinannya besar
(12 bahan × kombinasi 2-4 gejala = ratusan permintaan unik). **Pengetahuan tetap
terpakai di hari ke-30.** Pemain jadi benar-benar *belajar khasiat bahan*, bukan
menghafal 8 nama jamu.

Ini juga lebih setia pada praktik jamu asli: jamu memang diracik sesuai kondisi,
bukan produk kaleng.

#### Masalah #2 — Deduksi dan timer saling bertentangan

Berpikir butuh waktu tenang. Timer menghukum berpikir. Kalau digabung mentah,
pemain akan **berhenti berpikir** dan asal comot — persis membunuh nilai edukatif.

**Solusi — Timer hanya jalan saat MERACIK, tidak saat MEMBACA.**

- Saat dialog customer & membuka Serat (kitab) → **timer melambat 80%**
- Saat puzzle & rebusan → timer normal

Secara naratif: "acaraki yang baik mendengarkan dengan sabar." Secara desain:
kita menghukum kelambatan *eksekusi*, bukan kelambatan *berpikir*. Pemain boleh
merenung; yang dikejar waktu adalah tangannya, bukan otaknya.

#### Masalah #3 — "Kematangan + urutan penempatan" berisiko overload

Ide awal: setiap bahan punya tingkat kematangan, jadi harus ditaruh berurutan.
Digabung dengan puzzle spasial + timer = **tiga beban kognitif bersamaan.**

Kabar baiknya: klarifikasi kamu sudah memperbaiki ini. Kematangan dipindah ke
**fase rebusan yang terpisah** dari fase puzzle. Itu keputusan yang tepat — dua
puzzle berurutan, bukan satu puzzle bertumpuk.

**Rekomendasi:** pertahankan pemisahan itu. Jangan tambahkan constraint urutan
*di dalam* fase puzzle. Kalau ternyata puzzle terasa terlalu mudah, tambahkan
tekanan lewat bentuk kuali & blocker (§5), bukan lewat aturan urutan.

---

## 5. Fase 1 — PUZZLE KUALI (Meracik)

Adaptasi langsung dari Waste Crusher.

### Aturan dasar

| Waste Crusher | ACARAKI |
|---|---|
| Landfill berbentuk irregular | **Kuali** dengan bentuk dalam yang irregular |
| Block dari inventory | **Bahan** yang dipilih dari Serat (kitab) |
| Isi penuh tanpa pelanggaran = menang | Isi penuh **dengan bahan yang benar** = jamu jadi |
| Toxic tak boleh di permukaan | Bahan pahit tak boleh di permukaan (mengendap) |

**Kondisi berhasil:** semua sel kuali terisi **DAN** semua bahan wajib resep sudah
masuk **DAN** tidak ada pelanggaran aturan.

### Kenapa bentuk kuali berubah-ubah (jawaban untuk "blocker blocks")

Tim kamu menyebut "blocker blocks", dan interpretasimu benar: maksudnya **tiap
racikan punya tata letak berbeda** supaya tidak jadi hafalan.

Kita implementasikan dengan dua cara yang saling melengkapi:

**a. Sisa Ampas (Residue)** — sel yang sudah terisi sejak awal dan tidak bisa
dipakai. Ini sisa racikan sebelumnya yang belum dibersihkan.
- Naratif: kuali belum sempat dicuci karena antrean ramai
- Mekanik: mengurangi ruang, memaksa penataan ulang
- **Jumlahnya bertambah seiring hari** → kurva kesulitan alami
- Bisa dibersihkan lewat boon "Bilas Kuali"

**b. Bentuk kuali bervariasi** — kedai punya beberapa kuali dengan bentuk dalam
berbeda (bundar, lonjong, bersudut). Customer dengan pesanan besar butuh kuali
besar.

### Alat (Tools)

| Alat | Fungsi | Status |
|---|---|---|
| **Pipisan & Gandik** | Potong/haluskan bahan jadi 2 bagian | Port dari Cutter — **historis akurat**, ini memang alat asli acaraki |
| **Tumbuk (Lumpang)** | Padatkan bahan: 2×6 → 3×4 → 4×3 | Port dari HydraulicPress |
| **Putar** | Rotasi 90° | Sudah ada |
| **Saring** | Hapus 1 sel Ampas | Alat baru, uses terbatas |

> **Catatan akurasi:** *pipisan* (batu landasan) dan *gandik* (batu penggilas)
> adalah alat asli peracik jamu era Majapahit. Menamai alat dengan nama aslinya
> memberi nilai edukatif gratis tanpa mengubah mekanik sama sekali.

---

## 6. Fase 2 — REBUSAN (Panci & Api)

Ini sistem **baru**, bukan port dari Melter. Ini kontribusi orisinal game kalian.

### Konsep

Jamu yang selesai dari fase puzzle masuk ke **panci**. Panci bisa menampung
**beberapa jamu sekaligus** (default 2, bisa di-upgrade sampai 4).

Setiap jamu punya **jendela kematangan** yang berbeda-beda, dan pemain mengatur
**satu tuas api** yang berlaku untuk seluruh panci.

### Mekanik: Tuas Api

```
   PANAS  ┃█┃  ← geser vertikal
     ▲    ┃█┃
     │    ┃ ┃     Satu tuas, mempengaruhi SEMUA jamu di panci
     │    ┃ ┃
   DINGIN ┃ ┃
```

Setiap jamu punya **zona suhu ideal** yang berbeda:

| Jamu | Zona ideal | Alasan (nyata) |
|---|---|---|
| Kunyit Asam | Sedang | Kurkumin rusak bila terlalu panas |
| Wedang Jahe | Panas | Butuh mendidih untuk mengeluarkan gingerol |
| Beras Kencur | Rendah | Beras bisa gosong |

**Bar kematangan** tiap jamu terisi lebih cepat kalau api berada di zona
idealnya, lambat kalau di luar zona, dan **bar gosong** terisi kalau terlalu panas.

### Kenapa ini fun

Konfliknya jelas dan mudah dibaca: **satu tuas, banyak jamu, kebutuhan berbeda.**
Pemain harus terus-menerus berkompromi — naikkan api untuk jahe, tapi kunyit
mulai rusak. Ini menciptakan keputusan menarik setiap detik tanpa perlu aturan
rumit.

Ini juga **jujur secara edukatif**: suhu memang memengaruhi ekstraksi senyawa
herbal. Pemain belajar sesuatu yang benar sambil bermain.

### Multitasking

Selagi menunggu rebusan, pemain **kembali ke puzzle** untuk meracik pesanan
berikutnya. Inilah sumber ketegangan utama game: mata harus bolak-balik antara
kuali dan panci.

> **Catatan produksi:** ini fitur paling mahal untuk diseimbangkan. Kalau waktu
> mepet, versi minimum yang tetap fun: **1 jamu per panci, tuas api tetap ada.**
> Multi-jamu bisa jadi upgrade yang di-unlock, bukan fitur hari pertama.

---

## 7. Ekonomi & Progresi

### Bayaran

```
Bayaran = HargaDasar × (Akurasi) × (1 + SisaKesabaran) × BonusKematangan
```

| Faktor | Rentang | Keterangan |
|---|---|---|
| **Akurasi** | 0.3 – 1.0 | Berapa banyak gejala yang tertangani. Salah bahan tetap dibayar sedikit — pemain tidak dihukum berat karena belajar |
| **Sisa kesabaran** | 0 – 1.0 | Semakin cepat dilayani, semakin besar |
| **Kematangan** | 0.5 – 1.2 | Pas = bonus, mentah/gosong = penalti |

**Prinsip:** jangan pernah beri 0. Pemain yang salah harus tetap dapat sesuatu +
umpan balik yang mengajari. Kegagalan harus terasa seperti pelajaran, bukan
hukuman.

### Boon (dipilih tiap pagi)

Naratif: **ritual pagi acaraki** — doa, meditasi, puasa sebelum meracik. Ini
langsung dari fakta sejarah, dan menjelaskan kenapa boon dipilih di pagi hari.

Pemain memilih **1 dari 3** boon acak:

| Kategori | Contoh |
|---|---|
| **Kuali** | +1 ukuran kuali · Ampas awal berkurang 2 · Bentuk kuali lebih ramah |
| **Api** | Zona ideal melebar 20% · Gosong lebih lambat · +1 slot panci |
| **Pengetahuan** | Serat menandai bahan yang cocok · Gejala ditampilkan lebih jelas |
| **Pelanggan** | Kesabaran +15% · Bayaran +10% |
| **Alat** | +2 penggunaan pipisan · Saring gratis tiap pesanan |

**Tension desain yang sehat:** boon "Pengetahuan" membuat game lebih mudah tapi
mengurangi tantangan deduksi. Ini pilihan yang bermakna: pemain baru mengambilnya,
pemain mahir melewatinya demi boon yang lebih kuat. Ini juga **difficulty slider
alami** tanpa menu setting.

---

## 8. Struktur Endless

| Hari | Yang berubah |
|---|---|
| 1–2 | Tutorial terselubung. 1 gejala per customer. Panci 1 slot |
| 3–5 | 2 gejala. Ampas mulai muncul. Panci 2 slot |
| 6–9 | 3 gejala. Bahan langka muncul. Customer lebih tidak sabar |
| 10+ | Skala tanpa batas: gejala 3–4, ampas padat, timer lebih ketat |

**Kondisi kalah:** kepuasan pelanggan (reputasi kedai) habis. Melayani dengan
buruk mengurangi reputasi; melayani dengan baik menambahnya.

---

## 9. Yang Membuat Ini Layak Menang di Bootcamp

Juri bootcamp game edukasi budaya biasanya menilai: **apakah budayanya inti atau
tempelan?**

Di game ini budayanya **inti**, dan ini buktinya:

1. **Menghapus jamu = game hancur.** Ganti dengan "ramuan fantasi generik", dan
   sistem gejala majemuk kehilangan basisnya. Ini tes paling penting, dan kita lolos.
2. **Pemain benar-benar belajar.** Setelah 1 jam, pemain tahu kencur untuk nyeri
   sendi, temulawak untuk liver, brotowali untuk demam. Bukan hafalan nama, tapi
   pemahaman fungsi.
3. **Detail historis tersebar di mekanik**, bukan di layar teks: acaraki, pipisan
   & gandik, ritual pagi, Serat sebagai kitab resep.
4. **Bukan game "edukasi" yang membosankan.** Ini game puzzle beneran yang kebetulan
   mengajarkan sesuatu yang nyata.

---

## 10. Risiko & Mitigasi

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Scope terlalu besar untuk waktu bootcamp | **Tinggi** | Prioritas: Puzzle → Rebusan → Ekonomi → Boon. Lihat 05-Production.md |
| Multitasking puzzle+panci bikin frustrasi | Sedang | Mulai 1 slot panci; multi-slot sebagai upgrade |
| Terlalu banyak bahan bikin bingung | Sedang | Rilis 8 bahan inti dulu, 4 sisanya unlock bertahap |
| Deduksi terasa seperti tebak-tebakan | **Tinggi** | Serat harus bisa dicari berdasarkan **gejala**, bukan cuma nama jamu |
| Klaim kesehatan bisa menyesatkan | Sedang | Sertakan disclaimer; gunakan bahasa "dipercaya secara tradisional" |

---

## Dokumen Terkait

- `02-Ingredients.md` — database bahan & khasiat nyata
- `03-Customers.md` — karakter & motivasinya
- `04-Architecture.md` — rencana teknis & reuse dari Waste Crusher
- `05-Production.md` — prioritas & jadwal
