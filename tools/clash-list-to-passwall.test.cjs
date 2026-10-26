// Run with: node tools/clash-list-to-passwall.test.cjs
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const fields = new Map();
const storage = new Map();
function element() {
  return { value: '', textContent: '', classList: { add() {}, remove() {} },
    addEventListener() {}, appendChild() {} };
}
const context = vm.createContext({
  document: {
    getElementById(id) {
      if (!fields.has(id)) fields.set(id, element());
      return fields.get(id);
    },
    createElement: element
  },
  localStorage: {
    getItem: key => storage.get(key) ?? null,
    setItem: (key, value) => storage.set(key, value)
  },
  setTimeout() {}
});
const html = fs.readFileSync(path.join(__dirname, 'clash-list-to-passwall.html'), 'utf8');
vm.runInContext(html.match(/<script>([\s\S]*?)<\/script>/)[1], context);
const convert = (input, mode) => JSON.parse(JSON.stringify(context.convertRules(input, mode)));

let result = convert(`payload:
  # comment
  - DOMAIN-SUFFIX,chatgpt.com
  - 'DOMAIN,github.com' # comment
  - "DOMAIN-KEYWORD,client-api"
  - IP-CIDR,24.199.123.28/32
  - IP-CIDR6,2001:db8::/32
  - IP-ASN,20473`);
assert.deepEqual(result.domains, ['domain:chatgpt.com', 'full:github.com', 'client-api']);
assert.deepEqual(result.ips, ['24.199.123.28/32', '2001:db8::/32']);
assert.equal(result.skipped, 1);
assert.equal(result.issues[0].line, 8);

result = convert('DOMAIN-SUFFIX,chatgpt.com\r\nDOMAIN-SUFFIX,chatgpt.com');
assert.equal(result.converted, 1);
assert.equal(result.duplicates, 1);
assert.deepEqual(convert('DOMAIN-SUFFIX,\nDOMAIN,foo..com\nIP-CIDR,999.1.1.1/32\nIP-CIDR,:::/128\nIP-CIDR,1.2.3.4/33').skipped, 5);

result = convert('rules:\n - DOMAIN,github.com,MyServer\n - DST-PORT,22,MyServer\n - IP-CIDR,1.2.3.4/32,DIRECT,no-resolve\n - IP-CIDR,10.0.0.0/8,DIRECT,src');
assert.equal(result.converted, 2);
assert.equal(result.skipped, 2);
assert.equal(result.issues.length, 4);
assert.deepEqual(result.ips, ['1.2.3.4/32']);

for (const input of ['DOMAIN-REGEX,^example\\.com$', 'AND,((DOMAIN,github.com),(DST-PORT,22)),PROXY', 'GEOSITE,openai', 'payload: ["DOMAIN,github.com"]', "- 'DOMAIN,github.com", '- |']) {
  assert.equal(convert(input).skipped, 1, input);
}
assert.deepEqual(convert('payload:\n - example.com\n - +.example.net\n - "*.example.org"', 'domain').domains,
  ['full:example.com', 'domain:example.net', 'regexp:^[^.]+\\.example\\.org$']);
assert.equal(convert('foo.*.com', 'domain').skipped, 1);
assert.deepEqual(convert('payload:\n - 1.2.3.4/32\n - ::1/128', 'ipcidr').ips, ['1.2.3.4/32', '::1/128']);
assert.equal(convert('').converted, 0);

// Exercise the real UI handler and corrupted/disabled history storage.
context.document.getElementById('inputBehavior').value = 'classical';
context.document.getElementById('ruleInput').value = 'DOMAIN-SUFFIX,chatgpt.com';
storage.set('history', '{invalid json');
context.convertRule();
assert.equal(fields.get('domainOutput').value, 'domain:chatgpt.com');
assert.equal(fields.get('ipOutput').rows, 3);
context.document.getElementById('ruleInput').value = '';
context.localStorage.setItem = () => { throw new Error('disabled'); };
context.convertRule();
assert.equal(fields.get('domainOutput').value, '');
console.log('All converter regression checks passed.');
