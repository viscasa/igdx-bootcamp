# ACARAKI — Karakter Pelanggan

> Setting: kota pelabuhan Majapahit, abad ke-14. Pelabuhan dipilih karena
> memungkinkan **keragaman pelanggan** yang masuk akal: prajurit, pedagang asing,
> nelayan, bangsawan, petani — semua berkumpul di satu tempat.

---

## Prinsip Penulisan Karakter

**Aturan #1 — Pelanggan tidak boleh menyebut nama jamu.**
Mereka menyebut **keluhan** dan **konteks hidupnya**. Pemain yang menerjemahkan.

**Aturan #2 — Setiap pelanggan mengajarkan satu hal budaya.**
Bukan lewat ceramah, tapi lewat siapa mereka dan kenapa mereka butuh.

**Aturan #3 — Gejalanya berlapis, bukan tunggal.**
Ini yang membuat deduksi tetap hidup setelah puluhan kali main (lihat GDD §4).

**Aturan #4 — Dialog bervariasi.**
Tiap karakter punya 4–6 varian keluhan dengan kombinasi gejala berbeda. Karakter
yang sama muncul lagi bukan berarti pesanan yang sama.

---

## Anatomi Sebuah Pesanan

```
┌──────────────────────────────────────────────┐
│  [Sprite]   JAYENG — Prajurit                 │
│                                               │
│  "Besok pasukan berangkat ke timur. Tapi      │
│   badanku panas sejak semalam, dan bekas      │
│   luka di lenganku gatal tak karuan.          │
│   Aku tak mau ditinggal."                     │
│                                               │
│  Gejala terdeteksi:  [DEMAM]  [KULIT]         │
│  Kesabaran:  ████████░░  (8.0 detik)          │
└──────────────────────────────────────────────┘
```

Panel "Gejala terdeteksi" **bisa dimatikan** lewat pengaturan kesulitan — pemain
mahir membaca langsung dari dialog. Ini difficulty slider yang elegan.

---

## KAST UTAMA (8 karakter)

### 1. JAYENG — Prajurit Muda
> *Kesabaran: Rendah · Bayaran: Sedang*

Prajurit yang selalu terburu-buru dan sedikit sombong, tapi diam-diam takut
mengecewakan komandannya.

**Kenapa dia butuh jamu:** hidup di barak, tidur beralas tanah, sering terluka
saat latihan. Prajurit Majapahit tidak punya tabib pribadi — mereka mengandalkan
acaraki kota.

**Varian keluhan:**

| # | Dialog | Gejala | Bahan yang tepat |
|---|---|---|---|
| 1 | *"Badanku panas sejak semalam, dan bekas luka di lenganku gatal."* | `DEMAM` `KULIT` | Brotowali, Daun Sirih |
| 2 | *"Besok berbaris jauh. Kakiku sudah ngilu dari kemarin, dan aku kurang tenaga."* | `NYERI_SENDI` `LEMAH` | Kencur, Beras, Jahe Merah |
| 3 | *"Semalam jaga di menara, anginnya menusuk. Sekarang dadaku sesak dan batuk."* | `DINGIN` `BATUK` | Jahe Merah, Kencur |
| 4 | *"Aku jatuh dari kuda. Tidak patah, tapi memar di mana-mana dan pinggangku kaku."* | `LUKA_DALAM` `NYERI_SENDI` | Daun Sirih, Kunyit, Kencur |

**Nilai edukatif:** menghancurkan asumsi "prajurit = ramuan kekuatan". Prajurit
sungguhan butuh **pemulihan**, bukan buff kekuatan. Ini koreksi yang menarik dari
ide awal tim.

---

### 2. NYAI SEKAR — Pedagang Kain di Pasar
> *Kesabaran: Sedang · Bayaran: Tinggi*

Perempuan paruh baya, tajam soal harga, hafal wajah semua orang di pasar. Dia
pelanggan tetap yang paling sering muncul.

**Kenapa dia butuh jamu:** berdiri seharian, banyak bicara, makan tidak teratur.
Perempuan pedagang adalah **konsumen jamu terbesar secara historis** — dan
sebagian besar penjual jamu gendong juga perempuan.

**Varian keluhan:**

| # | Dialog | Gejala |
|---|---|---|
| 1 | *"Bulanan datang lagi. Perutku melilit tapi lapak tak bisa kutinggal."* | `WANITA` `NYERI_SENDI` |
| 2 | *"Seharian berdiri, pinggangku mau patah. Dan aku belum makan sejak subuh."* | `NYERI_SENDI` `NAFSU_MAKAN` |
| 3 | *"Suaraku habis menawar sejak pagi. Tenggorokanku kering."* | `BATUK` |
| 4 | *"Aku ingin badanku tetap ramping seperti dulu. Ada yang bisa membantu?"* | `PENCERNAAN` `KULIT` (→ Galian Singset) |

