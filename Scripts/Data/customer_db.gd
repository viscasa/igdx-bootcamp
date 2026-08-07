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


func get_by_id(id: StringName) -> CustomerData:
	for c in all:
		if c.customer_id == id:
			return c
	return null


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
			V.create("Aku jaga gerbang semalaman. Badanku panas, dan bekas luka di lenganku gatal lagi.",
				[S.DEMAM, S.KULIT], 2, {S.DEMAM: 4, S.KULIT: 2}, [
					"Aku berkeringat terus, padahal tadi malam dingin.",
					"Kulit di sekitar lukanya merah dan gatal."
				]),
			V.create("Besok aku patroli lagi. Kaki pegal semua, tenaga juga cepat habis.",
				[S.NYERI_SENDI, S.LEMAH], 1, {S.NYERI_SENDI: 3, S.LEMAH: 3}, [
					"Lutut dan bahuku paling sakit kalau digerakkan.",
					"Angkat tombak sebentar saja sudah capek."
				]),
			V.create("Semalam aku kena angin di menara. Sekarang menggigil dan batuk terus.",
				[S.DINGIN, S.BATUK], 1, {S.DINGIN: 3, S.BATUK: 3}, [
					"Badanku rasanya dingin, walau sudah dekat api.",
					"Tenggorokanku gatal dan ada dahaknya."
				]),
			V.create("Aku jatuh dari kuda. Tidak berdarah, tapi badan dalamnya sakit dan pinggangku kaku.",
				[S.LUKA_DALAM, S.NYERI_SENDI], 4, {S.LUKA_DALAM: 4, S.NYERI_SENDI: 4}, [
					"Memarnya dalam, bukan luka terbuka.",
					"Pinggangku kaku saat membungkuk."
				]),
		]),

		_make(&"nyai_sekar", "Nyai Sekar", "Penjual Kain", Color("c46f9f"), 55.0, 1.4, [
			V.create("Hari ini daganganku ramai, tapi perut bawahku melilit. Pinggangku juga pegal.",
				[S.WANITA, S.NYERI_SENDI], 1, {S.WANITA: 4, S.NYERI_SENDI: 3}, [
					"Ini datang tiap bulan, biasanya begini.",
					"Pinggang dan pahaku ikut pegal."
				]),
			V.create("Aku berdiri dari subuh di pasar. Pinggang sakit, makan pun tidak berselera.",
				[S.NYERI_SENDI, S.NAFSU_MAKAN], 1, {S.NYERI_SENDI: 4, S.NAFSU_MAKAN: 2}, [
					"Rasa sakitnya di pinggang dan kaki.",
					"Aku belum ingin makan dari pagi."
				]),
			V.create("Aku banyak bicara ke pembeli. Sekarang suaraku serak dan tenggorokan kering.",
				[S.BATUK], 1, {S.BATUK: 2}, [
					"Tenggorokanku kering dan mengganjal."
				]),
			V.create("Besok aku harus ke istana. Perutku berat setelah makan banyak, wajahku juga kusam.",
				[S.PENCERNAAN, S.KULIT], 4, {S.PENCERNAAN: 4, S.KULIT: 3}, [
					"Perutku terasa penuh sejak makan besar.",
					"Wajahku muncul bintik merah."
				]),
		]),

		_make(&"ki_wanata", "Ki Wanata", "Petani Tua", Color("7f8f5a"), 90.0, 0.7, [
			V.create("Setiap pagi sendiku ngilu. Mungkin karena sudah tua, tapi hari ini lebih sakit.",
				[S.NYERI_SENDI], 1, {S.NYERI_SENDI: 2}, [
					"Sakitnya muncul saat sendi digerakkan."
				]),
			V.create("Istriku bilang mataku agak kuning. Badanku juga lemas terus.",
				[S.HATI_LIVER, S.LEMAH], 3, {S.HATI_LIVER: 5, S.LEMAH: 3}, [
					"Yang paling kelihatan: warna kuning di mata.",
					"Aku lemas berhari-hari, bukan sekadar mengantuk."
				]),
			V.create("Sudah tiga hari perutku kembung. Biasanya aku lahap, sekarang tidak ingin makan.",
				[S.PENCERNAAN, S.NAFSU_MAKAN], 1, {S.PENCERNAAN: 4, S.NAFSU_MAKAN: 3}, [
					"Perutku kembung dan melilit setelah makan.",
					"Aku kehilangan selera makan."
				]),
			V.create("Sawah masih harus dikerjakan, tapi tenagaku habis dan lututku pegal.",
				[S.LEMAH, S.NYERI_SENDI], 1, {S.LEMAH: 4, S.NYERI_SENDI: 2}, [
					"Tenagaku cepat habis saat memikul karung.",
					"Lututku ngilu sejak turun sawah."
				]),
		]),

		_make(&"dyah_pramesti", "Dyah Pramesti", "Putri Istana", Color("b09fd4"), 30.0, 2.0, [
			# PIKIRAN needs kayu manis, which unlocks on day 4.
			V.create("Aku tidak bisa tidur semalam. Kepalaku penuh pikiran sampai pagi.",
				[S.PIKIRAN], 4, {S.PIKIRAN: 3}, [
					"Tubuhku lelah, tapi kepala tak mau diam.",
					"Aku sulit tidur meski kamar sudah sunyi."
				]),
			V.create("Ada merah-merah di wajahku. Aku malu kalau harus bertemu orang istana.",
				[S.KULIT], 1, {S.KULIT: 3}, [
					"Keluhannya tampak di permukaan kulit."
				]),
			V.create("Aku makan terlalu banyak di pesta semalam. Perutku tidak enak dan aku tidak lapar.",
				[S.PENCERNAAN, S.NAFSU_MAKAN], 1, {S.PENCERNAAN: 2, S.NAFSU_MAKAN: 2}, [
					"Perut terasa berat setelah makan besar.",
					"Aku tak berselera sejak pagi."
				]),
			V.create("Besok aku tampil di balairung. Aku ingin wajahku segar dan perutku tidak berat.",
				[S.KULIT, S.PENCERNAAN], 3, {S.KULIT: 4, S.PENCERNAAN: 3}, [
					"Wajahku tampak kusam.",
					"Perutku terasa penuh dan lambat."
				]),
			V.create("Makanan istana terlalu berat. Perutku sakit, dan badanku terasa tidak enak.",
				[S.PENCERNAAN, S.HATI_LIVER], 4, {S.PENCERNAAN: 5, S.HATI_LIVER: 3}, [
					"Keluhannya mulai dari perut setelah makan besar.",
					"Badanku terasa tidak bugar sejak kemarin."
				]),
		]),

		_make(&"tuan_li", "Tuan Li", "Pedagang Kapal", Color("d4c46f"), 60.0, 1.5, [
			V.create("Aku baru turun dari kapal. Ombaknya besar sekali. Sekarang perutku masih mual.",
				[S.PENCERNAAN], 1, {S.PENCERNAAN: 3}, [
					"Rasanya mual sejak perjalanan laut tadi."
				]),
			V.create("Di kapal anginnya dingin. Sekarang aku menggigil dan batuk terus.",
				[S.DINGIN, S.BATUK], 1, {S.DINGIN: 3, S.BATUK: 4}, [
					"Badanku masih terasa dingin.",
					"Tenggorokan gatal dan batuk terus."
				]),
			V.create("Tanganku kaku setelah bongkar muatan kapal. Ada jamu untuk sendi?",
				[S.NYERI_SENDI], 3, {S.NYERI_SENDI: 4}, [
					"Yang sakit itu sendi jari dan lutut."
				]),
		]),

		_make(&"mbok_darmi", "Mbok Darmi", "Penjual Jamu", Color("9fc46f"), 80.0, 0.8, [
			V.create("Aku keliling jualan dari pagi. Punggungku sakit dan badanku lemas.",
				[S.NYERI_SENDI, S.LEMAH], 1, {S.NYERI_SENDI: 3, S.LEMAH: 3}, [
					"Nyeri paling terasa di punggung dan bahu.",
					"Tenagaku habis sebelum matahari tinggi."
				]),
			V.create("Tadi pagi aku kena angin terus di jalan. Sekarang menggigil dan batuk.",
				[S.DINGIN, S.BATUK], 1, {S.DINGIN: 4, S.BATUK: 3}, [
					"Aku menggigil setelah kena angin.",
					"Batuknya datang bersama tenggorokan gatal."
				]),
			V.create("Kulitku lagi merah dan gatal. Badanku juga terasa tidak enak dari dalam.",
				[S.KULIT, S.HATI_LIVER], 3, {S.KULIT: 4, S.HATI_LIVER: 4}, [
					"Di kulit terlihat merah dan gatal.",
					"Aku butuh yang membersihkan rasa tidak bugar dari dalam."
				]),
		]),

		# Raka is a child and should sound direct, nervous, and easy to read.
		_make(&"raka", "Raka", "Anak Desa", Color("6fc4d4"), 35.0, 0.5, [
			V.create("Kak... ibu nyuruh aku ke sini. Adikku susah makan. Nasi sudah disuapin juga tetap ditolak.",
				[S.NAFSU_MAKAN], 1, {S.NAFSU_MAKAN: 2}, [
					"Dia nggak panas, kak. Cuma kalau lihat makanan langsung geleng-geleng.",
					"Ibu bilang badannya makin kurus karena makannya sedikit."
				]),
			V.create("Ibu bilang aku harus minum jamu. Tapi jangan yang pahit banget ya... kulitku gatal, perutku juga sakit.",
				[S.KULIT, S.PENCERNAAN], 1, {S.KULIT: 2, S.PENCERNAAN: 2}, [
					"Gatalnya di tangan sama leher. Aku garuk terus.",
					"Perutku mulas sejak tadi pagi."
				]),
			V.create("Perutku sakit, kak. Aku makan mangga muda kebanyakan. Jangan bilang ibu ya.",
				[S.PENCERNAAN], 1, {S.PENCERNAAN: 3}, [
					"Rasanya mual dan melilit setelah makan yang asam.",
					"Aku nggak batuk, nggak panas. Cuma perutku yang rewel."
				]),
		]),

		_make(&"empu_gandring", "Empu Gandring", "Pandai Besi", Color("8a8a9f"), 50.0, 1.2, [
			# PIKIRAN (kayu manis) and LUKA_DALAM (daun sirih) unlock on day 4.
			V.create("Aku menempa sampai pagi. Asap tungku bikin tenggorokanku kering, kepalaku juga berat.",
				[S.BATUK, S.PIKIRAN], 4, {S.BATUK: 3, S.PIKIRAN: 3}, [
					"Tenggorokan kering karena asap dan batuk.",
					"Kepalaku tak tenang setelah kerja semalaman."
				]),
			V.create("Percikan besi kena tanganku. Kulitnya perih, dan bagian dalamnya terasa memar.",
				[S.KULIT, S.LUKA_DALAM], 4, {S.KULIT: 3, S.LUKA_DALAM: 3}, [
					"Kulitnya merah dan panas.",
					"Memarnya terasa di bawah kulit."
				]),
			V.create("Asap tungku membuat tenggorokanku kering sekali.",
				[S.BATUK], 1, {S.BATUK: 3}, [
					"Tenggorokan kering dan mengganjal."
				]),
			V.create("Punggungku kaku setelah menempa seharian. Tenagaku juga habis.",
				[S.NYERI_SENDI, S.LEMAH], 1, {S.NYERI_SENDI: 4, S.LEMAH: 3}, [
					"Punggung dan bahuku ngilu.",
					"Tenagaku terkuras setelah kerja bara."
				]),
		]),
	]
