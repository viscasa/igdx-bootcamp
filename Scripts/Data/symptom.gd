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
	WANITA,       ## menstrual / postpartum
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
	Code.WANITA: "Wanita",
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


static func display_name(code: Code) -> String:
	return NAMES.get(code, "?")


static func color(code: Code) -> Color:
	return COLORS.get(code, Color.WHITE)
