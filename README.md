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
3. **Racik** dengan puzzle penataan bahan ke dalam kuali
4. **Rebus** di panci, atur api sesuai kebutuhan tiap bahan
5. **Sajikan** sebelum kesabaran mereka habis

---

## Status Prototype

Loop inti sudah bisa dimainkan — puzzle, deduksi gejala, rebusan, ekonomi, dan
day loop. Visual masih pakai primitif (ColorRect/`_draw`), belum ada art/audio.

**Alur main:**

```
SERAT ──drag──> KUALI ──SPASI──> BOTOL di MEJA ──drag──> PANCI ──drag──> PELANGGAN
(rak bahan)     (puzzle)         (jamu jadi)             (rebus)         (sajikan)
```

Botol jamu adalah **benda fisik** yang dibawa pemain. Karena itu ia bisa
diberikan ke **siapa saja** di antrean — termasuk orang yang salah. Nilainya
dihitung saat diserahkan, berdasarkan keluhan orang yang **menerima**, bukan
orang yang memesannya.

**Kontrol:**

| Tombol | Fungsi |
|---|---|
| Drag kiri | Ambil bahan dari Serat → kuali · lalu botol → panci → pelanggan |
| `R` / klik-kanan / scroll | Putar bahan |
| `SPASI` | Jadikan isi kuali sebuah botol jamu (kuali harus penuh) |
| `W` / `S` | Atur besar api |
| `Q` / `E` | Ganti pesanan yang sedang diracik |
| `TAB` | Mode baca — waktu melambat 80% |

**Menjalankan tes:**

```bash
godot --headless --script res://Scripts/Core/self_test.gd   # unit
godot --headless --script res://Scripts/Core/sim_test.gd    # simulasi & balans
```

`sim_test` memainkan puluhan pesanan otomatis dan melaporkan berapa banyak
racikan yang jendela suhunya mustahil — pakai ini tiap kali menyetel angka bahan.

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
