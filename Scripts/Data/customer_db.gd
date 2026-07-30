extends Node

## Autoload: the 8 customers and their dialogue variants.
## See Docs/03-Customers.md. Rule: never name a jamu in dialogue.

const S := Symptom.Code

var all: Array[CustomerData] = []


func _ready() -> void:
	_build()


func pick_random(day: int, rng: RandomNumberGenerator) -> CustomerData:
	return all[rng.randi() % all.size()]


func _make(id: StringName, name_: String, role: String, col: Color,
		patience: float, pay: float, variants: Array) -> CustomerData:
	var c := CustomerData.new()
	c.customer_id = id
	c.display_name = name_
	c.role = role
	c.color = col
	c.base_patience = patience
	c.pay_multiplier = pay
	var typed: Array[RequestVariant] = []
	for v in variants:
		typed.append(v)
	c.variants = typed
	return c


func _build() -> void:
	var V := RequestVariant

	all = [
		_make(&"jayeng", "Jayeng", "Prajurit Muda", Color("a8563c"), 40.0, 1.0, [
			V.create("Badanku panas sejak semalam, dan bekas luka di lenganku gatal tak karuan.",
				[S.DEMAM, S.KULIT]),
			V.create("Besok berbaris jauh. Kakiku sudah ngilu dari kemarin, dan aku kurang tenaga.",
				[S.NYERI_SENDI, S.LEMAH]),
			V.create("Semalam jaga di menara, anginnya menusuk. Sekarang dadaku sesak dan batuk.",
				[S.DINGIN, S.BATUK]),
			V.create("Aku jatuh dari kuda. Tidak patah, tapi memar di mana-mana dan pinggangku kaku.",
				[S.LUKA_DALAM, S.NYERI_SENDI], 4),
		]),

		_make(&"nyai_sekar", "Nyai Sekar", "Pedagang Kain", Color("c46f9f"), 55.0, 1.4, [
			V.create("Bulanan datang lagi. Perutku melilit tapi lapak tak bisa kutinggal.",
				[S.WANITA, S.NYERI_SENDI]),
			V.create("Seharian berdiri, pinggangku mau patah. Dan aku belum makan sejak subuh.",
				[S.NYERI_SENDI, S.NAFSU_MAKAN]),
			V.create("Suaraku habis menawar sejak pagi. Tenggorokanku kering.",
				[S.BATUK]),
			V.create("Aku ingin badanku tetap ramping seperti dulu. Ada yang bisa membantu?",
				[S.PENCERNAAN, S.KULIT], 4),
		]),

		_make(&"ki_wanata", "Ki Wanata", "Petani Tua", Color("7f8f5a"), 90.0, 0.7, [
			V.create("Sendi-sendiku berbunyi tiap pagi. Umur, katanya.",
				[S.NYERI_SENDI]),
			V.create("Mataku menguning kata istriku. Badanku lemas terus.",
				[S.HATI_LIVER, S.LEMAH]),
			V.create("Sudah tiga hari perutku kembung. Makan pun tak enak.",
				[S.PENCERNAAN, S.NAFSU_MAKAN]),
			V.create("Sawah masih menunggu, tapi tenagaku tak seperti dulu.",
				[S.LEMAH, S.NYERI_SENDI]),
		]),

		_make(&"dyah_pramesti", "Dyah Pramesti", "Putri Bangsawan", Color("b09fd4"), 30.0, 2.0, [
			# PIKIRAN needs kayu manis, which unlocks on day 4.
			V.create("Semalam aku terjaga hingga ayam berkokok. Pikiranku tak mau diam.",
				[S.PIKIRAN], 4),
			V.create("Wajahku... ada yang tak beres. Aku malu menghadap ayahanda.",
				[S.KULIT]),
			V.create("Perutku tak nyaman sejak perjamuan semalam. Aku tak berselera.",
				[S.PENCERNAAN, S.NAFSU_MAKAN]),
			V.create("Aku harus tampil di perjamuan besok. Aku ingin terlihat segar dan bercahaya.",
				[S.KULIT, S.PENCERNAAN], 3),
			V.create("Makanan istana terlalu berat. Perutku memberontak.",
				[S.PENCERNAAN, S.HATI_LIVER], 4),
		]),

		_make(&"tuan_li", "Tuan Li", "Pedagang Tiongkok", Color("d4c46f"), 60.0, 1.5, [
			V.create("Laut... perut tidak enak. Banyak goyang.",
				[S.PENCERNAAN]),
			V.create("Dingin di kapal. Batuk tidak berhenti.",
				[S.DINGIN, S.BATUK]),
			V.create("Di negeriku ada akar kuning untuk ini. Di sini ada?  (menunjuk sendinya)",
				[S.NYERI_SENDI], 3),
		]),

		_make(&"mbok_darmi", "Mbok Darmi", "Jamu Gendong", Color("9fc46f"), 80.0, 0.8, [
			V.create("Aku kehabisan bahan di jalan, Nak. Bakulku berat, punggungku protes.",
				[S.NYERI_SENDI, S.LEMAH]),
			V.create("Keliling sejak subuh, kena angin terus. Hidungku tak berhenti.",
				[S.DINGIN, S.BATUK]),
			V.create("Buatkan aku yang pahit, biar kuingat rasa buatan ibuku dulu.",
				[S.KULIT, S.HATI_LIVER], 3),
		]),

		_make(&"raka", "Raka", "Anak Kecil", Color("6fc4d4"), 35.0, 0.5, [
			V.create("Kata Ibu... anu... adikku tidak mau makan. Terus kurus. Itu saja.",
				[S.NAFSU_MAKAN]),
			V.create("Ibu bilang buatkan yang pahit. Aku tidak mau tapi harus.",
				[S.KULIT, S.PENCERNAAN]),
			V.create("Perutku sakit. Aku makan mangga muda banyak sekali tadi.",
				[S.PENCERNAAN]),
		]),

		_make(&"empu_gandring", "Empu Gandring", "Pandai Besi", Color("8a8a9f"), 50.0, 1.2, [
			# PIKIRAN (kayu manis) and LUKA_DALAM (daun sirih) unlock on day 4.
			V.create("Seharian di depan bara. Tenggorokanku kering dan kepalaku berdenyut.",
				[S.BATUK, S.PIKIRAN], 4),
			V.create("Percikan besi kena tanganku. Perih dan mulai bengkak.",
				[S.KULIT, S.LUKA_DALAM], 4),
			V.create("Bara membuat tenggorokanku kering seharian.",
				[S.BATUK]),
			V.create("Punggungku kaku dari menempa. Tapi pesanan tak boleh telat.",
				[S.NYERI_SENDI, S.LEMAH]),
		]),
	]
