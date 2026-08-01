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
ekonomi, dan day loop. Visual masih pakai primitif (`_draw`), belum ada art/audio.

**Dua ruangan, dihubungkan `TAB`:**

```
   ┌─────── KASIR ───────┐         ┌─────── DAPUR ───────┐
   │ baca keluhan        │  TAB    │ SERAT → KUALI       │
   │ klik → pesanan aktif│ ◄────►  │ alat 1/2/3          │
   │ serahkan jamu       │         │ SPASI → PANCI       │
   └─────────────────────┘         └─────────────────────┘
              ▲                               │
              └──── bawa maks 3 jamu ─────────┘
```

Waktu dan kesabaran **jalan di kedua ruangan**. Botol jamu dibawa di tangan,
jadi bisa diberikan ke **siapa saja** di antrean — termasuk orang yang salah.
Nilainya dihitung saat diserahkan, berdasarkan keluhan orang yang **menerima**,
bukan orang yang memesannya.

**Takaran:** tiap gejala minta sejumlah *potensi*, dan tiap **sel** bahan
menyumbang 1. Jadi kunyit 2×2 memberi 4, sebutir beras memberi 1 — ukuran bahan
menentukan kekuatannya. Bar takaran terisi real-time saat menaruh bahan, jadi
tidak ada resep yang perlu dihafal.

**Kontrol:**

| Tombol | Fungsi |
|---|---|
| `TAB` | Pindah ruangan (Kasir ⇄ Dapur) |
| Drag kiri | Bahan → kuali · botol → panci · botol → pelanggan |
| `R` / klik-kanan / scroll | Putar bahan |
| `SPASI` | Jadikan isi kuali sebuah jamu — **tidak perlu penuh** |
| `1` `2` `3` | Pipisan (belah) · Tumbuk (padatkan) · Saring (bersihkan ampas) |
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
