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
- Ritual doa/puasa sebelum meracik bisa jadi mekanik nyata (lihat §8 Boon)

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

Game terbagi jadi **dua ruangan** yang dihubungkan tombol `TAB`. Waktu dan
kesabaran pelanggan **jalan terus di keduanya** — itu sumber tekanannya.

```
        ┌──────── KASIR ────────┐        ┌──────── DAPUR ────────┐
        │                        │  TAB   │                        │
        │  1. Baca keluhan       │ ◄────► │  3. Pilih bahan        │
        │  2. Klik pelanggan     │        │  4. PUZZLE: isi kuali  │
        │     (jadi pesanan      │        │  5. Pakai alat (1/2/3) │
        │      aktif)            │        │  6. SPASI → jadi jamu  │
        │                        │        │  7. REBUS: atur api    │
        │  8. Serahkan jamu ─────┼────────┤     (jamu jadi otomatis│
        │     (bisa salah orang!)│        │      masuk ke tangan)  │
        └────────────────────────┘        └────────────────────────┘
                     ▲                                 │
                     └──── bawa maks 3 jamu ───────────┘
```

**Kenapa dua ruangan:** satu layar untuk semuanya bikin sempit — keluhan
panjang, bar takaran, kuali, panci, dan alat tidak muat bersamaan. Dipisah,
tiap ruangan punya ruang bernapas. Dan karena waktu tetap jalan, memilih
*kapan* berhenti meracik untuk cek antrean jadi keputusan nyata.

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

**Solusi lama (dibatalkan):** timer melambat 80% saat membaca.

**Solusi sekarang — bar takaran menggantikan beban ingatan.**

> ⚠️ **Keputusan ini membalik solusi lama, dan itu disengaja.** Sejak game
> dipecah jadi dua ruangan, waktu **jalan penuh di keduanya** — termasuk saat
> membaca di Kasir. Kalau waktu melambat di Kasir, ruangan itu jadi tempat
> aman untuk mengulur, dan tekanan yang jadi alasan pemisahan ruangan justru
> hilang.

Beban kognitifnya tetap turun, tapi lewat jalur berbeda:

| Beban lama | Sekarang |
|---|---|
| Ingat gejala apa saja yang diminta | **Kartu pesanan aktif** ikut ke dapur |
| Ingat sudah masuk bahan apa | **Bar takaran** terisi real-time |
| Hitung apakah sudah cukup | Bar menulis `3/5` langsung |

Jadi pemain tidak dihukum karena berpikir lambat — dia **tidak perlu menyimpan
apa pun di kepala**. Yang dikejar waktu tetap tangannya, bukan otaknya; caranya
saja yang berubah dari "perlambat jam" jadi "hilangkan kebutuhan mengingat".

**Risiko yang tersisa:** pemain baru bisa kewalahan di hari 1 karena tidak ada
lagi jeda aman. Mitigasinya ada di kurva takaran (§5.1) — hari 1–2 semua dosis
= 1, jadi pesanan awal sangat sederhana. Ini perlu diuji playtest; kalau ternyata
terlalu keras, opsi termurah adalah memperpanjang durasi hari 1–2, **bukan**
mengembalikan perlambatan waktu.

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
| Isi penuh tanpa pelanggaran = menang | **Takaran terpenuhi** = jamu manjur |
| Toxic tak boleh di permukaan | Bahan pahit menurunkan bayaran (perlu gula jawa) |

**Kuali TIDAK harus penuh.** Pemain menekan `SPASI` kapan saja untuk mengubah
isi kuali jadi jamu. Yang dinilai adalah **apa yang ada di dalamnya**, bukan
seberapa penuh. Sel kosong tidak dihukum sama sekali.

> **Kenapa puzzle tetap bergigi kalau tidak wajib penuh?** Karena takaran
> (§5.1) diukur dalam **sel**. Memenuhi takaran otomatis berarti mengisi
> banyak sel. Pemain menata rapi karena butuh ruang untuk takarannya, bukan
> karena dipaksa aturan. Tekanannya datang dari kebutuhan, bukan dari denda.

