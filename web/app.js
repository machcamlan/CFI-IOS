/* CFI Mobile — read-only client for the CFI production Worker.
   No build step: this file runs as-is on GitHub Pages and iOS Safari. */

'use strict';

const DEFAULT_API = 'https://cfi-football-intelligence.baoanhrat112020.workers.dev';
const MARKETS = ['3+ HT', '7+ FT', 'Other HT', 'Other FT'];
const MARKET_LABEL = {
  '3+ HT': 'Hiệp một từ 3 bàn',
  '7+ FT': 'Cả trận từ 7 bàn',
  'Other HT': 'Một đội ghi 4+ hiệp một',
  'Other FT': 'Một đội ghi 5+ cả trận',
};
const CALL_TEXT = {
  BET: ['bet', 'Đủ điều kiện vào kèo'],
  LEAN: ['lean', 'Nghiêng về một hướng'],
  WATCH: ['watch', 'Theo dõi thêm'],
  NO_BET: ['none', 'Không vào kèo'],
  BLOCKED: ['blocked', 'Bị chặn bởi cổng kiểm soát'],
};

/* ---------- storage that survives Safari private mode ---------- */

const memory = new Map();
const store = {
  get(key) {
    try { const v = localStorage.getItem(key); if (v !== null) return v; } catch (_) {}
    return memory.has(key) ? memory.get(key) : null;
  },
  set(key, value) {
    memory.set(key, value);
    try { localStorage.setItem(key, value); } catch (_) {}
  },
  remove(key) {
    memory.delete(key);
    try { localStorage.removeItem(key); } catch (_) {}
  },
};

/* ---------- helpers ---------- */

const $ = (id) => document.getElementById(id);
const num = (v) => (typeof v === 'number' && Number.isFinite(v) ? v : null);
const pct = (v) => (num(v) === null ? null : `${(v * 100).toFixed(1)}%`);
const clamp01 = (v) => Math.max(0, Math.min(1, v));

function text(node, value) { node.textContent = value == null ? '' : String(value); }

function apiBase() {
  const saved = (store.get('cfi.api') || '').trim();
  return (saved || DEFAULT_API).replace(/\/+$/, '');
}

function today() {
  const d = new Date();
  const pad = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

function showState(title, body, busy) {
  $('state').hidden = false;
  $('state').classList.toggle('bad', busy === 'error');
  text($('state-title'), title);
  text($('state-body'), body);
  $('scan').hidden = busy !== 'busy';
}

function hideState() { $('state').hidden = true; }

/* ---------- network ---------- */

async function call(path, options, timeoutMs) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs || 45000);
  try {
    const response = await fetch(apiBase() + path, Object.assign({ signal: controller.signal }, options));
    const raw = await response.text();
    let body = null;
    try { body = raw ? JSON.parse(raw) : null; } catch (_) { body = { status: 'NON_JSON_RESPONSE', raw: raw.slice(0, 400) }; }
    return { ok: response.ok, status: response.status, body };
  } finally {
    clearTimeout(timer);
  }
}

async function checkHealth() {
  const dot = $('health-dot');
  dot.className = 'dot busy';
  text($('health-text'), 'Đang kiểm tra');
  try {
    const { ok, body } = await call('/api/status', { method: 'GET' }, 15000);
    if (!ok) throw new Error('status');
    dot.className = 'dot live';
    text($('health-text'), 'Sẵn sàng');
    const engine = (body && (body.engine || (body.runtime && body.runtime.engine))) || null;
    if (engine) text($('engine'), engine);
  } catch (_) {
    dot.className = 'dot down';
    text($('health-text'), 'Không kết nối được');
    text($('engine'), 'ngoại tuyến');
  }
}

/* ---------- rendering ---------- */

