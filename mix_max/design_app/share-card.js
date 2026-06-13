/* ── Mix Max — Share Card renderer ─────────────────────────
   renderShareCard(mountEl, run) builds the shareable card DOM.
   `run` matches the contract written by the app to localStorage:
   { experiment, rating, bestOf, isBest, num, rank, mix[], outcomes[] }
   (meta / comp-bar fields are accepted but intentionally not shown).      */

(function () {
  const ICONS = {
    hash:   '<path d="M9 4 7 20M17 4l-2 16M4 9h16M3 15h16"/>',
    timer:  '<circle cx="12" cy="13" r="8"/><path d="M12 13V8M12 13l3 2M9 2h6"/>',
    toggle: '<rect x="2.5" y="7" width="19" height="10" rx="5"/><circle cx="16" cy="12" r="3.2" fill="var(--sage)" stroke="none"/>',
    list:   '<path d="M9 6h11M9 12h11M9 18h11"/><circle cx="4.5" cy="6" r="1.1" fill="var(--sage)" stroke="none"/><circle cx="4.5" cy="12" r="1.1" fill="var(--sage)" stroke="none"/><circle cx="4.5" cy="18" r="1.1" fill="var(--sage)" stroke="none"/>',
    order:  '<path d="M7 4v16M7 20l-3-3M7 20l3-3M17 20V4M17 4l-3 3M17 4l3 3"/>',
  };
  function sageIcon(name, px) {
    const s = px || 15;
    return `<svg width="${s}" height="${s}" viewBox="0 0 24 24" fill="none" stroke="var(--sage)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${ICONS[name] || ICONS.hash}</svg>`;
  }
  function esc(v) {
    return String(v == null ? '' : v).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  }
  function norm(o) {
    const lo = o.min == null ? 0 : o.min, hi = o.max == null ? 10 : o.max;
    return hi > lo ? Math.min(Math.max((o.value - lo) / (hi - lo), 0), 1) : 0;
  }

  const TROPHY = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 4h10v4a5 5 0 0 1-10 0V4Z"/><path d="M7 5H4.5a2.5 2.5 0 0 0 2.5 4M17 5h2.5a2.5 2.5 0 0 1-2.5 4M9 20h6M12 13v3.5"/></svg>';
  const FLASK  = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="var(--inkSoft)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 3h6M10 3v6L5.5 17.5A2.5 2.5 0 0 0 7.7 21h8.6a2.5 2.5 0 0 0 2.2-3.5L14 9V3"/><path d="M7.7 14h8.6"/></svg>';
  const STAR   = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="var(--gold)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2.5l1.9 5.6L19.5 10l-5.6 1.9L12 17.5l-1.9-5.6L4.5 10l5.6-1.9L12 2.5Z"/></svg>';
  const FOOTMARK = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--gold)" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M9 3h6M10 3v6L5.5 17.5A2.5 2.5 0 0 0 7.7 21h8.6a2.5 2.5 0 0 0 2.2-3.5L14 9V3"/><path d="M7.7 14h8.6"/></svg>';

  // weight-aware contribution palette — matches the in-app Rating breakdown
  const WEIGHT_COLORS = ['#7E719A', '#B5872B', '#6E8A63', '#B0715B', '#5E8A86', '#9A6A8C', '#8A7A3E'];

  // each outcome's contribution to the rating (weight × normalized score × 10).
  // Uses values supplied by the app; falls back to computing them for static demos.
  function ratingRows(outs) {
    const hasPoints = outs.length && outs[0].points != null;
    if (hasPoints) {
      return outs.map(o => ({
        o,
        weight: o.weight != null ? o.weight : 1 / outs.length,
        points: o.points,
      }));
    }
    const rawW = outs.map(o => (o.weight != null ? o.weight : 1));
    const sum = rawW.reduce((a, b) => a + b, 0) || 1;
    return outs.map((o, i) => {
      const w = rawW[i] / sum;
      return { o, weight: w, points: w * norm(o) * 10 };
    });
  }

  function renderShareCard(mount, run) {
    const isBest = run.isBest !== false;
    const mix = Array.isArray(run.mix) ? run.mix : [];
    const outs = Array.isArray(run.outcomes) ? run.outcomes : [];
    const listMode = mix.length > 4;         // 5+ params → ultra-compact list

    // a single parameter spans both columns only when it would otherwise sit alone
    const spanLast = mix.length % 2 === 1 && mix.length === 1;

    const chips = mix.map((m, i) => {
      const span = (spanLast && i === mix.length - 1) ? ' span2' : '';
      return `<div class="pchip${span}">
        <div class="ptop">
          <div class="pic">${sageIcon(m.icon, 15)}</div>
          <div class="pname">${esc(m.name)}</div>
        </div>
        <div class="pval">${esc(m.value)}${m.unit ? `<u>${esc(m.unit)}</u>` : ''}</div>
      </div>`;
    }).join('');

    const listRows = mix.map(m => `
      <div class="lrow">
        <div class="lic">${sageIcon(m.icon, 12)}</div>
        <div class="ln">${esc(m.name)}</div>
        <div class="lv">${esc(m.value)}${m.unit ? `<u>${esc(m.unit)}</u>` : ''}</div>
      </div>`).join('');

    const mixHtml = listMode
      ? `<div class="mixlist">${listRows}</div>`
      : `<div class="mixgrid">${chips}</div>`;

    const ratRows = ratingRows(outs);
    const compSegs = ratRows.map((r, i) => {
      const w = Math.min(r.points * 10, 100);
      return `<div class="seg" style="width:${w}%;background:${WEIGHT_COLORS[i % WEIGHT_COLORS.length]}">${w >= 11 ? `<span>${r.points.toFixed(1)}</span>` : ''}</div>`;
    }).join('');

    const outRows = ratRows.map((r, i) => `
      <div class="orow">
        <span class="odot" style="background:${WEIGHT_COLORS[i % WEIGHT_COLORS.length]}"></span>
        <div class="oinfo">
          <div class="oname">${esc(r.o.name)}</div>
          <div class="oweight">${Math.round(r.weight * 100)}% weight</div>
        </div>
        <div class="ochip">${esc(r.o.value)}<s> / ${esc(r.o.max == null ? 10 : r.o.max)}</s></div>
        <div class="opts">+${r.points.toFixed(1)}</div>
      </div>`).join('');

    mount.classList.add('mmcard');
    mount.innerHTML = `
      <div class="pad head">
        <div class="eyebrow" style="color:var(--gold)">Mix Max</div>
        <div class="badge${isBest ? '' : ' neutral'}">${isBest ? TROPHY : FLASK}<span>${isBest ? 'Best run' : ('Run ' + (run.num || ''))}</span></div>
      </div>

      <div class="pad">
        <h1 class="title">${esc(run.experiment || 'Untitled')}</h1>
      </div>

      <div class="rating">
        <div class="ratingNum">${Number(run.rating || 0).toFixed(1)}<em>/10</em></div>
        <div class="ratingLabel">
          <div class="eyebrow" style="color:var(--goldText)">Overall rating</div>
          <div class="star">${STAR}<span>${isBest ? 'Top-rated mix' : ('Ranked #' + (run.rank || '—'))}</span></div>
        </div>
      </div>

      <div class="pad" style="margin-top:26px">
        <div class="section"><span class="lbl">The mix</span><span class="cnt">${mix.length}</span></div>
        <div class="sub">${isBest ? 'The exact values that won.' : 'The full mix, exactly as set.'}</div>
        ${mixHtml}
      </div>

      <div class="pad" style="margin-top:24px">
        <div class="section"><span class="lbl">How it scored</span><span class="cnt">${outs.length}</span></div>
        <div class="sub">Each outcome's score, by weight, adds up to the rating.</div>
        <div class="compbar">${compSegs}</div>
        <div class="orows">${outRows}</div>
      </div>

      <div class="foot">
        <div class="left">${FOOTMARK}<span class="wd">Find the best version of anything</span></div>
        <div class="brand"><b>Mix</b> Max</div>
      </div>`;
    return mount;
  }

  window.renderShareCard = renderShareCard;
})();