### 5.0 Mengambil pesanan — langkah yang wajib terlihat

Pelanggan datang sendiri ke antrean, tapi **dapur tidak bekerja sampai pemain
menekan `AMBIL PESANAN`** di kartu pelanggan.

```
KASIR                                DAPUR (sebelum ambil)
┌────────────────────────────┐       ┌────────────────────────┐
│ [ikon] Jayeng              │       │  "Belum ambil pesanan."│
│ "Badanku panas semalam..." │       │                        │
│ DEMAM ▪▪▪▪  KULIT ▪▪       │       │  (kuali kosong,        │
│                            │       │   SPASI menolak)       │
│ [   AMBIL PESANAN   ]  ←   │       └────────────────────────┘
└────────────────────────────┘
```

**Kenapa harus eksplisit.** Versi sebelumnya memakai `active_index` yang
default-nya `0`, jadi dapur selalu punya pesanan bahkan kalau pemain tak pernah
memilih siapa pun. Akibatnya "mengambil pesanan" **tidak punya efek yang
terlihat** — pemain tidak bisa membedakan sudah memilih atau belum, dan
langkahnya jadi tak kasatmata.

Sekarang pesanan aktif dilacak **berdasarkan identitas order**, bukan indeks.
Null artinya benar-benar belum ada. Kuali kosong dan `SPASI` menolak dengan
pesan yang menyebutkan langkahnya. Aturannya: **kalau sebuah langkah wajib,
melewatkannya harus terasa.**

### 5.1 Takaran (Potency) — berapa banyak, bukan cuma apa

Aturannya satu kalimat, dan ditulis di layar setiap saat:

> **1 petak bahan = 1 takaran.**

Kunyit berbentuk 2×2 = 4 petak → memberi **4 takaran**. Beras 1×1 → **1
takaran**. Rak Serat menulis angka ini langsung di tiap bahan (`+4`, `+1`), jadi
pemain tidak perlu menghitung petak sendiri.

```
Ki Wanata: "Mataku menguning kata istriku. Badanku lemas terus."

  Butuh berapa petak bahan yang cocok:
  HATI      ████░  4/5     ← temulawak (2×3 = 6 petak) → cukup
  LEMAH     ███    3/3 cukup  ← jahe merah (4 petak) → cukup
```

**Catatan kejelasan (dari playtest internal):** versi pertama sistem ini
membingungkan bahkan bagi yang merancangnya. Penyebabnya bukan konsepnya, tapi
**angkanya tidak pernah dijelaskan asalnya** — bar melompat 4 saat kunyit masuk
tanpa ada apa pun di layar yang bilang kenapa. Tiga hal memperbaikinya:

1. Rak menulis `+4` di tiap bahan, jadi nilainya diketahui **sebelum** diambil
2. Kartu pesanan menulis aturannya: *"Butuh berapa petak bahan yang cocok"*
3. Nama gejala ditulis sebagai teks di rak, bukan cuma kotak warna — jadi
   mencocokkan bahan ke keluhan adalah **membaca**, bukan mengingat kode warna

**Kenapa takaran, bukan "butuh 3 beras":**

| | Jumlah eksplisit | **Takaran (dipakai)** |
|---|---|---|
| Cara baca | Hafal daftar | Baca bar di layar |
| Ukuran bahan | Nyaris tak berarti | **Menentukan** — beras 1 sel vs temulawak 6 sel |
| Hubungan ke puzzle | Terpisah | **Menyatu** — potensi = luas |
| Risiko | Menghidupkan hafalan resep | Tetap butuh tahu bahannya |

Keparahan ditulis **sesuai kata-katanya**: *"melilit parah"* minta lebih
banyak daripada *"perutku tak nyaman"*. Pemain yang membaca teliti bisa
menebak takaran sebelum bar mengonfirmasi.

**Kurva pengenalan:** hari 1–2 semua takaran dipaksa jadi 1 (persis seperti
"satu bahan cukup"), hari 3–4 maksimal 2, hari 5+ takaran penuh. Pemain
belajar sistemnya tanpa tutorial.

### 5.2 Ampas (jawaban untuk "blocker blocks")

