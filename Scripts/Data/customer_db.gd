extends Node

## Autoload: the 8 customers and their dialogue variants.
## See Docs/03-Customers.md. Rule: never name a jamu in dialogue.
##
## Severity (4th arg of V.create) is the potency each symptom demands, in
## grid cells. It is authored to MATCH THE WORDS: "melilit parah" asks for
## more than "perutku tak nyaman". The player who reads carefully can
## estimate the dose before the bar confirms it — which is the whole point.
## Left blank, a symptom defaults to 1.

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
				[S.DEMAM, S.KULIT], 1, {S.DEMAM: 4, S.KULIT: 2}),
			V.create("Besok berbaris jauh. Kakiku sudah ngilu dari kemarin, dan aku kurang tenaga.",
				[S.NYERI_SENDI, S.LEMAH], 1, {S.NYERI_SENDI: 3, S.LEMAH: 3}),
			V.create("Semalam jaga di menara, anginnya menusuk. Sekarang dadaku sesak dan batuk.",
				[S.DINGIN, S.BATUK], 1, {S.DINGIN: 3, S.BATUK: 3}),
			V.create("Aku jatuh dari kuda. Tidak patah, tapi memar di mana-mana dan pinggangku kaku.",
				[S.LUKA_DALAM, S.NYERI_SENDI], 4, {S.LUKA_DALAM: 4, S.NYERI_SENDI: 4}),
		]),

		_make(&"nyai_sekar", "Nyai Sekar", "Pedagang Kain", Color("c46f9f"), 55.0, 1.4, [
			V.create("Bulanan datang lagi. Perutku melilit tapi lapak tak bisa kutinggal.",
				[S.WANITA, S.NYERI_SENDI], 1, {S.WANITA: 4, S.NYERI_SENDI: 3}),
			V.create("Seharian berdiri, pinggangku mau patah. Dan aku belum makan sejak subuh.",
				[S.NYERI_SENDI, S.NAFSU_MAKAN], 1, {S.NYERI_SENDI: 4, S.NAFSU_MAKAN: 2}),
			V.create("Suaraku habis menawar sejak pagi. Tenggorokanku kering.",
				[S.BATUK], 1, {S.BATUK: 2}),
			V.create("Aku ingin badanku tetap ramping seperti dulu. Ada yang bisa membantu?",
				[S.PENCERNAAN, S.KULIT], 4, {S.PENCERNAAN: 4, S.KULIT: 3}),
		]),

		_make(&"ki_wanata", "Ki Wanata", "Petani Tua", Color("7f8f5a"), 90.0, 0.7, [
			V.create("Sendi-sendiku berbunyi tiap pagi. Umur, katanya.",
				[S.NYERI_SENDI], 1, {S.NYERI_SENDI: 2}),
			V.create("Mataku menguning kata istriku. Badanku lemas terus.",
				[S.HATI_LIVER, S.LEMAH], 1, {S.HATI_LIVER: 5, S.LEMAH: 3}),
			V.create("Sudah tiga hari perutku kembung. Makan pun tak enak.",
				[S.PENCERNAAN, S.NAFSU_MAKAN], 1, {S.PENCERNAAN: 4, S.NAFSU_MAKAN: 3}),
			V.create("Sawah masih menunggu, tapi tenagaku tak seperti dulu.",
				[S.LEMAH, S.NYERI_SENDI], 1, {S.LEMAH: 4, S.NYERI_SENDI: 2}),
		]),

		_make(&"dyah_pramesti", "Dyah Pramesti", "Putri Bangsawan", Color("b09fd4"), 30.0, 2.0, [
			# PIKIRAN needs kayu manis, which unlocks on day 4.
			V.create("Semalam aku terjaga hingga ayam berkokok. Pikiranku tak mau diam.",
				[S.PIKIRAN], 4, {S.PIKIRAN: 3}),
			V.create("Wajahku... ada yang tak beres. Aku malu menghadap ayahanda.",
				[S.KULIT], 1, {S.KULIT: 3}),
			V.create("Perutku tak nyaman sejak perjamuan semalam. Aku tak berselera.",
				[S.PENCERNAAN, S.NAFSU_MAKAN], 1, {S.PENCERNAAN: 2, S.NAFSU_MAKAN: 2}),
			V.create("Aku harus tampil di perjamuan besok. Aku ingin terlihat segar dan bercahaya.",
				[S.KULIT, S.PENCERNAAN], 3, {S.KULIT: 4, S.PENCERNAAN: 3}),
			V.create("Makanan istana terlalu berat. Perutku memberontak.",
				[S.PENCERNAAN, S.HATI_LIVER], 4, {S.PENCERNAAN: 5, S.HATI_LIVER: 3}),
		]),

		_make(&"tuan_li", "Tuan Li", "Pedagang Tiongkok", Color("d4c46f"), 60.0, 1.5, [
			V.create("Laut... perut tidak enak. Banyak goyang.",
				[S.PENCERNAAN], 1, {S.PENCERNAAN: 3}),
			V.create("Dingin di kapal. Batuk tidak berhenti.",
				[S.DINGIN, S.BATUK], 1, {S.DINGIN: 3, S.BATUK: 4}),
			V.create("Di negeriku ada akar kuning untuk ini. Di sini ada?  (menunjuk sendinya)",
				[S.NYERI_SENDI], 3, {S.NYERI_SENDI: 4}),
		]),

		_make(&"mbok_darmi", "Mbok Darmi", "Jamu Gendong", Color("9fc46f"), 80.0, 0.8, [
			V.create("Aku kehabisan bahan di jalan, Nak. Bakulku berat, punggungku protes.",
				[S.NYERI_SENDI, S.LEMAH], 1, {S.NYERI_SENDI: 3, S.LEMAH: 3}),
			V.create("Keliling sejak subuh, kena angin terus. Hidungku tak berhenti.",
				[S.DINGIN, S.BATUK], 1, {S.DINGIN: 4, S.BATUK: 3}),
			V.create("Buatkan aku yang pahit, biar kuingat rasa buatan ibuku dulu.",
				[S.KULIT, S.HATI_LIVER], 3, {S.KULIT: 4, S.HATI_LIVER: 4}),
		]),

		# Raka is a child: small doses. He is also the gentlest introduction
		# to potency, which is why his numbers stay near 1-2.
		_make(&"raka", "Raka", "Anak Kecil", Color("6fc4d4"), 35.0, 0.5, [
			V.create("Kata Ibu... anu... adikku tidak mau makan. Terus kurus. Itu saja.",
				[S.NAFSU_MAKAN], 1, {S.NAFSU_MAKAN: 2}),
			V.create("Ibu bilang buatkan yang pahit. Aku tidak mau tapi harus.",
				[S.KULIT, S.PENCERNAAN], 1, {S.KULIT: 2, S.PENCERNAAN: 2}),
			V.create("Perutku sakit. Aku makan mangga muda banyak sekali tadi.",
				[S.PENCERNAAN], 1, {S.PENCERNAAN: 3}),
		]),

		_make(&"empu_gandring", "Empu Gandring", "Pandai Besi", Color("8a8a9f"), 50.0, 1.2, [
			# PIKIRAN (kayu manis) and LUKA_DALAM (daun sirih) unlock on day 4.
			V.create("Seharian di depan bara. Tenggorokanku kering dan kepalaku berdenyut.",
				[S.BATUK, S.PIKIRAN], 4, {S.BATUK: 3, S.PIKIRAN: 3}),
			V.create("Percikan besi kena tanganku. Perih dan mulai bengkak.",
				[S.KULIT, S.LUKA_DALAM], 4, {S.KULIT: 3, S.LUKA_DALAM: 3}),
			V.create("Bara membuat tenggorokanku kering seharian.",
				[S.BATUK], 1, {S.BATUK: 3}),
			V.create("Punggungku kaku dari menempa. Tapi pesanan tak boleh telat.",
				[S.NYERI_SENDI, S.LEMAH], 1, {S.NYERI_SENDI: 4, S.LEMAH: 3}),
		]),
	]
