# ACARAKI — Database Bahan & Resep

> Semua khasiat di bawah **berbasis penggunaan tradisional nyata** dan disertai
> sumber. Ini fondasi klaim edukatif game. Jangan mengarang khasiat baru —
> kalau butuh bahan tambahan, riset dulu.

---

## Prinsip Desain Bahan

Setiap bahan punya **tiga lapis identitas** yang harus konsisten:

1. **Fakta** — khasiat tradisional yang sungguh ada
2. **Terjemahan RPG** — padanan "potion" yang jujur pada faktanya
3. **Bentuk block** — bentuk puzzle yang mencerminkan wujud fisik tanaman aslinya

Lapis ke-3 sering dilupakan, padahal ini yang bikin pemain **ingat**. Jahe punya
bentuk rimpang bercabang → block-nya bentuk L/T. Beras itu butiran kecil →
block 1×1. Bentuk jadi alat bantu ingat.

---

## Sistem Gejala (Symptom Tags)

Ini tulang punggung sistem deduksi. Customer mengeluh dalam bentuk **gejala**;
tiap bahan **menangani** gejala tertentu.

| Kode Gejala | Keluhan customer terdengar seperti | Padanan RPG |
|---|---|---|
| `DEMAM` | "Badanku panas", "menggigil" | Debuff: Burning |
| `NYERI_SENDI` | "Pinggangku ngilu", "pegal linu" | Debuff: Slowed |
| `LEMAH` | "Tidak bertenaga", "gampang capek" | Buff: Strength |
| `PENCERNAAN` | "Perutku kembung", "mual" | Debuff: Poisoned |
| `BATUK` | "Tenggorokanku gatal", "berdahak" | Debuff: Silenced |
| `NAFSU_MAKAN` | "Tidak selera makan", "kurus" | Buff: Vitality |
| `DINGIN` | "Kedinginan", "masuk angin" | Resist: Cold |
| `LUKA_DALAM` | "Bekas jatuh", "memar" | Regeneration |
| `PIKIRAN` | "Sulit tidur", "cemas", "pusing" | Buff: Focus |
| `KULIT` | "Gatal-gatal", "jerawat" | Cleanse |
| `HATI_LIVER` | "Mata kuning", "lemas terus" | Detox |
| `WANITA` | Nyeri haid, pasca-melahirkan | Restore |

---

## BAHAN INTI (8) — tersedia sejak Hari 1

### 1. BROTOWALI — *Tinospora crispa*

| | |
|---|---|
| **Julukan RPG** | **Potion of Bitter Resolve** (Ramuan Tekad Pahit) |
| **Menangani** | `DEMAM`, `KULIT`, `NAFSU_MAKAN` |
| **Bentuk block** | 1×4 batang lurus, berbintil (batangnya memang panjang merambat) |
| **Rasa** | Sangat pahit ★★★★★ |
| **Zona api** | Panas — butuh direbus lama agar senyawa pahitnya keluar |

**Fakta:** Tanaman merambat dengan batang berbintil khas dan rasa yang sangat
pahit. Mengandung alkaloid, flavonoid, saponin, dan senyawa pahit (pikroretin,
berberin, palmatin, kolumbin). Secara tradisional dipercaya bersifat
**antipiretik** (menurunkan panas) dan **antiinflamasi**, serta digunakan untuk
gatal-gatal, menambah nafsu makan, dan membersihkan darah.

> **Catatan untuk tim:** ide awal "brotowali = strength potion untuk perang"
> perlu dikoreksi. Brotowali **bukan** penambah kekuatan — ia penurun demam dan
> antiradang. Untuk "prajurit mau perang", padanan yang benar adalah
> **Beras Kencur** (stamina) atau **Jahe Merah** (kekuatan/kehangatan).
>
> Tapi brotowali tetap bisa masuk cerita perang dengan cara yang **lebih akurat
> dan lebih menarik**: prajurit yang **terluka dan demam** di kamp, atau prajurit
> yang lukanya gatal dan terinfeksi. Lihat karakter *Jayeng* di `03-Customers.md`.