Tim menyebut "blocker blocks" — kotak X yang menghalangi kuali. Kita namai
**Ampas**: sisa racikan sebelumnya yang belum sempat dicuci.

**Kenapa Ampas, bukan sekadar "kotak gelap":** satu nama ini menjawab tiga
pertanyaan sekaligus tanpa perlu penjelasan tambahan.

| Pertanyaan | Jawaban |
|---|---|
| Kenapa ada? | Kuali belum dicuci — antrean ramai |
| Kenapa makin banyak tiap hari? | Makin ramai, makin tak sempat cuci |
| Bisa dihilangkan? | Tidak dalam satu sesi — ampas adalah kendala yang harus disiasati, bukan dibeli keluar (lihat §5.3) |

Efek sampingnya bagus: ampas terasa seperti **hutang**. Pemain yang buru-buru
menumpuk masalah untuk hari berikutnya.

**Jaminan solvabilitas** — ini permintaan spesifik dari tim, dan dijamin oleh
kode, bukan oleh harapan. Lihat §5.4.

### 5.3 Pipisan — mesin potong (port persis dari Waste Crusher)

| Alat | Jatah/hari | Fungsi | Cara pakai |
|---|---|---|---|
| **Pipisan** | 3 | Belah bahan di kolom yang kamu pilih | **Seret bahan ke mesinnya** |
| **Putar** | ∞ | Rotasi 90° | `R` / klik-kanan |

**Mekanik intinya bukan "membelah", tapi "membidik".** Mata pisau **diam di satu
titik**. Yang bergerak adalah bahannya. Menggeser bahan ke kiri/kanan di bawah
pisau menentukan **di kolom mana** potongan jatuh, dan garis pratinjau hijau
menunjukkan persis di mana pisau akan turun sebelum kamu melepas.

```
        │  ← mata pisau (diam)
   ▓▓▓▓▓│▓▓▓        geser bahan → potongan bergeser
        │
   hasil: 5 sel + 3 sel

        │
   ▓▓│▓▓▓▓▓▓        geser lagi → pembagian berbeda
        │
   hasil: 2 sel + 6 sel
```

Ini yang membuat memotong jadi **keputusan**, bukan tombol. Butuh takaran 3?
Belah bahan 4-sel di kolom 3, pakai potongan besarnya, sisanya untuk order lain.

**Aturan sumbu:** pisau jatuh vertikal, jadi hanya **lebar** (kolom) yang bisa
dibelah. Bahan setinggi 1×4 harus **diputar dulu** dengan `R`. Ini persis aturan
Waste Crusher, dan menambah satu lapis keputusan gratis.

**Potongan tetap di mesin.** Setelah dibelah, dua potongnya duduk di kiri-kanan
pisau sampai kamu mengambilnya. Mesin **terkunci** selama masih ada potongan di
atasnya — jadi kamu harus membereskan hasil sebelum memotong lagi. Tidak ada
yang otomatis masuk kuali; alat tetap jadi *langkah dalam puzzle*, bukan tombol
perbaiki-otomatis.

**Kenapa jatahnya dibatasi:** alat tak terbatas berarti pemain memotong tiap
kali ragu, dan puzzle-nya hilang. Dibatasi, tiap penggunaan jadi pertanyaan —
*"apakah ini benar-benar situasi tersulit hari ini?"* Jatah **per hari**, bukan
per pesanan, supaya pemain menabung lintas pelanggan.

> **Saring dan Tumbuk dihapus** atas permintaan tim. Efeknya justru menajamkan
> desain: sekarang cuma ada **satu** alat, jadi tidak ada kebingungan alat mana
> untuk situasi apa. Ampas pun jadi kendala nyata yang harus disiasati lewat
> penataan, bukan sesuatu yang bisa dibeli keluar.
>
> Konsekuensi yang perlu dipantau: dulu Tumbuk adalah jalan keluar kalau bentuk
> bahan tidak muat. Sekarang jalan keluarnya cuma **putar** dan **belah**. Kalau
> playtest menunjukkan pemain sering mentok, kandidat termurah adalah menambah
> jatah pipisan — bukan mengembalikan Tumbuk.

