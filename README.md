# ACARAKI — Peracik Jamu Majapahit

Game puzzle-management lima hari bertema warisan jamu Indonesia, dibuat untuk tugas akhir
**IGDX Bootcamp**.

Kamu adalah **acaraki** — sebutan asli untuk peracik jamu, tercatat dalam
Prasasti Madhawapura era Majapahit. Pelanggan datang dengan keluhan, bukan dengan
pesanan. Kamu yang harus tahu tanaman apa yang menyembuhkannya.

---

## Cara Main

1. **Dengarkan** keluhan pelanggan — label gejala dan nama jamu disembunyikan
2. **Diagnosis** dari dialog atau petunjuk tambahan
3. **Pelajari** kandidat bahan lewat Serat Wulandari (`F`)
4. **Racik** dengan puzzle penataan bahan ke dalam kuali
5. **Rebus** di panci, atur api lalu angkat botol pada saat yang tepat
6. **Sajikan**, dapatkan uang, dan pilih persiapan untuk hari berikutnya

---

## Status Prototype

Vertical slice sudah bisa dimainkan — diagnosis berbasis clue, dictionary Serat,
puzzle takaran, pipisan, suhu, biaya bahan, empat resep warisan, laporan layanan,
ekonomi, upgrade, tema harian, kondisi kalah, dan kemenangan hari kelima.
Belum ada production art/audio; visual prototype dibangun dari node scene dan
`icon.svg` bawaan Godot.

**Catatan visual:** panel diagnosis, Serat, intro, laporan hasil, dan akhir hari
dibangun sebagai scene UI yang mudah diganti saat art final masuk. Latar memakai
`ColorRect`, `Polygon2D`, `Line2D`, dan animasi scene; `icon.svg` tetap menjadi
placeholder karakter.

**Urutan main (langkah demi langkah):**

```
1. KASIR   klik [ PERIKSA KELUHAN ]
2. KASIR   baca dialog, pilih 1–3 diagnosis; boleh minta clue (-5 detik)
3. KASIR   klik [ AMBIL PESANAN ] — boleh ambil BEBERAPA sekaligus
4. F       buka Serat untuk mencari bahan berdasarkan keluhan
5. TAB     pindah ke Dapur
6. DAPUR   seret bahan dari RAK ke KUALI
             (mau dosis presisi? seret ke PIPISAN dulu)
7. DAPUR   klik tombol [ SELESAI ] di samping kuali
8. DAPUR   W/S atur api; saat SIAP, seret botol keluar dari panci
9. TAB     kembali ke Kasir
10. KASIR  seret botol dari DIBAWA ke pelanggan
11. AKHIR HARI pilih satu upgrade atau meditasi gratis
```

**Langkah 2 tidak bisa dilewati.** Sebelum ambil pesanan, kuali di dapur kosong
dan tombol SELESAI menolak jalan. Ini disengaja: kalau dapur tetap bisa dipakai
tanpa mengambil pesanan, pemain tidak pernah sadar bahwa itu sebuah langkah.

**Satu kuali melayani siapa saja.** Mengambil beberapa pesanan tidak mengunci
dapur ke salah satunya — tidak ada status "sedang meracik". Kamu meracik satu
ramuan, lalu memutuskan siapa yang cocok menerimanya. Kadang satu racikan
kebetulan cocok untuk dua orang sekaligus; kartu di dapur menampilkan **semua**
pesanan yang diambil sekaligus supaya kamu bisa melihatnya.

```
PESANAN DIAMBIL
Isi kuali:  Pencernaan 4  Lemah 3

[o] Raka                        ◆ RACIKAN COCOK
    Pencernaan  ###   3/3

[o] Ki Wanata
    Hati        _____ 0/5
    Lemah       ###   3/3
```

Waktu dan kesabaran **jalan di kedua ruangan**. Botol jamu dibawa di tangan,
jadi bisa diberikan ke **siapa saja** di antrean — termasuk orang yang salah.
Nilainya dihitung saat diserahkan, berdasarkan keluhan orang yang **menerima**,
bukan orang yang memesannya.

**Takaran — aturannya satu kalimat:**

> **1 petak bahan = 1 takaran.**

Kunyit bentuknya 2×2 = 4 petak, jadi dia memberi **4 takaran**. Sebutir beras
1 petak = **1 takaran**. Rak Serat menulis angkanya langsung (`+4`, `+1`), jadi
tidak perlu menghitung petak sendiri.

