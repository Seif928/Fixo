const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const web = path.join(__dirname, '..', 'web');

test('startup retires only Flutter asset caches and preserves Firebase push registration', async () => {
  const removed = [], deleted = [];
  let loaded = false;
  const registrations = ['flutter_service_worker.js?v=old', 'firebase-messaging-sw.js', 'other-worker.js'].map(name => ({
    active: {scriptURL: `https://fixo.example/${name}`},
    unregister: async () => {removed.push(name);},
  }));
  const source = fs.readFileSync(path.join(web, 'flutter_bootstrap.js'), 'utf8')
    .replace('{{flutter_js}}', '').replace('{{flutter_build_config}}', '');
  await vm.runInNewContext(source, {
    navigator: {serviceWorker: {getRegistrations: async () => registrations}},
    location: {origin: 'https://fixo.example'}, document: {baseURI: 'https://fixo.example/'}, URL,
    caches: {delete: async key => {deleted.push(key);}},
    console,
    _flutter: {loader: {load: () => {loaded = true;}}},
  });
  assert.equal(loaded, true);
  assert.deepEqual(removed, ['flutter_service_worker.js?v=old']);
  assert.deepEqual(deleted.sort(), ['flutter-app-cache', 'flutter-app-manifest', 'flutter-temp-cache']);
});

test('a blocked cache API cannot prevent the app from loading', async () => {
  let loaded = false;
  const source = fs.readFileSync(path.join(web, 'flutter_bootstrap.js'), 'utf8')
    .replace('{{flutter_js}}', '').replace('{{flutter_build_config}}', '');
  await vm.runInNewContext(source, {
    navigator: {serviceWorker: {getRegistrations: async () => {throw Error('denied');}}},
    console: {warn: () => {}},
    _flutter: {loader: {load: () => {loaded = true;}}},
  });
  assert.equal(loaded, true);
});