> **Aturan penting:** Pipisan **tidak mengubah jumlah sel**. Membelah kunyit
> 2×2 di tengah menghasilkan dua potong 2 sel — jadi potensinya ikut terbelah.
> Kalau tidak begitu, alat jadi cara menggandakan khasiat gratis.

### 5.4 Jaminan: selalu ada minimal 1 solusi

Algoritmanya **generate-and-verify**, bukan generate-and-hope:

```
1. Hitung kebutuhan takaran pesanan     → _shapes_needed_for()
2. Pilih kuali yang MUAT untuk itu      → KualiShape.shape_for()
3. Hitung budget ampas (sisakan slack)  → residue_budget()
4. Taruh ampas tersebar                 → _pick_scattered()
5. BUKTIKAN masih bisa diisi            → _is_solvable()   ← kuncinya
6. Gagal? ulangi dari 4 (12×)
7. Tetap gagal? kirim papan BERSIH tanpa ampas
```

**Langkah 5** menjalankan **backtracking exact-cover solver**: mencoba
menempatkan tiap bahan wajib di **4 rotasi × semua posisi anchor**, rekursif.
Bukan heuristik — ini bukti konstruktif. Grid ~20 sel, jadi biayanya milidetik.

**Langkah 2 penting dan sempat jadi bug nyata.** Awalnya kuali dipilih acak,
dan tes menemukan 17 kasus di mana pesanan berat (butuh 13–16 sel) mendarat di
kuali `kecil` (12 sel) — mustahil sebelum ampas ikut bermain. Sekarang kuali
dipilih **berdasarkan kebutuhan pesanan**, dengan slack minimal 3 sel.

**Verifikasi:** `sim_test.gd` menyapu seluruh kombinasi customer × varian ×
hari × 8 undian kuali = **1.488 papan**, dan memastikan tiap papan punya
packing yang benar-benar ada. Hasil saat ini: **0 papan bermasalah**.

**Prinsipnya:** lebih baik terlalu mudah daripada mustahil. Puzzle yang tak
bisa diselesaikan menghancurkan kepercayaan pemain seketika, dan itu tidak
bisa diperbaiki dengan permintaan maaf.

> **Catatan jujur soal batas jaminan:** yang dijamin adalah **ada satu solusi**,
> bukan bahwa semua pilihan pemain akan muat. Kalau pemain memilih bahan yang
> jauh lebih besar dari perlunya, dia bisa kehabisan ruang. Karena itu ada
> tombol `C` untuk mengosongkan kuali — pemain selalu punya jalan keluar.
> Menjamin *semua* kombinasi akan memaksa ampas jadi nol, dan itu membunuh
> fitur ini.

> **Catatan akurasi:** *pipisan* (batu landasan) dan *gandik* (batu penggilas)
> adalah alat asli peracik jamu era Majapahit. Menamai alat dengan nama aslinya
> memberi nilai edukatif gratis tanpa mengubah mekanik sama sekali.

---

## 6. Fase 2 — BOTOL JAMU (Mengantar)

`SPASI` mengubah isi kuali jadi **botol jamu** yang langsung masuk panci.
Setelah matang, botol otomatis pindah ke **tangan pemain** (maks 3 botol).
Pemain lalu `TAB` ke Kasir dan menyeret botol ke **pelanggan mana pun**.

### Kenapa kapasitas bawa dibatasi 3

Kalau pemain bisa membawa sepuluh botol, dia akan meracik satu batch besar lalu
menyetor semuanya sekaligus — dan ritme bolak-balik antar ruangan hilang. Tiga
botol memaksa perjalanan, dan perjalanan itulah yang menciptakan ritme shift.

### Kenapa ini penting

Kalau jamu otomatis kembali ke pemesannya, pengetahuan pemain cuma diuji **sekali**
(saat memilih bahan). Dengan botol yang dibawa tangan, pengetahuan diuji **dua
kali** — dan yang kedua di bawah tekanan waktu, saat antrean penuh dan beberapa
botol menunggu sekaligus.

