// Keep the newest five releases of the configured Firebase Android app.
// The service account file is created by the distribution workflow.
const KEEP_COUNT = 5;
const API_ROOT = 'https://firebaseappdistribution.googleapis.com/v1';

function planPrune(releases, parent, keepCount = KEEP_COUNT) {
  if (!Array.isArray(releases) || !Number.isInteger(keepCount) || keepCount < 1) {
    throw new Error('Invalid release list or retention count');
  }

  const prefix = `${parent}/releases/`;
  const seen = new Set();
  for (const release of releases) {
    if (!release.name?.startsWith(prefix) || !Number.isFinite(Date.parse(release.createTime))) {
      throw new Error('Release list contains an unexpected app or creation time');
    }
    if (seen.has(release.name)) {
      throw new Error('Release list contains duplicate releases');
    }
    seen.add(release.name);
  }

  const newestFirst = [...releases].sort((a, b) =>
    Date.parse(b.createTime) - Date.parse(a.createTime) || b.name.localeCompare(a.name)
  );
  return {
    keep: newestFirst.slice(0, keepCount).map((release) => release.name),
    remove: newestFirst.slice(keepCount).map((release) => release.name),
  };
}

async function main() {
  const appId = process.env.FIREBASE_ANDROID_APP_ID || '';
  const match = /^1:([0-9]+):android:[0-9a-f]+$/.exec(appId);
  if (!match || !process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    throw new Error('Firebase app ID or service account file is missing');
  }
  const parent = `projects/${match[1]}/apps/${appId}`;

  // Use the same service account that uploaded the APK, without printing its token.
  const { GoogleAuth } = require('google-auth-library');
  const auth = new GoogleAuth({
    keyFile: process.env.GOOGLE_APPLICATION_CREDENTIALS,
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  });
  const client = await auth.getClient();
  const { token } = await client.getAccessToken();
  if (!token) throw new Error('Could not obtain Firebase API access token');

  async function request(url, options = {}) {
    const response = await fetch(url, {
      ...options,
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
        ...options.headers,
      },
    });
    if (!response.ok) throw new Error(`Firebase App Distribution API returned HTTP ${response.status}`);
    return response.json();
  }

  async function listReleases() {
    const releases = [];
    let pageToken = '';
    do {
      const url = new URL(`${API_ROOT}/${parent}/releases`);
      url.searchParams.set('pageSize', '100');
      if (pageToken) url.searchParams.set('pageToken', pageToken);
      const page = await request(url);
      releases.push(...(page.releases || []));
      pageToken = page.nextPageToken || '';
    } while (pageToken);
    return releases;
  }

  const { keep, remove } = planPrune(await listReleases(), parent);
  console.log(`Keeping ${keep.length} newest Firebase releases; deleting ${remove.length} older releases.`);
  for (let offset = 0; offset < remove.length; offset += 100) {
    await request(`${API_ROOT}/${parent}/releases:batchDelete`, {
      method: 'POST',
      body: JSON.stringify({ names: remove.slice(offset, offset + 100) }),
    });
  }
  let remaining = await listReleases();
  for (let attempt = 0; remaining.length > KEEP_COUNT && attempt < 4; attempt++) {
    await new Promise((resolve) => setTimeout(resolve, 2000));
    remaining = await listReleases();
  }
  if (remaining.length > KEEP_COUNT) {
    throw new Error(`Firebase still lists ${remaining.length} releases after cleanup`);
  }
  console.log(`Firebase now has ${remaining.length} releases.`);
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}

module.exports = { planPrune };
