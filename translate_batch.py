#!/usr/bin/env python3
"""Batch translate ARB from Chinese to Thai & Vietnamese using batched API calls."""
import json
import sys

try:
    from deep_translator import GoogleTranslator
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "deep-translator", "-q"])
    from deep_translator import GoogleTranslator

with open("lib/l10n/app_zh.arb", "r", encoding="utf-8") as f:
    zh_data = json.load(f)

# Collect translatable entries preserving order
keys = []
values = []
for k, v in zh_data.items():
    if k.startswith("@") or k == "@@locale":
        continue
    keys.append(k)
    values.append(v)

print(f"Translating {len(values)} entries...")

# Batch translate: join with a unique separator
SEP = "\n|||SEP|||\n"
def translate_batch(source_lang, target_lang, texts, label):
    translator = GoogleTranslator(source=source_lang, target=target_lang)
    combined = SEP.join(texts)
    try:
        result = translator.translate(combined)
        translated = result.split(SEP)
        if len(translated) != len(texts):
            print(f"  WARNING: {label} count mismatch: {len(translated)} vs {len(texts)}")
            # Fall back to individual
            translated = []
            for t in texts:
                try:
                    translated.append(translator.translate(t))
                except:
                    translated.append(t)
    except Exception as e:
        print(f"  Batch {label} failed: {e}, trying individually...")
        translated = []
        for t in texts:
            try:
                translated.append(translator.translate(t))
            except:
                translated.append(t)
    result_data = {"@@locale": target_lang}
    for k, v in zip(keys, translated):
        result_data[k] = v.strip().replace("|||SEP|||", "|||SEP|||")
    return result_data

# Thai
print("Translating to Thai...")
th_data = translate_batch("zh-CN", "th", values, "Thai")
with open("lib/l10n/app_th.arb", "w", encoding="utf-8") as f:
    json.dump(th_data, f, ensure_ascii=False, indent=2)
print("  app_th.arb written")

# Vietnamese
print("Translating to Vietnamese...")
vi_data = translate_batch("zh-CN", "vi", values, "Vietnamese")
with open("lib/l10n/app_vi.arb", "w", encoding="utf-8") as f:
    json.dump(vi_data, f, ensure_ascii=False, indent=2)
print("  app_vi.arb written")

print("Done!")