function renderMarkets(markets) {
  const host = $('markets');
  host.innerHTML = '';
  for (const key of MARKETS) {
    const row = (markets && markets[key]) || {};
    const a = num(row.methodA);
    const b = num(row.methodB);
    const final = num(row.final);

    const el = document.createElement('article');
    el.className = 'market';

    const head = document.createElement('div');
    head.className = 'market-head';
    const name = document.createElement('div');
    name.className = 'name';
    name.textContent = MARKET_LABEL[key] || key;
    const value = document.createElement('div');
    value.className = final === null ? 'final none' : 'final';
    value.textContent = final === null ? 'chưa đủ dữ liệu' : pct(final);
    head.append(name, value);
    el.append(head);

    if (final !== null || a !== null || b !== null) {
      const measure = document.createElement('div');
      measure.className = 'measure';
      const track = document.createElement('div');
      track.className = 'track';
      measure.append(track);
      if (final !== null) {
        const fill = document.createElement('div');
        fill.className = 'fill';
        fill.style.width = `${clamp01(final) * 100}%`;
        measure.append(fill);
      }
      for (const [val, cls, label] of [[a, '', 'A'], [b, 'b', 'B']]) {
        if (val === null) continue;
        const tick = document.createElement('i');
        tick.className = `tick ${cls}`.trim();
        tick.style.left = `${clamp01(val) * 100}%`;
        tick.setAttribute('data-k', label);
        measure.append(tick);
      }
      el.append(measure);
    }

    const foot = document.createElement('div');
    foot.className = 'market-foot';
    const bits = [];
    if (a !== null) bits.push(['Method A', pct(a)]);
    if (b !== null) bits.push(['Method B', pct(b)]);
    if (row.confidence) bits.push(['Độ tin cậy', String(row.confidence)]);
    if (num(row.fairOdds) !== null) bits.push(['Fair odds', row.fairOdds.toFixed(2)]);
    if (!bits.length) bits.push(['Trạng thái', 'máy chủ không trả về hai phương án']);
    for (const [k, v] of bits) {
      const span = document.createElement('span');
      span.innerHTML = '';
      span.append(document.createTextNode(k + ' '));
      const strong = document.createElement('b');
      strong.textContent = v;
      span.append(strong);
      foot.append(span);
    }
    el.append(foot);
    host.append(el);
  }
}

function renderScoreRows(host, rows) {
  host.innerHTML = '';
  const list = Array.isArray(rows) ? rows.slice(0, 3) : [];
  if (!list.length) {
    const empty = document.createElement('div');
    empty.className = 'score-row';
    empty.textContent = 'Không có';
    host.append(empty);
    return;
  }
  for (const row of list) {
    const line = document.createElement('div');
    line.className = 'score-row';
    const label = document.createElement('span');
    const home = row.home != null ? row.home : (row.h != null ? row.h : '?');
    const away = row.away != null ? row.away : (row.a != null ? row.a : '?');
    label.textContent = row.score || `${home}-${away}`;
    const p = document.createElement('span');
    p.className = 'p';
    const probability = num(row.probability != null ? row.probability : row.p);
    p.textContent = probability === null ? '—' : pct(probability);
    line.append(label, p);
    host.append(line);
  }
}

function renderScoreline(scoreline, expected) {
  const section = $('scoreline-section');
  if (!scoreline) { section.hidden = true; return; }
  section.hidden = false;

  const eg = expected || scoreline.expectedGoals || {};
  const leg = (period) => {
    const source = eg[period.toLowerCase()] || eg[period] || {};
    const home = num(source.home);
    const away = num(source.away);
    if (home === null && away === null) return 'Bàn kỳ vọng chưa có';
    return `Bàn kỳ vọng ${home === null ? '—' : home.toFixed(2)} / ${away === null ? '—' : away.toFixed(2)}`;
  };
  text($('xg-ht'), leg('ht'));
  text($('xg-ft'), leg('ft'));

  const ht = scoreline.ht || {};
  const ft = scoreline.ft || {};
  renderScoreRows($('scores-ht'), ht.final || ht.top3 || ht.top || []);
  renderScoreRows($('scores-ft'), ft.final || ft.top3 || ft.top || []);

  const path = scoreline.mostLikelyPath;
  if (path) {
    $('path').hidden = false;
    $('path').innerHTML = '';
    $('path').append(document.createTextNode('Đường đi khả dĩ nhất '));
    const b = document.createElement('b');
    b.textContent = typeof path === 'string' ? path : `${path.ht || '?'} → ${path.ft || '?'}`;
    $('path').append(b);
  } else {
    $('path').hidden = true;
  }
}

function kvRow(host, label, value, tone) {
  const row = document.createElement('div');
  row.className = 'kv';
  const k = document.createElement('span');
  k.textContent = label;
  const v = document.createElement('b');
  if (tone) v.classList.add(tone);
  v.textContent = value;
  row.append(k, v);
  host.append(row);
}