---

### 2. JAHE MERAH — *Zingiber officinale var. rubrum*

| | |
|---|---|
| **Julukan RPG** | **Potion of Inner Fire** (Ramuan Api Dalam) |
| **Menangani** | `DINGIN`, `LEMAH`, `NYERI_SENDI`, `BATUK` |
| **Bentuk block** | Bentuk L bercabang (rimpang memang bercabang) |
| **Rasa** | Pedas hangat ★★★★ |
| **Zona api** | Sangat panas — harus mendidih |

**Fakta:** Jahe merah mengandung minyak atsiri 2,58–2,72%, lebih tinggi dari jahe
biasa. Mengandung gingerol dan shogaol yang bersifat antimikroba. Secara
tradisional digunakan untuk **menghangatkan tubuh**, meredakan masuk angin,
pegal linu, dan batuk.

---

### 3. KUNYIT — *Curcuma longa*

| | |
|---|---|
| **Julukan RPG** | **Potion of Golden Ward** (Ramuan Perisai Emas) |
| **Menangani** | `PENCERNAAN`, `NYERI_SENDI`, `WANITA` |
| **Bentuk block** | 2×2 rimpang gemuk |
| **Rasa** | Getir hangat ★★ |
| **Zona api** | **Sedang** — kurkumin rusak bila terlalu panas |

**Fakta:** Kandungan aktif utamanya **kurkuminoid**, terutama kurkumin, yang
dikenal bersifat **antiinflamasi dan antioksidan kuat**. Bahan utama jamu
**kunyit asam**, yang secara tradisional diminum perempuan untuk meredakan nyeri
haid.

---

### 4. KENCUR — *Kaempferia galanga*

| | |
|---|---|
| **Julukan RPG** | **Potion of Steady Breath** (Ramuan Napas Tenang) |
| **Menangani** | `BATUK`, `NYERI_SENDI`, `LEMAH` |
| **Bentuk block** | 2×1 rimpang kecil |
| **Rasa** | Tajam segar ★★★ |
| **Zona api** | Rendah–sedang |

**Fakta:** Manfaat utamanya untuk **mengobati batuk, melegakan pernapasan, dan
menghilangkan dahak**. Senyawanya bersifat antiinflamasi dan pereda nyeri,
membantu mengurangi **nyeri sendi dan otot**.

---

### 5. TEMULAWAK — *Curcuma xanthorrhiza*

| | |
|---|---|
| **Julukan RPG** | **Potion of Deep Cleansing** (Ramuan Pembersih Dalam) |
| **Menangani** | `HATI_LIVER`, `NAFSU_MAKAN`, `PENCERNAAN` |
| **Bentuk block** | 2×3 rimpang besar |
| **Rasa** | Pahit getir ★★★ |
| **Zona api** | Sedang–panas |

**Fakta:** Dikenal luas sebagai **hepatoprotektor** — melindungi dan memperbaiki
fungsi **hati (liver)**. Senyawa kuncinya **xanthorrhizol**. Juga tradisional
dipakai untuk menambah nafsu makan, terutama pada anak-anak.

> Ini bahan paling khas Indonesia di daftar ini — temulawak hampir tidak dipakai
> di pengobatan herbal negara lain. Layak jadi bahan "bintang" di cerita.

---

### 6. BERAS — *Oryza sativa*

| | |
|---|---|
| **Julukan RPG** | **Base: Grain of Endurance** (Dasar: Butir Ketahanan) |
| **Menangani** | `LEMAH`, `NAFSU_MAKAN` (penguat, bukan penyembuh) |
| **Bentuk block** | 1×1 butiran — bahan pengisi celah |
| **Rasa** | Netral, melembutkan rasa pahit |
| **Zona api** | **Rendah** — gampang gosong |

**Fakta:** Komponen utama **beras kencur**, jamu yang secara tradisional dipercaya
menambah **stamina**, mengembalikan nafsu makan, dan menghilangkan pegal linu.