**Nilai edukatif:** memperkenalkan **kunyit asam** dan **galian singset** dalam
konteks aslinya — jamu perempuan, bukan sekadar "minuman sehat".

---

### 3. WIRA — Petani Muda
> *Kesabaran: Sangat Tinggi · Bayaran: Rendah*

Sabar, banyak bercerita, sering memberi petunjuk tanpa sadar. Bayarannya kecil
tapi dia **memberi tip berupa pengetahuan** — kadang menyebut nama bahan yang
"dipakai ibunya dulu".

**Kenapa dia butuh jamu:** tubuh tua yang dipakai kerja berat puluhan tahun.

**Varian keluhan:**

| # | Dialog | Gejala |
|---|---|---|
| 1 | *"Sendi-sendiku berbunyi tiap pagi. Umur, katanya."* | `NYERI_SENDI` |
| 2 | *"Mataku menguning kata istriku. Badanku lemas terus."* | `HATI_LIVER` `LEMAH` |
| 3 | *"Sudah tiga hari perutku kembung. Makan pun tak enak."* | `PENCERNAAN` `NAFSU_MAKAN` |
| 4 | *"Sawah masih menunggu, tapi tenagaku tak seperti dulu."* | `LEMAH` `NYERI_SENDI` |

**Peran desain:** kesabarannya tinggi → pelanggan "aman" untuk pemain yang sedang
kewalahan. Dia adalah **katup pelepas tekanan** dalam kurva kesulitan.

**Nilai edukatif:** memperkenalkan **temulawak** untuk liver — khasiat yang paling
khas Indonesia dan paling tidak dikenal pemain asing.

---

### 4. DYAH PRAMESTI — Putri Bangsawan
> *Kesabaran: Sangat Rendah · Bayaran: Sangat Tinggi*

Halus tapi tidak sabar. Menyebut keluhannya dengan bahasa berbunga-bunga sehingga
**lebih sulit diterjemahkan** — ini kesulitan yang datang dari karakter, bukan
dari aturan buatan.

**Varian keluhan:**

| # | Dialog | Gejala |
|---|---|---|
| 1 | *"Semalam aku terjaga hingga ayam berkokok. Pikiranku tak mau diam."* | `PIKIRAN` |
| 2 | *"Wajahku... ada yang tak beres. Aku malu menghadap ayahanda."* | `KULIT` |
| 3 | *"Aku harus tampil di perjamuan besok. Aku ingin terlihat segar dan bercahaya."* | `KULIT` `PENCERNAAN` |
| 4 | *"Makanan istana terlalu berat. Perutku memberontak."* | `PENCERNAAN` `HATI_LIVER` |

**Peran desain:** bayaran besar + kesabaran kecil = **keputusan berisiko**. Layani
duluan (dan telantarkan yang lain) atau lewatkan?

---

### 5. TUAN LI — Pedagang dari Tiongkok
> *Kesabaran: Sedang · Bayaran: Tinggi*

Bahasa Jawanya patah-patah, jadi keluhannya **pendek dan ambigu** — kesulitan
alami lain yang lahir dari karakter.

**Kenapa dia ada:** pelabuhan Majapahit memang ramai pedagang Tiongkok, Arab, dan
India. Kehadirannya historis akurat sekaligus membuka tema **pertukaran
pengetahuan herbal antarbangsa**.

**Varian keluhan:**

| # | Dialog | Gejala |
|---|---|---|
| 1 | *"Laut... perut tidak enak. Banyak goyang."* | `PENCERNAAN` |
| 2 | *"Dingin di kapal. Batuk tidak berhenti."* | `DINGIN` `BATUK` |
| 3 | *"Di negeriku ada akar kuning untuk ini. Di sini ada?"* (menunjuk sendinya) | `NYERI_SENDI` → kunyit |

**Nilai edukatif:** menunjukkan jamu sebagai bagian dari **jaringan perdagangan
rempah dunia**, bukan tradisi yang terisolasi.

---

### 6. MBOK DARMI — Penjual Jamu Gendong Senior
> *Kesabaran: Tinggi · Bayaran: Rendah — tapi memberi RESEP*

Bukan benar-benar pelanggan. Dia rekan seprofesi yang datang bertukar bahan.
Menyelesaikan pesanannya **membuka halaman baru di Serat** (resep klasik).

**Fungsi:** ini adalah **sistem tutorial dan unlock**, dibungkus jadi karakter.
Jauh lebih baik daripada popup "Resep baru terbuka!".