function renderEvidence(evidence) {
  const host = $('evidence');
  host.innerHTML = '';
  if (!evidence) {
    kvRow(host, 'Bằng chứng', 'Máy chủ không trả về phần này', 'warn');
    return;
  }
  const counts = evidence.counts || {};
  const unique = num(counts.uniqueCanonical);
  const rows = [
    ['Trận sân nhà', counts.homeFixtures],
    ['Trận sân khách', counts.awayFixtures],
    ['Đối đầu trực tiếp', counts.h2hFixtures],
    ['Trận gốc không trùng', counts.uniqueCanonical],
  ];
  for (const [label, value] of rows) {
    kvRow(host, label, num(value) === null ? '—' : String(value));
  }
  for (const [label, key] of [['Đủ tỷ số hiệp một', 'htCoverage'], ['Đủ tỷ số cả trận', 'ftCoverage']]) {
    const raw = num(evidence[key]) !== null ? num(evidence[key]) : num(counts[key]);
    if (raw === null) { kvRow(host, label, '—'); continue; }
    const ratio = unique && raw > 1 ? raw / unique : raw;
    const tone = ratio >= 0.9 ? 'ok' : ratio >= 0.6 ? 'warn' : 'no';
    const shown = unique && raw > 1 ? `${raw}/${unique}` : pct(raw);
    kvRow(host, label, shown, tone);
  }
  if (evidence.quality) kvRow(host, 'Chất lượng', String(evidence.quality));
  if (evidence.sufficiency) {
    const s = evidence.sufficiency;
    const eligible = s.decisionEligible === true;
    kvRow(host, 'Đủ để ra quyết định', eligible ? 'Có' : 'Chưa', eligible ? 'ok' : 'warn');
  }
}

function renderGates(gates) {
  const section = $('gates-section');
  const host = $('gates');
  host.innerHTML = '';
  if (!gates || typeof gates !== 'object') { section.hidden = true; return; }
  const labels = {
    strictPrior: 'Strict prior',
    consistency: 'Nhất quán nội bộ',
    evidenceSufficient: 'Đủ bằng chứng',
    fixtureIdentityVerified: 'Xác minh danh tính trận',
    marketCoherence: 'Gắn kết giữa các thị trường',
    threePlusHtCalibration: 'Hiệu chỉnh 3+ HT',
    verifiedOdds: 'Kèo đã xác minh',
    freshOdds: 'Kèo còn mới',
  };
  let shown = 0;
  for (const [key, label] of Object.entries(labels)) {
    if (!(key in gates)) continue;
    const raw = gates[key];
    let value; let tone;
    if (raw === true) { value = 'Đạt'; tone = 'ok'; }
    else if (raw === false) { value = 'Không đạt'; tone = 'no'; }
    else { value = String(raw); tone = /PASS|OK/i.test(value) ? 'ok' : /FAIL|BLOCK/i.test(value) ? 'no' : 'warn'; }
    kvRow(host, label, value, tone);
    shown += 1;
  }
  section.hidden = shown === 0;
}

function renderVerdict(body, output, home, away, date) {
  const decision = String((output && output.final) || body.verdict || body.status || 'NO_BET').toUpperCase();
  const [cls, phrase] = CALL_TEXT[decision] || ['none', decision];
  const call = $('call');
  call.className = `call ${cls}`;
  text(call, phrase);

  const primary = (output && output.primary) || null;
  const pick = $('pick');
  pick.innerHTML = '';
  if (primary && primary.market) {
    pick.append(document.createTextNode('Thị trường dẫn đầu '));
    const b = document.createElement('b');
    const p = num(primary.probability);
    b.textContent = p === null ? primary.market : `${primary.market} ${pct(p)}`;
    pick.append(b);
  } else {
    pick.textContent = 'Chưa có thị trường nào vượt ngưỡng quyết định.';
  }

  const target = body.target || {};
  const parts = [
    `${target.home || home} gặp ${target.away || away}`,
    target.targetDate || target.target_date || date,
  ];
  if (body.engine) parts.push(body.engine);
  text($('fixture'), parts.filter(Boolean).join(' · '));
}