Kalau pelanggan minta `PENCERNAAN 5`, kamu butuh 5 petak bahan yang menangani
pencernaan — misalnya 1 kunyit (+4) dan 1 beras... yang ternyata tidak menangani
pencernaan. Jadi: 1 kunyit (+4) + 1 asam jawa (+4) = 8, lebih dari cukup.
Kelebihan tetap manjur, tetapi kehilangan bonus **presisi dosis**. Bar menulis
angka sebenarnya (`8/5`), sehingga pemain dapat memilih cepat atau memakai
pipisan untuk mengejar racikan sempurna.

Bar di kartu pesanan terisi **saat itu juga** berdasarkan diagnosis pemain.
Jawaban asli baru dibuka setelah jamu diserahkan, lewat laporan Diagnosis,
Khasiat, Takaran, Rasa, Rebusan, dan untung bersih.

**Pipisan = mesin potong, persis seperti Waste Crusher.** Tidak ada tombol alat.
Mata pisaunya **diam**; yang kamu geser adalah bahannya.

```
        │  ← pisau diam di sini
   ▓▓▓▓▓│▓▓▓     geser bahan kiri/kanan
        │        → memilih di kolom mana potongan jatuh
```

Garis hijau menunjukkan letak potongan sebelum kamu melepas. Dua potongnya
**tetap di mesin** sampai kamu ambil, dan mesin terkunci selama masih ada
potongan di atasnya.

> Pisau jatuh vertikal, jadi cuma **lebar** yang bisa dibelah. Bahan tinggi
> seperti brotowali (1×4) harus **diputar dulu** pakai `R`.

**Kontrol:**

| Tombol | Fungsi |
|---|---|
| Klik `PERIKSA KELUHAN` | Buka catatan diagnosis pelanggan |
| Klik diagnosis / `TANYA PETUNJUK` | Catat dugaan atau minta clue dengan biaya waktu |
| `F` | Buka/tutup Serat Wulandari; waktu melambat saat belajar |
| Klik `AMBIL PESANAN` | Bawa diagnosis ke dapur (boleh beberapa order) |
| Klik `SELESAI` (di samping kuali) | Jadikan isi kuali sebuah jamu — **tidak perlu penuh** |
| `TAB` | Pindah ruangan (Kasir ⇄ Dapur) |
| Drag kiri | Bahan → kuali/pipisan · botol matang → keluar panci/pelanggan |
| `R` / klik-kanan / scroll | Putar bahan |
| `W` / `S` | Atur besar api |
| `SPASI` | Pintasan untuk tombol SELESAI |
| `C` | Kosongkan kuali |

**Menjalankan tes:**

```bash
godot --headless --script res://Scripts/Core/self_test.gd   # unit
godot --headless --script res://Scripts/Core/sim_test.gd    # simulasi & balans
godot --headless --script res://Scripts/Core/flow_test.gd   # integrasi 2 ruangan
```

- `sim_test` memainkan pesanan otomatis, melaporkan jendela suhu yang mustahil,
  dan **membuktikan tiap papan yang mungkin muncul masih bisa diselesaikan**
  (1.488 papan disapu tiap run). Pakai ini tiap kali menyetel angka bahan.
- `flow_test` menjalankan node sungguhan: ganti ruangan, bawa jamu, serahkan —
  menangkap bug yang tidak terlihat oleh tes logika murni.

---

## Dokumentasi

| Dokumen | Isi |
|---|---|
| [01-GDD-Core.md](Docs/01-GDD-Core.md) | Loop utama, analisis desain, sistem gejala |
| [02-Ingredients.md](Docs/02-Ingredients.md) | 12 bahan + khasiat nyata bersumber |
| [03-Customers.md](Docs/03-Customers.md) | 8 karakter & motivasinya |
| [04-Architecture.md](Docs/04-Architecture.md) | Rencana teknis, reuse dari Waste Crusher |
| [05-Production.md](Docs/05-Production.md) | Prioritas MUST/SHOULD/COULD |
| [06-Fun-Vertical-Slice.md](Docs/06-Fun-Vertical-Slice.md) | Sistem diagnosis, ekonomi, lima hari, dan hipotesis playtest |

---

## Teknis

- **Engine:** Godot 4.7 — [unduh di sini](https://godotengine.org/download/archive/4.7-stable/)
- **Basis kode puzzle:** diadaptasi dari *Waste Crusher* (BGD Jam 2026)

---

## Catatan

Khasiat bahan yang ditampilkan merujuk pada **penggunaan tradisional** dan bukan
saran medis. Jamu diakui UNESCO sebagai Warisan Budaya Takbenda pada 2023.

### Audio credits

- Selected UI sound effects by AmbroggioMusic.
- UI Sound Effects by lolurio (CC BY 4.0).
