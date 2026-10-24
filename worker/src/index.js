// Clan Hub proxy. Holds the official API token (secret COC_TOKEN) so it never
// ships in the app or the repo. The official API only accepts keys bound to
// fixed IPs, so requests go through the RoyaleAPI community proxy, whose IP
// (45.79.218.79) is the one whitelisted on the key.
//
// Routes
//   GET /player/:tag        official player profile
//   GET /live[?clan=#TAG]   live event windows for the home rail
//   GET /released           names of units confirmed live in the game
//
// No request data is logged or stored.

const API = 'https://cocproxy.royaleapi.dev/v1';
const TAG_RE = /^#?[0289PYLQGRJCUV]{3,12}$/i;

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Accept, Content-Type',
};

function json(body, status = 200, maxAge = 0) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...CORS,
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': maxAge > 0 ? `public, max-age=${maxAge}` : 'no-store',
    },
  });
}

function cleanTag(raw) {
  const t = decodeURIComponent(raw || '').trim().toUpperCase();
  if (!TAG_RE.test(t)) return null;
  return t.startsWith('#') ? t : `#${t}`;
}

async function coc(env, path) {
  const res = await fetch(`${API}${path}`, {
    headers: { Authorization: `Bearer ${env.COC_TOKEN}`, Accept: 'application/json' },
    cf: { cacheTtl: 0 },
  });
  if (!res.ok) {
    const err = new Error(`upstream ${res.status}`);
    err.status = res.status;
    throw err;
  }
  return res.json();
}

/** Edge-cache a computed JSON body for `ttl` seconds. */
async function cached(ctx, key, ttl, compute) {
  const cache = caches.default;
  const req = new Request(`https://clan-hub.cache/${key}`);
  const hit = await cache.match(req);
  if (hit) return hit.json();
  const body = await compute();
  ctx.waitUntil(
    cache.put(req, new Response(JSON.stringify(body), {
      headers: { 'Cache-Control': `public, max-age=${ttl}` },
    })),
  );
  return body;
}

const addDays = (compact, days) => {
  // "20261023T070000.000Z" -> Date
  const m = /^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})/.exec(compact || '');
  if (!m) return null;
  const d = new Date(Date.UTC(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +m[6]));
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString();
};

async function referenceClan(env, ctx) {
  return cached(ctx, 'ref-clan', 86400, async () => {
    const r = await coc(env, '/locations/global/rankings/clans?limit=1');
    return { tag: r.items?.[0]?.tag ?? null };
  });
}

async function liveEvents(env, ctx, clanTag) {
  const shared = await cached(ctx, 'live-shared', 300, async () => {
    const events = [];
    try {
      const gp = await coc(env, '/goldpass/seasons/current');
      events.push({
        id: 'goldpass', kind: 'goldPass', title: 'Gold Pass season',
        subtitle: 'Season rewards track', start: gp.startTime, end: gp.endTime,
      });
    } catch (_) { /* skip */ }
    try {
      const ref = await referenceClan(env, ctx);
      if (ref.tag) {
        const r = await coc(env, `/clans/${encodeURIComponent(ref.tag)}/capitalraidseasons?limit=1`);
        const s = r.items?.[0];
        if (s?.state === 'ongoing') {
          events.push({
            id: 'raid', kind: 'raidWeekend', title: 'Raid Weekend',
            subtitle: 'Clan Capital raids', start: s.startTime, end: s.endTime,
          });
        } else if (s) {
          events.push({
            id: 'raid-next', kind: 'raidWeekend', title: 'Raid Weekend',
            subtitle: 'Next Clan Capital raids',
            start: addDays(s.startTime, 7), end: addDays(s.endTime, 7),
          });
        }
      }
    } catch (_) { /* skip */ }
    return events;
  });

  const events = [...shared];
  if (clanTag) {
    try {
      const w = await coc(env, `/clans/${encodeURIComponent(clanTag)}/currentwar`);
      if (w.state === 'preparation' || w.state === 'inWar') {
        const vs = w.opponent?.name ? `vs ${w.opponent.name}` : 'Your clan';
        events.push(w.state === 'preparation'
          ? { id: 'war', kind: 'clanWar', title: 'Clan war', subtitle: vs, start: w.startTime, end: w.endTime }
          : { id: 'war', kind: 'clanWar', title: 'Clan war battle day', subtitle: vs, start: w.startTime, end: w.endTime });
      }
    } catch (_) { /* private war log or no war */ }
  }
  return { events };
}

async function released(env, ctx) {
  return cached(ctx, 'released', 86400, async () => {
    const top = await coc(env, '/locations/global/rankings/players?limit=25');
    const names = new Set();
    for (const p of top.items ?? []) {
      try {
        const full = await coc(env, `/players/${encodeURIComponent(p.tag)}`);
        for (const k of ['troops', 'heroes', 'spells', 'heroEquipment']) {
          for (const u of full[k] ?? []) names.add(u.name);
        }
      } catch (_) { /* skip one player */ }
    }
    return { names: [...names].sort(), updated: new Date().toISOString() };
  });
}

export default {
  async fetch(request, env, ctx) {
    if (request.method === 'OPTIONS') return new Response(null, { headers: CORS });
    if (request.method !== 'GET') return json({ reason: 'methodNotAllowed' }, 405);
    const url = new URL(request.url);
    const parts = url.pathname.split('/').filter(Boolean);
    try {
      if (parts[0] === 'player' && parts[1]) {
        const tag = cleanTag(parts.slice(1).join('/'));
        if (!tag) return json({ reason: 'badTag' }, 400);
        return json(await coc(env, `/players/${encodeURIComponent(tag)}`), 200, 60);
      }
      if (parts[0] === 'live') {
        const raw = url.searchParams.get('clan');
        const clan = raw ? cleanTag(raw) : null;
        return json(await liveEvents(env, ctx, clan), 200, 60);
      }
      if (parts[0] === 'released') return json(await released(env, ctx), 200, 3600);
      return json({ reason: 'notFound' }, 404);
    } catch (e) {
      const status = [400, 403, 404, 429, 503].includes(e.status) ? e.status : 502;
      return json({ reason: 'upstream', status: e.status ?? null }, status);
    }
  },
};
