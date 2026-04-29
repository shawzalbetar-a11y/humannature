const fs = require('fs');
const path = require('path');

function walk(dir) {
    let results = [];
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
    // Simple regex to find <Image tags
    const imageTags = content.match(/<Image[\s\S]*?>/g);
    if (imageTags) {
        imageTags.forEach((tag) => {
            if (!tag.includes('alt=')) {
                console.log(`Missing alt in ${file}:`);
                console.log(tag);
                console.log('---');
            }
        });
    }
});
