const { test } = require('node:test');
const assert = require('node:assert/strict');
const { planPrune } = require('./prune_firebase_releases');

const parent = 'projects/123/apps/1:123:android:abc';
const release = (version) => ({
  name: `${parent}/releases/${version}`,
  createTime: `2026-11-${String(version).padStart(2, '0')}T00:00:00Z`,
});

test('keeps five newest releases even when the API returns them out of order', () => {
  const plan = planPrune([release(4), release(1), release(7), release(3), release(6), release(2), release(5)], parent);
  assert.deepEqual(plan.keep, [7, 6, 5, 4, 3].map((version) => release(version).name));
  assert.deepEqual(plan.remove, [2, 1].map((version) => release(version).name));
});

test('does not delete anything when there are five or fewer releases', () => {
  assert.deepEqual(planPrune([release(2), release(1)], parent).remove, []);
});

test('refuses releases belonging to another app', () => {
  assert.throws(() => planPrune([{ ...release(1), name: 'projects/other/apps/other/releases/1' }], parent));
});
