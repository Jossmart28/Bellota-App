import json
import os

arb_file = "app_mi.arb"

updates = {
    "registrationFormConfirm": "Kainara waia",
    "onboardingConfirm": "Kainara waia",
    "onboardingGotItLetsGo": "Kainara waia" # Let's translate other confirms
}

with open(arb_file, 'r', encoding='utf-8') as f:
    data = json.load(f)

for k, v in updates.items():
    data[k] = v

with open(arb_file, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
print("Updated successfully!")