**Dialog contoh:**
> *"Aku kehabisan bahan di jalan, Nak. Buatkan aku satu, dan kuajari kau resep
> yang diajarkan ibuku dulu."*

**Nilai edukatif:** **jamu gendong** adalah tradisi nyata yang kini makin langka —
perempuan penjual jamu keliling yang menggendong bakul botol. Menampilkannya
sebagai mentor yang dihormati adalah pilihan yang bermakna.

---

### 7. RAKA — Anak Kecil
> *Kesabaran: Rendah (anak-anak!) · Bayaran: Sangat Rendah*

Dikirim ibunya, dan **menyampaikan pesan dengan berantakan** — sumber komedi
sekaligus tantangan deduksi.

**Varian keluhan:**

| # | Dialog | Gejala |
|---|---|---|
| 1 | *"Kata Ibu... anu... adikku tidak mau makan. Terus kurus. Itu saja."* | `NAFSU_MAKAN` |
| 2 | *"Ibu bilang buatkan yang pahit. Aku tidak mau tapi harus."* | `KULIT` `PENCERNAAN` |
| 3 | *"Perutku sakit. Aku makan mangga muda banyak sekali tadi."* | `PENCERNAAN` |

**Nilai edukatif:** **temulawak untuk anak susah makan** adalah penggunaan jamu
yang sangat umum di Indonesia sampai hari ini. Pemain Indonesia akan langsung
mengenalinya — momen "eh, ini aku banget".

---

### 8. EMPU GANDRING — Pandai Besi
> *Kesabaran: Sedang · Bayaran: Sedang*

Bekerja di depan tungku sepanjang hari. Namanya adalah **anggukan halus** ke
legenda Jawa (pembuat keris Ken Arok) — pemain Indonesia akan tersenyum.

**Varian keluhan:**

| # | Dialog | Gejala |
|---|---|---|
| 1 | *"Seharian di depan bara. Tenggorokanku kering dan kepalaku berdenyut."* | `BATUK` `PIKIRAN` |
| 2 | *"Percikan besi kena tanganku. Perih dan mulai bengkak."* | `KULIT` `LUKA_DALAM` |
| 3 | *"Punggungku kaku dari menempa. Tapi pesanan tak boleh telat."* | `NYERI_SENDI` `LEMAH` |

---

## Sistem Kesabaran

```
Kesabaran = BasisKarakter × PengaliHari × BoonPemain
```

| Karakter | Basis (detik) |
|---|---|
| Wira | 90 |
| Ibu Darmi | 80 |
| Tuan Li | 60 |
| Ibu Sekar | 55 |
| Bayu | 50 |
| Jayeng | 40 |
| Raka | 35 |
| Dyah Pramesti | 30 |

**Perilaku visual:** bar kesabaran menurun; sprite berubah ekspresi di 50% dan
25%. Di 0% mereka pergi — reputasi berkurang, dan ini terasa buruk secara
emosional, bukan cuma secara angka.

**Antrean:** maksimal 3 pelanggan menunggu sekaligus. Semua timer berjalan
bersamaan. Ini sumber tekanan manajemen utama.

---

## Kenapa Cast Ini Bekerja

1. **Cakupan gejala lengkap** — 12 kode gejala semuanya punya pemilik alami
2. **Kesulitan bervariasi lewat karakter, bukan angka** — Dyah sulit karena
   bicaranya berbunga, Tuan Li sulit karena bahasanya patah, Raka sulit karena
   berantakan. Tiga rasa kesulitan yang berbeda
3. **Ada pelepas tekanan** — Wira dan Ibu Darmi memberi ruang bernapas
4. **Cerita muncul dari pengulangan** — melihat Jayeng pulang dari perang dengan
   luka baru, atau Raka datang sendiri (bukan disuruh ibunya) di hari ke-20,
   menciptakan keterikatan tanpa cutscene apa pun

---

## Ide Lanjutan (bila waktu memungkinkan)

- **Pelanggan langka:** *Bhayangkara* (pengawal raja) — bayaran besar, gejala 4
  lapis, muncul acak setelah hari 10
- **Kejadian harian:** "Musim hujan — banyak yang masuk angin" (gejala `DINGIN`
  lebih sering), "Panen raya — petani berdatangan"
- **Rantai cerita:** Jayeng muncul 5 kali → cerita kecilnya selesai → memberi
  pusaka permanen
- **Pelanggan salah tebak:** ada yang minta jamu *tertentu* padahal gejalanya
  butuh yang lain. Beri yang dia minta = bayaran normal. Beri yang benar =
  bayaran besar + reputasi. Ini pelajaran bagus: **acaraki mendengar tubuh, bukan
  cuma mulut.**
