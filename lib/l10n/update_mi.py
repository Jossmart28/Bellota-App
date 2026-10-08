import json
import os

arb_file = "app_mi.arb"

updates = {
    "calendarJan": "Siakwa kati",
    "calendarFeb": "Kuswa kati",
    "calendarMar": "Kakamuk kati",
    "calendarApr": "Lih wauhni kati",
    "calendarMay": "Lih mairin kati",
    "calendarJun": "Li kati",
    "calendarJul": "Pastara kati",
    "calendarAug": "Sikla kati",
    "calendarSep": "Wis kati",
    "calendarOct": "Waupasa kati",
    "calendarNov": "Yahbra kati",
    "calendarDec": "Krismis kati",
    "registrationFormCancel": "Dakbaia",
    "registrationFormPeriodStarts": "Kati iwaia takwakanka",
    "registrationFormSymptoms": "Trabilka nani",
    "registrationFormVaginalFlow": "Mairin wina wina laya takanka",
    "registrationFormSex": "Mairin ar waitna sapa",
    "registrationFormBleedingPattern": "Nahki pit talia plapi ba",
    "registrationFormPainAndSymptoms": "Latwan bara trabilka wala nani",
    "registrationFormNotes": "Uplika dukiara ulbanka nani",
    "registrationFormNotesHint": "Naiwa diara mai takan nani ba uls",
    "registrationFormLogProgress": "Ulbi mangkan ka kainara",
    "registrationFormComplete": "Sut aslika",
    "registrationFormPartial": "Piska kum baman",
    "registrationFormSaveLog": "Ulbi mangkan kan sunaia",
    "registrationFormSaved": "Pat ulbi mangkan",
    "symptomsAndActionsRecentPeriodError": "Pat katka iwanka kum takwakansa",

    "registrationFormWholeBody": "Wina aiska",
    "registrationFormHead": "Lal",
    "registrationFormAbdomen": "Biara",
    "registrationFormOther": "Wala",
    "registrationFormEmotional": "Sinska darawalanka",
    "registrationFormDigestive": "Klunghka tanira",

    "registrationFormFever": "Rihka",
    "registrationFormBodyAche": "Wina aiska latwanka",
    "registrationFormGeneralDistension": "Wina aiska puskanka",
    "registrationFormLowerBackPain": "Nina dusa latwan ka",
    "registrationFormLegCramps": "Kuhma ra sula wakia aubanka",
    "registrationFormAppetiteChanges": "Plun piaia natka chins takanka",
    "registrationFormCravings": "Diara pin dauki nani ba",
    "registrationFormWaterRetention": "Wina ra li alki takaskanka",
    "registrationFormNightSweats": "Tihmia ra laptika takanka",
    "registrationFormPalpitations": "Kupia isti prukanka",
    "registrationFormDizziness": "Bladaukanka",
    "registrationFormHotFlashes": "Winka prakaia munanka",
    "registrationFormJointPain": "Dusa wilkanka nani latwanka",
    "registrationFormBloating": "Puskan",
    "registrationFormNausea": "Aikabanka",
    "registrationFormPelvicPain": "Maisa tani latwanka",

    "registrationFormHeadache": "Lal klahwan",
    "registrationFormVertigo": "Bla daukanka",
    "registrationFormInsomnia": "Sip yapras",
    "registrationFormVomiting": "Aikaban",
    "registrationFormAcne": "Umala",

    "registrationFormAbdominalPain": "Biara klahwanka",
    "registrationFormAbdominalDistension": "Biara puskan baku sin plauya puskan",
    "registrationFormDiarrhea": "Biara sakan",
    "registrationFormConstipation": "Kanka karna takan trabilka",

    "registrationFormBreastTenderness": "Tialka trabilka",
    "registrationFormAbnormalDischarge": "Mairin wina wina laya takanka",
    "registrationFormSpotting": "Talia baiwanka"
}

with open(arb_file, 'r', encoding='utf-8') as f:
    data = json.load(f)

for k, v in updates.items():
    data[k] = v

with open(arb_file, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
print("Updated successfully!")
