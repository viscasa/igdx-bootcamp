class_name Symptom

## The 12 symptom codes that drive the deduction system.
## Customers complain in symptoms; ingredients treat symptoms.
## See Docs/02-Ingredients.md.

enum Code {
	DEMAM,        ## fever, hot body
	NYERI_SENDI,  ## joint / muscle ache
	LEMAH,        ## weakness, no stamina
	PENCERNAAN,   ## digestion, bloating, nausea
	BATUK,        ## cough, phlegm, sore throat
	NAFSU_MAKAN,  ## no appetite
	DINGIN,       ## cold, chills, masuk angin
	LUKA_DALAM,   ## bruises, internal injury
	PIKIRAN,      ## insomnia, anxiety, headache
	KULIT,        ## itching, acne, skin
	HATI_LIVER,   ## liver trouble
	WANITA,       ## menstrual cramps; legacy identifier kept for compatibility
}

const NAMES := {
	Code.DEMAM: "Demam",
	Code.NYERI_SENDI: "Nyeri Sendi",
	Code.LEMAH: "Lemah",
	Code.PENCERNAAN: "Pencernaan",
	Code.BATUK: "Batuk",
	Code.NAFSU_MAKAN: "Nafsu Makan",
	Code.DINGIN: "Dingin",
	Code.LUKA_DALAM: "Luka Dalam",
	Code.PIKIRAN: "Pikiran",
	Code.KULIT: "Kulit",
	Code.HATI_LIVER: "Hati",
	Code.WANITA: "Nyeri Haid",
}

## Placeholder colors so the prototype reads clearly without art.
const COLORS := {
	Code.DEMAM: Color("e05a4f"),
	Code.NYERI_SENDI: Color("b06fc4"),
	Code.LEMAH: Color("d89b3c"),
	Code.PENCERNAAN: Color("6fa84f"),
	Code.BATUK: Color("5aa8c4"),
	Code.NAFSU_MAKAN: Color("d4763c"),
	Code.DINGIN: Color("7f9fd4"),
	Code.LUKA_DALAM: Color("a05656"),
	Code.PIKIRAN: Color("8f7fc4"),
	Code.KULIT: Color("c4a05a"),
	Code.HATI_LIVER: Color("6f8f5a"),
	Code.WANITA: Color("d47f9f"),
}

## What a customer says when the player asks a follow-up question. These are
## deliberately clues, not labels: the player still has to interpret the
## answer and pin their own diagnosis on the order.
const CLUES := {
	Code.DEMAM: "Panasnya menetap bahkan saat malam, dan aku berkeringat.",
	Code.NYERI_SENDI: "Sakitnya paling terasa ketika sendi dan otot kugerakkan.",
	Code.LEMAH: "Tenagaku cepat habis meski baru melakukan sedikit pekerjaan.",
	Code.PENCERNAAN: "Perutku kembung, melilit, atau mual setelah makan.",
	Code.BATUK: "Tenggorokanku mengganjal dan kadang mengeluarkan dahak.",
	Code.NAFSU_MAKAN: "Makanan ada di depan mata, tetapi aku sama sekali tak berselera.",
	Code.DINGIN: "Aku menggigil dan ingin terus mendekap sesuatu yang hangat.",
	Code.LUKA_DALAM: "Tidak ada luka terbuka, tetapi bagian dalamnya memar dan berdenyut.",
	Code.PIKIRAN: "Tubuhku lelah, tetapi pikiranku terus berputar dan sulit tenang.",
	Code.KULIT: "Keluhannya terlihat di permukaan: gatal, kemerahan, atau beruntusan.",
	Code.HATI_LIVER: "Mataku tampak menguning dan tubuhku terus terasa tidak bugar.",
	Code.WANITA: "Aku sedang datang bulan. Perut bawahku kram seperti biasanya.",
}

## Short descriptions used by the Serat's complaint index. Unlike CLUES these
## are reference knowledge, so being direct is useful and educational.
const DESCRIPTIONS := {
	Code.DEMAM: "kata kunci: panas, berkeringat, meriang malam",
	Code.NYERI_SENDI: "kata kunci: pegal, ngilu, kaku, habis kerja berat",
	Code.LEMAH: "kata kunci: lesu, tidak bertenaga, cepat capek",
	Code.PENCERNAAN: "kata kunci: mual, kembung, perut melilit, salah makan",
	Code.BATUK: "kata kunci: batuk, dahak, tenggorokan kering/sesak",
	Code.NAFSU_MAKAN: "kata kunci: tidak berselera, susah makan, kurus",
	Code.DINGIN: "kata kunci: menggigil, masuk angin, kena angin/kapal",
	Code.LUKA_DALAM: "kata kunci: memar, bengkak, jatuh, sakit tanpa luka",
	Code.PIKIRAN: "kata kunci: sulit tidur, gelisah, kepala/pikiran berputar",
	Code.KULIT: "kata kunci: gatal, kemerahan, beruntusan, wajah bermasalah",
	Code.HATI_LIVER: "kata kunci: mata menguning, badan tidak bugar lama",
	Code.WANITA: "kata kunci: datang bulan, kram perut bawah, nyeri yang berulang tiap bulan",
}


static func display_name(code: Code) -> String:
	return NAMES.get(code, "?")


static func color(code: Code) -> Color:
	return COLORS.get(code, Color.WHITE)


static func clue(code: Code) -> String:
	return CLUES.get(code, "Coba dengarkan lagi keluhannya.")


static func description(code: Code) -> String:
	return DESCRIPTIONS.get(code, "")