**Peran puzzle:** karena bentuknya 1×1, beras adalah *pengisi celah* — bahan yang
menyelamatkan pemain saat kuali tersisa satu lubang kecil. Ini membuatnya berguna
secara mekanik, bukan cuma tematik.

---

### 7. ASAM JAWA — *Tamarindus indica*

| | |
|---|---|
| **Julukan RPG** | **Modifier: Souring Agent** (Pelaras Rasa) |
| **Menangani** | `PENCERNAAN`, `KULIT` |
| **Bentuk block** | Bentuk S/Z melengkung (polong memang bengkok) |
| **Rasa** | Asam ★★★★ |
| **Zona api** | Rendah |

**Fakta:** Mengandung **antosianin** yang berfungsi sebagai analgesik (anti-nyeri).
Pasangan klasik kunyit dalam **kunyit asam**.

**Peran puzzle:** bentuknya menyebalkan (S/Z) tapi ia **menurunkan kepahitan**
seluruh racikan — trade-off yang jelas.

---

### 8. GULA JAWA / GULA AREN

| | |
|---|---|
| **Julukan RPG** | **Modifier: Sweetening Base** (Pelembut Rasa) |
| **Menangani** | — (tidak menyembuhkan; menaikkan *kepuasan*) |
| **Bentuk block** | 2×2 blok padat |
| **Rasa** | Manis ★★★★★ |
| **Zona api** | Rendah — gampang gosong/karamel |

**Peran:** tidak menangani gejala apa pun, tapi **menaikkan bayaran** karena jamu
jadi lebih enak diminum. Mengajarkan hal yang benar: gula jawa memang ditambahkan
agar jamu bisa diminum, bukan karena khasiat.

**Keputusan menarik:** pakai gula = jamu lebih laku, tapi menghabiskan ruang kuali
yang berharga.

---

## BAHAN LANJUTAN (4) — unlock Hari 4+

### 9. SAMBILOTO — *Andrographis paniculata*
- **RPG:** *Potion of Purging Light* · **Gejala:** `DEMAM`, `KULIT`, `HATI_LIVER`
- **Bentuk:** Bentuk T bercabang (daun) · **Rasa:** Pahit ekstrem ★★★★★
- **Fakta:** Kandungan utamanya **andrographolide**, bersifat antiinflamasi,
  antioksidan, dan antivirus. Tradisional untuk meredakan **gejala flu, demam,
  dan menurunkan tekanan darah**. Bahan utama **jamu pahitan**.

### 10. TEMU IRENG — *Curcuma aeruginosa*
- **RPG:** *Potion of Iron Blood* · **Gejala:** `NAFSU_MAKAN`, `LEMAH`, `WANITA`
- **Bentuk:** 2×3 · **Rasa:** Sangat pahit ★★★★
- **Fakta:** Bahan **jamu cabe puyang**, tradisional untuk menambah nafsu makan
  dan membantu produksi sel darah merah (mencegah anemia).

### 11. DAUN SIRIH — *Piper betle*
- **RPG:** *Potion of Clean Wound* · **Gejala:** `KULIT`, `LUKA_DALAM`, `WANITA`
- **Bentuk:** Bentuk hati/P-hook · **Rasa:** Pedas getir ★★★
- **Fakta:** Bahan jamu tradisional yang lama digunakan sebagai **antiseptik**,
  untuk membersihkan luka dan menjaga kesehatan area kewanitaan.

### 12. KAYU MANIS — *Cinnamomum burmannii*
- **RPG:** *Potion of Warm Focus* · **Gejala:** `DINGIN`, `PIKIRAN`, `PENCERNAAN`
- **Bentuk:** 1×3 batang gulung · **Rasa:** Manis hangat ★★
- **Fakta:** Rempah asli Indonesia (**cassia vera** dari Sumatera Barat adalah
  komoditas ekspor bersejarah). Bahan **galian singset** dan berbagai jamu
  penghangat.

---

## Resep Jamu Klasik (referensi Serat / Cookbook)

Ini **bukan** target wajib — pemain bebas merakit. Tapi resep klasik memberi
**bonus "Racikan Sempurna" +25%** bila persis, dan berfungsi sebagai materi ajar.