**Aturan kuncinya:** jamu dinilai berdasarkan **siapa yang menerima**, bukan siapa
yang memesan.

```
Botol diracik untuk Raka (Pencernaan)
  → diberikan ke Raka           = 100%  "Racikan Tepat"
  → diberikan ke Empu Gandring  =   0%  "Tidak Membantu"  + reputasi -1
     (Batuk tidak tertangani)
```

Botol menampilkan **strip gejala** yang ditanganinya dan nama pemesannya, jadi
salah kasih adalah **kelalaian**, bukan jebakan. Pemain punya semua informasi.

### Konsekuensi menarik yang muncul sendiri

- **Botol bisa "diselamatkan".** Jamu yang salah racik untuk A mungkin **kebetulan
  cocok** untuk B di antrean. Pemain yang jeli bisa menyelamatkan kesalahannya.
- **Antrean jadi teka-teki penugasan.** Dengan 3 botol dan 3 pelanggan, pemain
  harus memutuskan botol mana ke siapa — kadang jawaban terbaik bukan yang paling
  jelas.
- **Panik terasa nyata.** Kesabaran menipis, dua botol siap, dan pemain sempat
  ragu botol mana milik siapa. Ini ketegangan yang tidak ada di versi otomatis.

---

## 7. Fase 3 — REBUSAN (Panci & Api)

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

## 8. Ekonomi & Progresi

### Bayaran

```
Bayaran = HargaDasar × Akurasi × (1 + SisaKesabaran) × Kelezatan × BonusKematangan
```

| Faktor | Rentang | Keterangan |
|---|---|---|
| **Akurasi** | 0.3 – 1.0 | **Ditimbang takaran**, bukan hitung gejala. Setengah dosis = setengah nilai |
| **Sisa kesabaran** | 0 – 1.0 | Semakin cepat dilayani, semakin besar |
| **Kelezatan** | 0.5 – 1.2 | Pahit menurunkan; gula jawa menaikkan |
| **Kematangan** | 0.4 – 1.2 | Pas = bonus, mentah/gosong = penalti |

**Tidak ada faktor "efisiensi ruang".** Kuali setengah kosong dibayar sama
dengan kuali penuh, asal takarannya terpenuhi. Alasannya: takaran **sudah**
mengukur hal yang sama (potensi = sel), jadi menambah denda ruang kosong
berarti menghukum satu hal dua kali.

**Akurasi ditimbang takaran** — ini beda penting dari versi lama:

```
Butuh PENCERNAAN 4, pemain masuk 1 sel kunyit
  lama : gejala tidak tertangani     → akurasi 0.0   "salah total"
  baru : 1 dari 4 dosis terpenuhi    → akurasi 0.25  "kurang takaran"
```

Bedanya bukan cuma angka — bedanya **pelajaran yang disampaikan**. Pemain yang
memilih tanaman yang benar tapi kurang banyak harus diberi tahu *itu*, bukan
disamakan dengan pemain yang salah tanaman.

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
| **Alat** | +2 penggunaan pipisan |

**Tension desain yang sehat:** boon "Pengetahuan" membuat game lebih mudah tapi
mengurangi tantangan deduksi. Ini pilihan yang bermakna: pemain baru mengambilnya,
pemain mahir melewatinya demi boon yang lebih kuat. Ini juga **difficulty slider
alami** tanpa menu setting.

---

## 9. Struktur Endless

| Hari | Yang berubah |
|---|---|
| 1–2 | Tutorial terselubung. 1 gejala per customer. Panci 1 slot |
| 3–5 | 2 gejala. Ampas mulai muncul. Panci 2 slot |
| 6–9 | 3 gejala. Bahan langka muncul. Customer lebih tidak sabar |
| 10+ | Skala tanpa batas: gejala 3–4, ampas padat, timer lebih ketat |

**Kondisi kalah:** kepuasan pelanggan (reputasi kedai) habis. Melayani dengan
buruk mengurangi reputasi; melayani dengan baik menambahnya.

---

## 10. Yang Membuat Ini Layak Menang di Bootcamp

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

## 11. Risiko & Mitigasi

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
