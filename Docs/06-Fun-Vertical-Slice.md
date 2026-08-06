# ACARAKI — Fun-First Vertical Slice

Dokumen ini mencatat perubahan prototype setelah review gameplay. GDD inti tetap
menjadi sumber visi; vertical slice ini sengaja dibatasi menjadi **lima hari**
agar mempunyai awal, eskalasi, dan kemenangan yang bisa didemokan dalam satu sesi.

## Pilar yang Sekarang Dimainkan

1. **Dengarkan:** figur pelanggan tidak membocorkan label gejala.
2. **Diagnosis:** pemain menulis 1–3 dugaan dan boleh membeli kepastian dengan
   waktu melalui petunjuk lanjutan.
3. **Belajar:** `F` membuka Serat Wulandari. Waktu melambat agar membaca tidak
   dihukum, tetapi tidak berhenti total.
4. **Optimasi:** racikan dinilai dari khasiat, presisi dosis, rasa, kematangan,
   biaya bahan, dan resep warisan.
5. **Eksekusi:** botol tidak otomatis diangkat. Pemain harus menariknya keluar
   ketika matang sambil mengelola satu api untuk beberapa slot.
6. **Progresi:** duit dibelanjakan sekali pada akhir hari untuk mengubah build run.

## Struktur Lima Hari

| Hari | Tema | Eskalasi |
|---|---|---|
| 1 | Hari Pertama | Raka menjadi order tutorial satu gejala |
| 2 | Angin Muson | Dingin dan batuk lebih sering |
| 3 | Pasar Besar | Pencernaan dan nafsu makan lebih sering; panci bertambah |
| 4 | Tamu dari Penjuru | Empat bahan lanjutan terbuka |
| 5 | Penilaian Kedai | Keluhan majemuk berbobot lebih tinggi; run berakhir |

Setiap hari memberi bonus duit bila target racikan sempurna tercapai. Setelah
timer habis, shift benar-benar berhenti pada layar ritual/persiapan—tidak langsung
meloncat ke hari berikutnya.

## Penggunaan Duit

- **Pipisan Terasah:** +1 penggunaan per hari.
- **Teh Penyambut:** kesabaran pelanggan +12%.
- **Tungku Baru:** zona suhu setiap jamu lebih lebar.
- **Papan Nama Kedai:** bayaran dasar bertambah.
- **Cuci Kuali:** jumlah ampas berkurang.
- **Meditasi:** pilihan gratis untuk lanjut tanpa upgrade.

## Resep Warisan

Kunyit Asam, Beras Kencur, Wedang Jahe, dan Pahitan adalah penemuan opsional.
Resep klasik memberi bonus 18%, membuka nama di Serat, tetapi tidak menggantikan
sistem racikan personal. Pelanggan tetap dinilai berdasarkan kondisi mereka.

## Hipotesis Playtest

Vertical slice dianggap berhasil bila pemain baru:

- mengantar jamu pertama tanpa penjelasan lisan dalam tiga menit;
- dapat menjelaskan mengapa ia memilih bahan tersebut;
- memakai pipisan karena mengejar `1/1`, bukan karena disuruh;
- mengubah api setidaknya sekali ketika dua botol mempunyai target berbeda;
- mengingat minimal tiga khasiat tanaman setelah bermain;
- memilih melanjutkan ke hari berikutnya tanpa diminta.

Jika pemain gagal, potong beban diagnosis atau perpanjang kesabaran dahulu.
Jangan menambah bahan, alat, atau ruangan sebelum loop ini terbukti.