| Jamu | Bahan | Khasiat tradisional | Padanan RPG |
|---|---|---|---|
| **Beras Kencur** | Beras + Kencur + Jahe + Gula Jawa | Stamina, nafsu makan, pegal linu | Stamina Potion |
| **Kunyit Asam** | Kunyit + Asam Jawa + Gula Jawa | Nyeri haid, pencernaan | Pain Relief |
| **Pahitan** | Sambiloto + Brotowali | Gatal, diabetes, bersihkan darah | Cleanse / Detox |
| **Wedang Jahe** | Jahe Merah + Gula Jawa + Kayu Manis | Masuk angin, hangat | Cold Resist |
| **Cabe Puyang** | Temu Ireng + Temulawak + Jahe + Asam | Pegal linu, anemia | Regeneration |
| **Galian Singset** | Kunyit + Temulawak + Kencur + Kayu Manis + Asam | Kebugaran tubuh | Fitness Buff |
| **Sinom** | Kunyit + Asam muda + Gula Jawa | Segar, pencernaan | Refreshment |
| **Kunci Suruh** | Daun Sirih + Kunyit | Kesehatan wanita | Restoration |

> **Catatan komposisi:** resep jamu tradisional bervariasi antar daerah dan antar
> peracik. Versi di atas disederhanakan agar cocok untuk puzzle. Tidak apa-apa —
> yang penting **khasiat tiap bahan akurat**, dan variasi resep memang realistis.

---

## Disclaimer (wajib tampil di game)

Tampilkan di layar judul atau kredit:

> *Game ini terinspirasi dari warisan jamu Indonesia yang telah diakui UNESCO
> sebagai Warisan Budaya Takbenda. Khasiat yang ditampilkan merujuk pada
> penggunaan tradisional dan bukan merupakan saran medis. Konsultasikan dengan
> tenaga kesehatan untuk masalah kesehatan Anda.*

Ini bukan cuma etis — juri bootcamp akan menghargainya sebagai tanda riset yang
bertanggung jawab.

---

## Sumber

- [Brotowali Tinospora Crispa: Si Pahit Kaya Manfaat Herbal — Halodoc](https://www.halodoc.com/artikel/brotowali-tinospora-crispa-si-pahit-kaya-manfaat-herbal)
- [8 Manfaat Brotowali bagi Kesehatan — Alodokter](https://www.alodokter.com/8-manfaat-brotowali-bagi-kesehatan-dari-mengatasi-demam-hingga-diabetes)
- [Empon-empon, Manfaat dan Cara Membuatnya — Alodokter](https://www.alodokter.com/empon-empon-ketahui-manfaat-dan-cara-membuatnya)
- [Empat Empon-empon Populer — Kompas](https://www.kompas.com/skola/read/2020/03/08/213018869/empat-empon-empon-populer?page=all)
- [10 Jamu Khas Indonesia: Sejarah, Bahan, Khasiat — Kompas](https://regional.kompas.com/read/2022/03/13/200517278/10-jamu-khas-indonesia-sejarah-bahan-khasiat-dan-cara-pembuatan?page=all)
- [Manfaat Daun Sambiloto — Bio Farma](https://www.biofarma.co.id/id/announcement/detail/ini-5-manfaat-daun-sambiloto-yang-perlu-kamu-tahu)
- [10 Jamu Khas Jateng dan Manfaatnya — Detik](https://www.detik.com/jateng/berita/d-6805273/10-jamu-khas-jateng-dan-manfaatnya-bagi-kesehatan)
- [Jamu Beras Kencur: Cara Buat dan Khasiat — Detik](https://www.detik.com/jogja/kuliner/d-8252179/jamu-beras-kencur-untuk-obat-apa-ini-cara-buat-dan-9-khasiat-bagi-kesehatan)
- [3 Jamu Herbal Asli Indonesia, Galian Singset — Tribun Health](https://health.tribunnews.com/2024/09/21/3-jamu-herbal-asli-indonesia-beserta-khasiatnya-galian-singset-untuk-apa)
