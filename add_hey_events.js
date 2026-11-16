const fs = require('fs');
let parsed = JSON.parse(fs.readFileSync('C:\\Users\\mattf\\Downloads\\New folder (22)\\tnt\\assets\\data\\places\\places.json', 'utf8'));
const heyEvents = [
    { time: 0, name: 'Hey', params: ['bf-places'] },
    { time: 8000, name: 'Hey', params: ['bloxbi'] },
    { time: 16000, name: 'Hey', params: ['bf-places'] },
    { time: 24000, name: 'Hey', params: ['bloxbi'] },
    { time: 32000, name: 'Hey', params: ['bf-places'] }
];
const insertPosition = 1; // After Hide Stuff at position 0
const newEvents = [...parsed.events.slice(0, insertPosition), ...heyEvents, ...parsed.events.slice(insertPosition)];
parsed.events = newEvents;
fs.writeFileSync('C:\\Users\\mattf\\Downloads\\New folder (22)\\tnt\\assets\\data\\places\\places.json', JSON.stringify(parsed, null, 4));
console.log('Added', heyEvents.length, 'Hey events');
console.log('Total events now:', parsed.events.length);
// Show Hey events
console.log('Hey events:');
parsed.events.filter(e => e.name === 'Hey').forEach((e, i) => {
    console.log(' ' + i + ':', e.name, 'at', (e.time/1000).toFixed(1) + 's', 'params:', e.params ? e.params[0] : 'none');
});