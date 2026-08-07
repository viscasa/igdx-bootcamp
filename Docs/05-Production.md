# ACARAKI — Prioritas Produksi

> Dokumen ini menjawab satu pertanyaan: **kalau waktu habis, apa yang harus sudah
> jadi?**

---

## Definisi Tiga Tingkat

### 🔴 MUST — tanpa ini tidak ada game

1. Puzzle kuali: drag bahan, isi penuh, validasi
2. Pelanggan dengan dialog bergejala + bar kesabaran
3. Penilaian racikan (akurasi berdasarkan gejala tertangani)
4. Panci dengan tuas api & bar kematangan — **1 slot saja cukup**
5. Timer hari + kondisi kalah
6. Serat (cookbook) yang bisa dicari **berdasarkan gejala**
7. 6 bahan, 3 pelanggan

**Ini sudah merupakan game utuh dan bisa dinilai juri.**

### 🟡 SHOULD — membuatnya bagus

8. Panci multi-slot (2–4)
9. Sistem ampas yang bertambah
10. Layar boon tiap pagi
11. 12 bahan, 8 pelanggan
12. Alat pipisan (mesin potong)
13. Bonus "Racikan Sempurna" untuk resep klasik

### 🟢 COULD — kalau sempat

14. Rantai cerita pelanggan
15. Kejadian harian (musim hujan, panen)
16. Pelanggan langka
17. Papan skor
18. Mode "tanpa panel gejala" (kesulitan tinggi)

---

## Peringatan Scope

Yang paling sering membunuh proyek bootcamp adalah **membangun semua sistem
setengah jadi** lalu tidak ada yang selesai.

Urutan di `04-Architecture.md` sengaja disusun agar **setiap tahap menghasilkan
sesuatu yang bisa dimainkan**. Setelah Tahap 2 kalian sudah punya sesuatu yang
bisa ditunjukkan. Jangan pernah berada dalam kondisi "semua 70% jadi".

**Aturan praktis:** kalau di tengah jalan harus memotong, potong **isi**
(jumlah bahan/pelanggan), jangan potong **sistem**. Game dengan 6 bahan yang
sistemnya utuh jauh lebih baik daripada game dengan 12 bahan yang pancinya belum
jalan.

---

## Yang Paling Berisiko

| Item | Kenapa berisiko | Turunkan risikonya dengan |
|---|---|---|
| Multitasking puzzle ⇄ panci | Belum pernah diuji, bisa jadi terlalu kacau | Bangun panci 1 slot dulu, uji rasanya |
| Generator ampas | Bisa menghasilkan puzzle mustahil | Tulis pengecek kelayakan sejak awal |
| Keseimbangan ekonomi | Butuh banyak playtest | Taruh semua angka di satu file konstanta |
| Kualitas tulisan dialog | Menentukan nilai edukatif | Tulis semua dialog **sebelum** implementasi |

---

## Pembagian Kerja (saran)

| Peran | Fokus |
|---|---|
| **Programmer 1** | Fase puzzle (port dari Waste Crusher) |
| **Programmer 2** | Panci, pelanggan, day loop |
| **Artist** | Sprite bahan 16×16 → **prioritas tertinggi**, tanpa ini tak ada yang bisa dites |
| **Designer/Writer** | Dialog, tuning angka, riset akurasi |

**Catatan untuk artist:** bentuk block bahan harus **jelas terbaca dalam ukuran
16×16 per sel**. Uji keterbacaannya lebih awal — kalau pemain tidak bisa
membedakan kunyit dan temulawak sekilas, seluruh sistem deduksi runtuh.

---

## Checklist Presentasi Bootcamp

Yang perlu ditonjolkan saat demo:

- [ ] Tunjukkan **satu siklus penuh** tanpa terputus (pelanggan → deduksi → racik → rebus → bayar)
- [ ] Tekankan bahwa **khasiatnya nyata** — tunjukkan halaman Serat dengan nama latin & sumber
- [ ] Sebutkan **acaraki, pipisan & gandik, Prasasti Madhawapura** — bukti riset
- [ ] Sebutkan jamu sebagai **Warisan Budaya Takbenda UNESCO**
- [ ] Tunjukkan disclaimer — tanda tanggung jawab
- [ ] Siapkan jawaban untuk: *"Apa yang pemain pelajari?"*
      → **"Fungsi 12 tanaman obat Indonesia, bukan hafalan nama jamu."**
