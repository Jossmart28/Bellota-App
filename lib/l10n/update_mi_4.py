import json

arb_file = "app_mi.arb"

updates = {
    # symptom screen header
    "symptomsAndActionsLogSymptoms": "Naiwa ulbanka",
    "symptomsAndActionsLoggedSymptoms": "Ulbi mangkan kan nani",
    "symptomsAndActionsNoEntriesDay": "Naiwa ulbanka pain ba. Witin ba ulbi mangkaia butunka ba tilara tama.",
    "symptomsAndActionsNoSymptomsLogged": "Trabilka nani ulbi mangkan pain ba.",
    "symptomsAndActionsPeriodStart": "Kati iwaia takwakanka",
    "symptomsAndActionsLastPeriodStart": "Bui kati iwaia takwakanka",
    "symptomsAndActionsExpectedSymptoms": "Trabilka nani sip takaia",
    "symptomsAndActionsNextPeriodWillBe": "Kaunwan katim ba...",
    "symptomsAndActionsBasedOnLastCycles": "Yawan bui kati nani ra mina munan.",

    # selected count
    "registrationFormSelectedCount": "alkiwan nani",
    "registrationFormAddSymptom": "Tanka",

    # emotional symptoms
    "registrationFormIrritability": "Alki prukan",
    "registrationFormSadness": "Sinska wiliwi",
    "registrationFormCryingEasily": "Wih wihwia",
    "registrationFormConcentrationDifficulty": "Lukanka kakaira",
    "registrationFormLowSelfEsteem": "Uplika dukiara yamni kaikanka pain",
    "registrationFormMoodSwings": "Sinska chins takanka",
    "registrationFormAnxiety": "Sin sin daukan",
    "registrationFormExtremeFatigue": "Sip ai prui kaka",
}

with open(arb_file, 'r', encoding='utf-8') as f:
    data = json.load(f)

for k, v in updates.items():
    data[k] = v

with open(arb_file, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
print("Updated successfully!")
