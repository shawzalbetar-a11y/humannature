const fs = require('fs');
const path = require('path');

function walk(dir) {
    let results = [];
    if (!fs.existsSync(dir)) return [];
    const list = fs.readdirSync(dir);
    list.forEach((file) => {
        file = path.join(dir, file);
        const stat = fs.statSync(file);
        if (stat && stat.isDirectory()) {
            results = results.concat(walk(file));
        } else {
            if (file.endsWith('.tsx') || file.endsWith('.jsx')) {
                results.push(file);
            }
        }
    });
    return results;
}

const files = walk('src');
files.forEach((file) => {
    const content = fs.readFileSync(file, 'utf8');
    // Regex to find <Image ... /> or <Image ... >
    // Matches <Image followed by anything until >
    const matches = content.matchAll(/<Image\b([\s\S]*?)>/g);
    for (const match of matches) {
        const props = match[1];
        if (!props.includes('alt=')) {
            console.log(`MISSING ALT: ${file}`);
            console.log(match[0]);
            console.log('---');
        }
    }
});
