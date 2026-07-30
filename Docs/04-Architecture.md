# ACARAKI — Arsitektur Teknis

> Referensi kode: `d:/GameDev/bgdjam-2026` (Waste Crusher).
> Dokumen ini memetakan **apa yang disalin, apa yang diubah, apa yang baru.**

---

## Ringkasan Reuse

| Sistem Waste Crusher | Status | Keterangan |
|---|---|---|
| `Scripts/Core/grid_logic.gd` | **Salin apa adanya** | Logika grid murni, tanpa dependensi. Sudah sempurna |
| `Scripts/Core/compression.gd` | **Salin apa adanya** | Untuk alat Tumbuk |
| `Scripts/Data/block_data.gd` | **Extend** | Jadi basis `IngredientData` |
| `Scripts/Data/irregular_block_data.gd` | **Salin + extend** | `shape_mask` persis yang kita butuhkan |
| `Scripts/Components/block_piece.gd` | **Salin, ganti nama** | → `ingredient_piece.gd` |
| `Scripts/Components/landfill_grid.gd` | **Salin, ganti nama + ubah win** | → `kuali_grid.gd` |
| `Scripts/Components/drag_manager.gd` | **Salin apa adanya** | Input handling sudah matang |
| `Scripts/Components/machine.gd` | **Salin apa adanya** | Base class-nya bagus, template method |
| `Scripts/Components/cutter.gd` | **Salin, ganti nama** | → `pipisan.gd` |
| `Scripts/Components/hydraulic_press.gd` | **Salin, ganti nama** | → `lumpang.gd` |
| `Scripts/Components/melter.gd` | ❌ **Buang** | Diganti sistem panci yang sepenuhnya baru |
| `Scripts/Components/inventory_manager.gd` | **Ubah besar** | Jadi UI Serat (cookbook) |
| `Scripts/Game/level.gd` | ❌ **Tulis ulang** | Level-based → day-based endless |
| `Scripts/Autoloads/*` | **Salin** | EventBus, AudioGlobal, ScreenShake, EffectManager, SaveManager |
| Sistem level_select & 20 level scene | ❌ **Buang** | Tidak relevan untuk endless |

**Estimasi:** ~60% kode fase puzzle bisa dipakai ulang. Yang benar-benar baru
adalah **panci, customer, ekonomi, dan orkestrasi hari**.

---

## Struktur Folder

```
Assets/
  Ingredients/     sprite bahan (16×16 per sel)
  Characters/      sprite pelanggan + ekspresi
  Kitchen/         kuali, panci, pipisan, lumpang
  UI/  SFX/  BGM/
Resources/
  IngredientData/  *.tres — satu per bahan
  JamuRecipe/      *.tres — resep klasik
  CustomerData/    *.tres — karakter + varian dialog
Scripts/
  Autoloads/       EventBus, GameManager, AudioGlobal, SaveManager, ...
  Core/            grid_logic, compression, symptom_matcher, recipe_evaluator
  Data/            ingredient_data, jamu_recipe, customer_data, symptom
  Components/      kuali_grid, ingredient_piece, drag_manager, pipisan, lumpang,
                   panci, customer_queue, ...
  Game/            day_manager, order_controller, boon_screen
  UI/              serat_book, patience_bar, heat_slider, dialogue_box
Scenes/            cerminan Scripts/
Docs/              dokumen desain
```

---

## Lapisan Data (Resource)

### `ingredient_data.gd` — extends BlockData

```gdscript
@tool
class_name IngredientData extends IrregularBlockData

@export var ingredient_id: StringName        # &"brotowali"
@export var display_name: String             # "Brotowali"
@export var latin_name: String               # "Tinospora crispa"

## Gejala yang ditangani bahan ini
@export var treats: Array[Symptom.Code] = []

## Zona suhu ideal untuk perebusan (0.0 dingin – 1.0 sangat panas)
@export_range(0.0, 1.0) var heat_min: float = 0.3
@export_range(0.0, 1.0) var heat_max: float = 0.7

@export_range(0, 5) var bitterness: int = 0  # memengaruhi kepuasan
@export var educational_note: String         # ditampilkan di Serat
@export var source_url: String               # kejujuran akademis
```

**Kenapa extend `IrregularBlockData`, bukan `BlockData`:** semua bahan punya
bentuk khas (jahe bercabang, asam melengkung), jadi `shape_mask` selalu dipakai.
Kita mewarisi `is_compressible()`/`is_cuttable()` lalu **override** karena
sebagian bahan memang bisa dipotong.

### `symptom.gd`

```gdscript
class_name Symptom

enum Code {
    DEMAM, NYERI_SENDI, LEMAH, PENCERNAAN, BATUK, NAFSU_MAKAN,
    DINGIN, LUKA_DALAM, PIKIRAN, KULIT, HATI_LIVER, WANITA,
}

static func display_name(code: Code) -> String: ...
static func icon(code: Code) -> Texture2D: ...
```

### `customer_data.gd`