function explain(status, httpStatus) {
  const map = {
    EVIDENCE_INSUFFICIENT: 'Cơ sở dữ liệu chưa có đủ trận trước ngày này để chạy strict-prior. Thử một ngày muộn hơn hoặc đội có nhiều lịch sử hơn.',
    NOT_FOUND: 'Máy chủ không tìm thấy trận khớp với hai tên đội này. Kiểm tra lại chính tả tên đội.',
    RUNTIME_CONTRACT_ERROR: 'Máy chủ từ chối vì hợp đồng runtime không đạt. Đây là lỗi phía máy chủ, không phải do nhập liệu.',
    INVALID_REQUEST: 'Máy chủ không đọc được yêu cầu. Kiểm tra lại ngày thi đấu.',
  };
  if (map[status]) return map[status];
  if (httpStatus === 422) return 'Bằng chứng không đủ hoặc đầu vào bị từ chối. Kết quả không được dựng thay bằng số giả.';
  if (httpStatus >= 500) return 'Máy chủ gặp lỗi khi chạy dự đoán. Thử lại sau ít phút.';
  return `Máy chủ trả về trạng thái ${status || httpStatus}.`;
}

/* ---------- main action ---------- */

async function predict() {
  const home = $('home').value.trim();
  const away = $('away').value.trim();
  const date = $('date').value;
  const language = $('language').value;

  if (!home || !away) { showState('Thiếu tên đội', 'Nhập cả đội nhà và đội khách rồi chạy lại.', 'error'); return; }
  if (!date) { showState('Thiếu ngày thi đấu', 'Chọn ngày diễn ra trận đấu.', 'error'); return; }

  store.set('cfi.home', home);
  store.set('cfi.away', away);
  store.set('cfi.language', language);

  $('run').disabled = true;
  $('result').hidden = true;
  showState('Đang phân tích', `${home} gặp ${away} · ${date}`, 'busy');

  try {
    const { ok, status, body } = await call('/api/predict', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ home, away, target_date: date, language, input_mode: 'SINGLE_MATCH', response_mode: 'compact' }),
    });

    if (!body) { showState('Không có phản hồi', 'Máy chủ trả về phản hồi rỗng.', 'error'); return; }

    $('raw').textContent = JSON.stringify(body, null, 2);

    const serverStatus = String(body.status || '').toUpperCase();
    if (!ok || (serverStatus && serverStatus !== 'OK' && !body.markets)) {
      showState('Không dựng được dự đoán', explain(serverStatus, status), 'error');
      $('result').hidden = true;
      return;
    }

    const output = body.practicalOutput || body.outputV3 || body.outputV2 || null;
    hideState();
    renderVerdict(body, output, home, away, date);
    renderMarkets(body.markets);
    renderScoreline((output && output.scoreline) || body.scoreline, (output && output.expectedGoals) || null);
    renderEvidence(body.evidence);
    renderGates((output && output.gates) || body.gates);
    $('result').hidden = false;
    $('result').scrollIntoView({ behavior: 'smooth', block: 'start' });
  } catch (error) {
    const aborted = error && error.name === 'AbortError';
    showState(
      aborted ? 'Quá thời gian chờ' : 'Không gọi được máy chủ',
      aborted
        ? 'Máy chủ không trả lời trong 45 giây. Mạng yếu hoặc Worker đang khởi động lại.'
        : 'Kiểm tra kết nối mạng và địa chỉ Worker trong phần Cài đặt máy chủ.',
      'error'
    );
  } finally {
    $('run').disabled = false;
  }
}

/* ---------- boot ---------- */

function boot() {
  $('date').value = store.get('cfi.date') || today();
  $('home').value = store.get('cfi.home') || '';
  $('away').value = store.get('cfi.away') || '';
  $('language').value = store.get('cfi.language') || 'vi';
  $('api').value = store.get('cfi.api') || DEFAULT_API;

  $('run').addEventListener('click', predict);
  $('date').addEventListener('change', () => store.set('cfi.date', $('date').value));
  $('away').addEventListener('keydown', (e) => { if (e.key === 'Enter') { e.target.blur(); predict(); } });

  $('save-api').addEventListener('click', () => {
    const value = $('api').value.trim();
    if (value) store.set('cfi.api', value); else store.remove('cfi.api');
    checkHealth();
  });
  $('reset-api').addEventListener('click', () => {
    store.remove('cfi.api');
    $('api').value = DEFAULT_API;
    checkHealth();
  });

  checkHealth();

  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
      navigator.serviceWorker.register('./sw.js').catch(() => {});
    });
  }
}

document.addEventListener('DOMContentLoaded', boot);
