import fs from 'node:fs';
import path from 'node:path';

const OUT_DIR = path.resolve('public/fonts');
const UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36';

const SOURCES = [
    {
        name: 'material-icons',
        url: 'https://fonts.googleapis.com/icon?family=Material+Icons'
    },
    {
        name: 'outfit',
        url: 'https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700&display=swap'
    }
];

fs.mkdirSync(OUT_DIR, { recursive: true });

for (const source of SOURCES) {
    const res = await fetch(source.url, { headers: { 'User-Agent': UA } });
    if (!res.ok) throw new Error(`${source.url} -> HTTP ${res.status}`);
    let css = await res.text();

    const urls = [...css.matchAll(/url\((https:\/\/fonts\.gstatic\.com\/[^)]+)\)/g)].map(m => m[1]);
    const unique = [...new Set(urls)];

    for (const fontUrl of unique) {
        const fileName = path.basename(new URL(fontUrl).pathname);
        const target = path.join(OUT_DIR, fileName);
        if (!fs.existsSync(target)) {
            const fontRes = await fetch(fontUrl, { headers: { 'User-Agent': UA } });
            if (!fontRes.ok) throw new Error(`${fontUrl} -> HTTP ${fontRes.status}`);
            fs.writeFileSync(target, Buffer.from(await fontRes.arrayBuffer()));
        }
        css = css.split(fontUrl).join(`./${fileName}`);
    }

    fs.writeFileSync(path.join(OUT_DIR, `${source.name}.css`), css);
    console.log(`${source.name}: ${unique.length} font file(s)`);
}