```gdscript
@tool
class_name CustomerData extends Resource

@export var customer_id: StringName
@export var display_name: String
@export var portrait: Texture2D
@export var base_patience: float = 60.0
@export var pay_multiplier: float = 1.0
@export var request_variants: Array[RequestVariant] = []
```

```gdscript
class_name RequestVariant extends Resource
@export_multiline var dialogue: String
@export var symptoms: Array[Symptom.Code] = []
@export var min_day: int = 1          # muncul mulai hari ke-
```

---

## Perubahan Kunci #1 — Kondisi Menang Kuali

Ini modifikasi paling penting dari Waste Crusher.

**Sebelumnya** (`landfill_grid.gd:132`):
```gdscript
func is_complete() -> bool:
    if not GridLogic.is_grid_full(grid): return false
    for id in placed_pieces:
        if placed_pieces[id].violated: return false
    return true
```

**Menjadi** (`kuali_grid.gd`):
```gdscript
## Kuali selesai bila penuh, tanpa pelanggaran, DAN meracik sesuatu yang berarti
func evaluate() -> BrewResult:
    if not GridLogic.is_grid_full(grid):
        return BrewResult.incomplete()
    for id in placed_pieces:
        if placed_pieces[id].violated:
            return BrewResult.violated()
    return RecipeEvaluator.evaluate(get_placed_ingredients(), current_order)
```

Perhatikan: hasilnya bukan lagi boolean menang/kalah, tapi **objek penilaian
bertingkat**. Ini yang memungkinkan "salah sedikit tetap dibayar sedikit".

### `recipe_evaluator.gd` (Core, static, mudah dites)

```gdscript
class_name RecipeEvaluator

static func evaluate(ingredients: Array[IngredientData],
                     order: Order) -> BrewResult:
    var covered: Dictionary = {}     # Symptom.Code -> bool
    var total_bitterness := 0
    var sweetness := 0

    for ing in ingredients:
        for s in ing.treats:
            covered[s] = true
        total_bitterness += ing.bitterness

    var hit := 0
    for s in order.symptoms:
        if covered.get(s, false): hit += 1

    var result := BrewResult.new()
    result.accuracy = float(hit) / maxi(order.symptoms.size(), 1)
    result.matched_recipe = _find_classic_recipe(ingredients)  # bonus
    result.palatability = _calc_palatability(total_bitterness, sweetness)
    return result
```

**Catatan desain:** semua logika penilaian ada di fungsi static tanpa node.
Artinya bisa diuji tanpa menjalankan game — penting karena ini sistem yang paling
sering perlu di-tuning.

---

## Perubahan Kunci #2 — Sistem Panci (Baru)

Ini **bukan** turunan `Melter`. Tulis dari nol.

```gdscript
class_name Panci extends Node2D

signal brew_ready(slot: int, brew: Brew)
signal brew_burnt(slot: int, brew: Brew)

@export var slot_count: int = 1              # upgradeable → 4
@export var heat: float = 0.5:               # 0.0 dingin – 1.0 sangat panas
    set(v):
        heat = clampf(v, 0.0, 1.0)
        _update_flame_visual()

var slots: Array[Brew] = []

func _process(delta: float) -> void:
    for brew in slots:
        if not brew or brew.is_done: continue

        if brew.is_heat_ideal(heat):
            brew.doneness += brew.cook_rate * delta
        else:
            brew.doneness += brew.cook_rate * delta * 0.35   # tetap maju, lambat

        if heat > brew.heat_max:
            brew.burn += (heat - brew.heat_max) * delta * BURN_RATE

        if brew.burn >= 1.0:
            brew_burnt.emit(...)
        elif brew.doneness >= 1.0:
            brew_ready.emit(...)
```

**Zona ideal satu racikan** = irisan dari zona semua bahannya:

```gdscript
func compute_heat_window(ingredients: Array[IngredientData]) -> Vector2:
    var lo := 0.0
    var hi := 1.0
    for ing in ingredients:
        lo = maxf(lo, ing.heat_min)
        hi = minf(hi, ing.heat_max)
    return Vector2(lo, hi)     # bila lo > hi → jendelanya sempit/mustahil
```

Ini menghasilkan konsekuensi desain yang **muncul sendiri tanpa diprogram
khusus**: mencampur bahan dengan kebutuhan suhu berbeda mempersempit jendela.
Pemain belajar bahwa **kombinasi bahan punya biaya**, bukan karena kita menulis
aturan khusus, tapi karena datanya memang begitu.

### ⚠️ Pelajaran dari prototype: `heat_flexible`

Versi pertama membuat **semua** bahan mempersempit jendela suhu. Hasil simulasi:
**27 dari 32 racikan punya jendela yang mustahil** — mekanik apinya mati total.

Penyebabnya beras. Karena bentuknya 1×1, beras dipakai sebagai pengisi celah di
hampir setiap racikan, dan zona dinginnya (0.0–0.4) bentrok dengan semua bahan
panas.

Solusinya: bahan pengisi dan pemanis (**beras, gula jawa, asam jawa**) diberi flag
`heat_flexible = true` dan **tidak ikut mempersempit jendela**. Ditambah pelebaran
zona beberapa bahan agar tetap beririsan tipis, hasilnya turun ke **0 dari 32**.

