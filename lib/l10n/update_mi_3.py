import json
import os

arb_file = "app_mi.arb"

updates = {
    "privacyPolicyAcceptText": "Aisi kaikri bara yamni kaikisna baksakan sturka palitik ka ulbanka ba wal",
    "privacyPolicyContinue": "Kainara waia",
    "birthYearContinue": "Kainara waia",
    "onboardingContinue": "Kainara waia",
    "languageScreenContinue": "Kainara waia",
    "registerContinue": "Kainara waia",
    "loginContinue": "Kainara waia"
}

with open(arb_file, 'r', encoding='utf-8') as f:
    data = json.load(f)

for k, v in updates.items():
    if k in data or "Continue" in k or k == "privacyPolicyAcceptText":
        data[k] = v

with open(arb_file, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
print("Updated successfully!")
