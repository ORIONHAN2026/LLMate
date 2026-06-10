import sys, json
from deep_translator import GoogleTranslator

with open('lib/l10n/app_zh.arb','r',encoding='utf-8') as f:
    d=json.load(f)
keys,vals=[],[]
for k,v in d.items():
    if k.startswith('@'): continue
    keys.append(k); vals.append(v)

out_th={'@@locale':'th'}
out_vi={'@@locale':'vi'}
SEP='␞␗␟␝S␞␗␟␝'
CHUNK=60

for lang,out in [('th',out_th),('vi',out_vi)]:
    print(f'{lang}...',flush=True)
    t=GoogleTranslator(source='zh-CN',target=lang)
    for s in range(0,len(vals),CHUNK):
        e=min(s+CHUNK,len(vals))
        batch=SEP.join(vals[s:e])
        r=t.translate(batch)
        parts=r.split(SEP)
        if len(parts)!=len(vals[s:e]):
            parts=r.split('␞␗␟␝')
        if len(parts)!=len(vals[s:e]):
            print(f'  WARN {lang} ch{s//CHUNK}: {len(parts)} != {len(vals[s:e])}',flush=True)
            parts=[]
            for v in vals[s:e]:
                parts.append(t.translate(v))
                if (len(parts))%10==0:
                    print(f'    {len(parts)}/{len(vals[s:e])}',flush=True)
        for k,v in zip(keys[s:e],parts):
            out[k]=v.strip()
        print(f'  {lang} {e}/{len(vals)}',flush=True)
    with open(f'lib/l10n/app_{lang}.arb','w',encoding='utf-8') as f:
        json.dump(out,f,ensure_ascii=False,indent=2)
    print(f'{lang} DONE',flush=True)
print('All done!',flush=True)