Jendela tetap sempit — mis. jahe merah + kencur = 0.55–0.70 — jadi ketegangan
kompromi tetap ada, tapi pemain tidak pernah dihukum karena pilihan yang masuk
akal.

> **Prinsip umum:** bahan yang muncul di hampir semua racikan tidak boleh punya
> constraint keras. Kalau nanti menambah bahan pengisi baru, tandai
> `heat_flexible`.

---

## Perubahan Kunci #3 — Orkestrasi Hari

`level.gd` dibuang, diganti tiga node yang tanggung jawabnya jelas:

```
DayManager       — timer hari, kurva kesulitan, transisi pagi/siang/malam
OrderController  — antrean pelanggan, spawn, kesabaran, penilaian & bayaran
KualiSession     — satu sesi puzzle (reset kuali, generate ampas, pilih bahan)
```

```gdscript
class_name DayManager extends Node

signal day_started(day: int)
signal day_ended(day: int, earnings: int)

@export var day_duration: float = 300.0
@export var reading_time_scale: float = 0.2   # timer melambat saat membaca

var day: int = 1
var time_left: float
var is_reading: bool = false     # true saat dialog/Serat terbuka

func _process(delta: float) -> void:
    var scale := reading_time_scale if is_reading else 1.0
    time_left -= delta * scale
    if time_left <= 0.0:
        _end_day()
```

`is_reading` adalah implementasi langsung dari solusi Masalah #2 di GDD — timer
menghukum eksekusi lambat, bukan berpikir lambat.

---

## Generator Ampas (Blocker)

```gdscript
class_name ResidueGenerator

## Ampas bertambah seiring hari, tapi selalu menyisakan ruang yang cukup
static func generate(grid: Dictionary, day: int, rng: RandomNumberGenerator,
                     required_area: int) -> Array[Vector2i]:
    var total := grid.size()
    var target := mini(
        int(total * clampf(0.05 + day * 0.02, 0.0, 0.30)),
        total - required_area - 2          # jaminan selalu bisa diselesaikan
    )
    ...
```

**Aturan mutlak:** ampas tidak boleh membuat pesanan mustahil. Selalu sisakan
ruang ≥ luas bahan wajib + 2 sel kelonggaran. Puzzle yang tidak bisa diselesaikan
akan langsung membunuh kepercayaan pemain.

Bila memungkinkan, jalankan **solver cepat** untuk memverifikasi kelayakan
sebelum sesi dimulai (backtracking pada grid ≤100 sel itu murah).

---

## EventBus

Perluas milik Waste Crusher:

```gdscript
# Puzzle (warisan)
signal ingredient_placed(piece, grid_pos)
signal ingredient_removed(piece)
signal kuali_complete(result: BrewResult)

# Panci (baru)
signal brew_started(slot: int)
signal brew_ready(slot: int)
signal brew_burnt(slot: int)
signal heat_changed(value: float)

# Pelanggan (baru)
signal customer_arrived(data: CustomerData, order: Order)
signal customer_served(data: CustomerData, payment: int, accuracy: float)
signal customer_left_angry(data: CustomerData)

# Hari (baru)
signal day_started(day: int)
signal day_ended(day: int, earnings: int)
signal boon_selected(boon: BoonData)
```

---

## Urutan Implementasi

Bertahap, tiap tahap **bisa dimainkan** — jangan bangun semuanya lalu integrasi
di akhir.

### Tahap 1 — Fondasi Puzzle (paling berisiko dulu)
1. Salin `grid_logic.gd`, `compression.gd` apa adanya
2. Port `block_piece` → `ingredient_piece`, `landfill_grid` → `kuali_grid`
3. Port `drag_manager` apa adanya
4. Buat 3 `IngredientData` untuk uji coba
5. **Target: bisa drag bahan ke kuali dan mengisinya penuh**

### Tahap 2 — Pesanan & Penilaian
6. `Symptom`, `Order`, `RecipeEvaluator`
7. Satu pelanggan hardcoded, dialog statis
8. **Target: satu siklus penuh — pesan → racik → dinilai**

### Tahap 3 — Panci
9. `Panci` + `HeatSlider` + bar kematangan
10. **Target: jamu bisa direbus sampai matang/gosong**

### Tahap 4 — Loop Hari
11. `DayManager`, `OrderController`, antrean & kesabaran
12. **Target: satu hari penuh bisa dimainkan**

### Tahap 5 — Progresi
13. Ekonomi, layar boon, ampas bertambah
14. Serat (cookbook) lengkap dengan pencarian berdasarkan gejala

### Tahap 6 — Isi & Polish
15. 12 bahan, 8 pelanggan, semua varian dialog
16. Audio, partikel, screen shake (salin `EffectManager`/`ScreenShake`)

---

## Catatan Versi

Waste Crusher pakai **Godot 4.6**, proyek ini **4.7**. Format `.tscn` berbeda
(`format=4`, ada `unique_id`). **Jangan salin file `.tscn` langsung** — buat ulang
scene di editor 4.7. Skrip `.gd` aman disalin.
