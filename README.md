# ACARAKI — Peracik Jamu Majapahit

Game puzzle endless bertema warisan jamu Indonesia, dibuat untuk tugas akhir
**IGDX Bootcamp**.

Kamu adalah **acaraki** — sebutan asli untuk peracik jamu, tercatat dalam
Prasasti Madhawapura era Majapahit. Pelanggan datang dengan keluhan, bukan dengan
pesanan. Kamu yang harus tahu tanaman apa yang menyembuhkannya.

---

## Cara Main

1. **Dengarkan** keluhan pelanggan — mereka tidak menyebut nama jamu
2. **Deduksi** bahan apa yang menangani gejalanya
3. **Racik** dengan puzzle penataan bahan ke dalam kuali, sampai takarannya cukup
4. **Rebus** di panci, atur api sesuai kebutuhan tiap bahan
5. **Sajikan** sebelum kesabaran mereka habis

---

## Status Prototype

Loop inti sudah bisa dimainkan — puzzle, deduksi gejala, takaran, alat, rebusan,
ekonomi, dan day loop. Belum ada art/audio.

**Catatan visual:** UI sengaja dibiarkan polos — tanpa panel, bingkai, atau
background hias. Yang digambar hanya hal yang membawa informasi (petak kuali,
bar takaran, potongan bahan) plus `icon.svg` sebagai placeholder pelanggan.
Status seperti "sedang dipilih" atau "hover" disampaikan lewat **warna teks dan
tint ikon**, bukan lewat kotak berwarna. Alasannya praktis: makin sedikit hiasan
sementara, makin sedikit yang harus dibongkar saat art asli masuk.

**Urutan main (langkah demi langkah):**

```
1. KASIR   baca keluhan pelanggan
2. KASIR   klik tombol [ AMBIL PESANAN ] di kartunya   <- WAJIB
3. TAB     pindah ke Dapur
4. DAPUR   seret bahan dari SERAT ke KUALI
             (mau dibelah/dipadatkan dulu? seret ke PIPISAN / TUMBUK)
5. DAPUR   SPASI  -> jadi jamu, masuk panci
6. DAPUR   W/S atur api sampai matang
7. TAB     kembali ke Kasir
8. KASIR   seret botol dari DIBAWA ke pelanggan
```

**Langkah 2 tidak bisa dilewati.** Sebelum ambil pesanan, kuali di dapur kosong
dan `SPASI` menolak jalan. Ini disengaja: kalau dapur tetap bisa dipakai tanpa
memilih siapa, pemain tidak pernah sadar bahwa "ambil pesanan" itu sebuah
langkah.

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
Kelebihan tidak dihukum.

Bar di kartu pesanan terisi **saat itu juga** setiap kali kamu menaruh bahan,
jadi tidak ada resep yang perlu dihafal — tinggal lihat sampai tertulis `cukup`.

**Alat = mesin fisik.** Tidak ada tombol alat. Pipisan dan Tumbuk adalah **kotak
di meja**: seret bahan ke dalamnya, hasilnya keluar di sebelahnya, lalu kamu
seret sendiri ke kuali. Sama seperti mesin di Waste Crusher.

**Kontrol:**

| Tombol | Fungsi |
|---|---|
| Klik `AMBIL PESANAN` | Ambil order pelanggan (wajib, di Kasir) |
| `TAB` | Pindah ruangan (Kasir ⇄ Dapur) |
| Drag kiri | Bahan → kuali / mesin · botol → panci · botol → pelanggan |
| `R` / klik-kanan / scroll | Putar bahan |
| `SPASI` | Jadikan isi kuali sebuah jamu — **tidak perlu penuh** |
| `W` / `S` | Atur besar api |
| `Q` / `E` | Ganti pesanan yang sedang diracik |
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

---

## Teknis

- **Engine:** Godot 4.7 — [unduh di sini](https://godotengine.org/download/archive/4.7-stable/)
- **Basis kode puzzle:** diadaptasi dari *Waste Crusher* (BGD Jam 2026)

---

## Catatan

Khasiat bahan yang ditampilkan merujuk pada **penggunaan tradisional** dan bukan
saran medis. Jamu diakui UNESCO sebagai Warisan Budaya Takbenda pada 2023.
