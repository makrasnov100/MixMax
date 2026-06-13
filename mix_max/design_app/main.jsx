// main.jsx — Mix Max prototype root: state, navigation, seed data, mount

const _NOW = Math.floor(Date.now() / 1000);
const DAY = 86400;

const SEED = [
  {
    id: 'best-tea', name: 'Best Tea',
    parameters: [
      { id: 'p1', name: 'Ounces of water', type: 'number', unit: 'oz', min: 10, max: 12, increment: 0.5 },
      { id: 'p2', name: 'Steep time', type: 'duration', unit: 'minutes', min: 1, max: 10, increment: 0.5 },
      { id: 'p3', name: 'Squeeze bag after steeping', type: 'toggle', onLabel: 'Squeeze', offLabel: 'Leave' },
      { id: 'p4', name: 'Sweetener', type: 'choice', options: ['honey', 'sugar', 'none'] },
    ],
    outcomes: [
      { id: 'o1', name: 'taste', description: 'Sip after it cools for one minute, before any snacks. 10 = rich and balanced with zero bitterness, 7 = good but slightly flat or astringent, 4 = needs sweetener to be drinkable, 0 = undrinkable. Ignore temperature preference — judge flavor only.', min: 1, max: 10, step: 1, goal: 'maximize', weight: 50 },
      { id: 'o2', name: 'smell', min: 1, max: 10, step: 1, goal: 'maximize', weight: 30 },
      { id: 'o3', name: 'appearance', min: 1, max: 10, step: 1, goal: 'maximize', weight: 20 },
    ],
    runs: [
      { id: 'r1', parameterValues: { p1: 11, p2: 3, p3: false, p4: 'honey' }, outcomeValues: { o1: 5, o2: 6, o3: 5 }, createdAt: _NOW - 12 * DAY - 2400, completedAt: _NOW - 12 * DAY },
      { id: 'r2', parameterValues: { p1: 10.5, p2: 5, p3: true, p4: 'honey' }, outcomeValues: { o1: 8, o2: 7, o3: 6 }, createdAt: _NOW - 5 * DAY - 1800, completedAt: _NOW - 5 * DAY },
      { id: 'r3', parameterValues: { p1: 12, p2: 4, p3: true, p4: 'sugar' }, outcomeValues: { o1: 6, o2: 6, o3: 7 }, createdAt: _NOW - 1 * DAY - 3000, completedAt: _NOW - 1 * DAY },
    ],
  },
  {
    id: 'cold-brew', name: 'House Cold Brew',
    parameters: [
      { id: 'cp1', name: 'Coffee grounds', type: 'number', unit: 'g', min: 60, max: 120, increment: 5 },
      { id: 'cp2', name: 'Brew time', type: 'duration', unit: 'hours', min: 8, max: 24, increment: 1 },
      { id: 'cp3', name: 'Grind', type: 'choice', options: ['coarse', 'medium', 'fine'] },
    ],
    outcomes: [
      { id: 'co1', name: 'strength', min: 1, max: 10, step: 1, goal: 'maximize', weight: 60 },
      { id: 'co2', name: 'bitterness', description: 'Judge the bitter aftertaste on the first black sip — before adding milk or ice.', min: 1, max: 10, step: 1, goal: 'minimize', weight: 40 },
    ],
    runs: [
      { id: 'cr1', parameterValues: { cp1: 90, cp2: 16, cp3: 'medium' }, outcomeValues: { co1: 7, co2: 4 }, createdAt: _NOW - 8 * DAY - 1200, completedAt: _NOW - 8 * DAY },
      { id: 'cr2', parameterValues: { cp1: 100, cp2: 12, cp3: 'coarse' }, outcomeValues: { co1: 6, co2: 6 }, createdAt: _NOW - 3 * DAY - 1200, completedAt: _NOW - 3 * DAY },
    ],
  },
  {
    id: 'run-routine', name: 'Pre-Run Routine',
    parameters: [
      { id: 'rp1', name: 'Warm-up', type: 'duration', unit: 'minutes', min: 0, max: 20, increment: 1 },
      { id: 'rp2', name: 'Caffeine', type: 'toggle', onLabel: 'Yes', offLabel: 'No' },
    ],
    outcomes: [
      { id: 'ro1', name: 'energy', min: 1, max: 10, step: 1, goal: 'maximize', weight: 100 },
    ],
    runs: [],
  },
];

// every recorded run carries a snapshot of the parameters & outcomes as they
// were at the time, so it always renders correctly even after later edits/deletes.
function withRunSnapshots(list) {
  return list.map(e => ({
    ...e,
    runs: (e.runs || []).map(r => ({
      params: e.parameters.map(p => ({ ...p })),
      outcomes: e.outcomes.map(o => ({ ...o })),
      ...r,
    })),
  }));
}

function midValue(o) {
  const min = o.min != null ? o.min : 0, max = o.max != null ? o.max : 10;
  const step = o.step && o.step > 0 ? o.step : 1;
  const mid = (min + max) / 2;
  const snapped = min + Math.round((mid - min) / step) * step;
  return Math.min(Math.max(snapped, min), max);
}

function App() {
  const [experiments, setExperiments] = React.useState(() => withRunSnapshots(SEED));
  const [route, setRoute] = React.useState({ name: 'list' }); // {name, expId, ratingIndex}
  const [drawer, setDrawer] = React.useState(null); // null | {kind, ...}
  const [suggestion, setSuggestion] = React.useState({});
  const [ratingValues, setRatingValues] = React.useState({});
  const [account, setAccount] = React.useState({ mode: 'none', provider: null, email: '' });

  const current = experiments.find(e => e.id === route.expId);

  // when rescoring an existing run, the rating flow walks that run's own outcome
  // snapshot (so the sliders match what was measured), not the live outcomes.
  const ratingRun = (route.name === 'rating' && route.rescoreRunId && current)
    ? (current.runs || []).find(r => r.id === route.rescoreRunId) : null;
  const ratingOutcomes = ratingRun ? runOutcomeDefs(current, ratingRun) : (current ? (current.outcomes || []) : []);

  const updateExp = (id, fn) => setExperiments(list => list.map(e => e.id === id ? fn(e) : e));

  // Stamp the moment the parameter set last changed (add / edit / delete). Runs
  // recorded before this moment used a different parameter set, so the optimizer
  // ignores them when tuning the next run — decided purely by this timestamp,
  // not a per-run compatibility check. Editing OUTCOMES does not stamp it, since
  // every run keeps its own outcome snapshot.
  const stampParams = (e) => ({ ...e, lastParametersUpdatedAt: Math.floor(Date.now() / 1000) });

  // navigation
  const openExp = (id) => setRoute({ name: 'details', expId: id });
  const back = () => setRoute({ name: 'list' });
  const openHistory = () => setRoute({ name: 'history', expId: route.expId });

  // ── account ──
  // mode: 'none'  → brand-new, hasn't chosen how to use the app yet (gate)
  //       'guest' → using the app as a guest (still cloud-backed)
  //       'signedIn' → signed in with Google / Apple
  const openAccount = () => setDrawer({ kind: 'account' });
  // Mocked OAuth: signing in records the provider + email (no name is stored).
  // If we're sitting on the create-experiment gate, proceed straight into the
  // new experiment once a choice is made; otherwise flip the drawer in place.
  const signIn = (provider) => {
    const gate = drawer && drawer.gate;
    setAccount({ mode: 'signedIn', provider, email: provider === 'apple' ? 'alex.rivera@icloud.com' : 'alex.rivera@gmail.com' });
    setDrawer(null);
    if (gate) doAddExperiment();
  };
  const continueAsGuest = () => {
    const gate = drawer && drawer.gate;
    setAccount({ mode: 'guest', provider: null, email: '' });
    setDrawer(null);
    if (gate) doAddExperiment();
  };
  // Signing out keeps you onboarded as a guest (data stays in the cloud).
  const signOut = () => { setAccount({ mode: 'guest', provider: null, email: '' }); setDrawer(null); };
  const requestDeleteAccount = () => setDrawer({ kind: 'confirmDelAccount' });
  // Deleting the account wipes the experiment data and returns to the unchosen
  // state, so the next "New experiment" asks how to use the app again.
  const confirmDeleteAccount = () => {
    setAccount({ mode: 'none', provider: null, email: '' });
    setExperiments([]);
    setDrawer(null);
    setRoute({ name: 'list' });
  };

  // Creating an experiment is gated on choosing how to use the app: a brand-new
  // user must pick guest / Google / Apple first. Once chosen, doAddExperiment runs.
  const doAddExperiment = () => {
    const id = 'exp-' + Date.now();
    const exp = { id, name: '', parameters: [], outcomes: [], runs: [] };
    setExperiments(list => [exp, ...list]);
    setRoute({ name: 'details', expId: id });
    setDrawer({ kind: 'name', isNew: true });
  };
  const addExperiment = () => {
    if (account.mode === 'none') { setDrawer({ kind: 'account', gate: true }); return; }
    doAddExperiment();
  };

  const saveName = (name) => {
    updateExp(route.expId, e => ({ ...e, name }));
    setDrawer(null);
  };

  const deleteExperiment = (id) => {
    setExperiments(list => list.filter(e => e.id !== id));
    setDrawer(null);
    setRoute({ name: 'list' });
  };
  const saveParam = (param) => { updateExp(route.expId, e => stampParams({ ...e, parameters: [...e.parameters, param] })); setDrawer(null); };
  // A new outcome's weight defaults to whatever is left of the 100% budget so
  // adding outcomes never overshoots; the user redistributes via the sliders.
  const saveOutput = (out) => {
    updateExp(route.expId, e => {
      const used = (e.outcomes || []).reduce((a, o) => a + (o.weight != null ? o.weight : 0), 0);
      const weight = Math.max(0, Math.min(100, 100 - used));
      return { ...e, outcomes: [...e.outcomes, { ...out, weight }] };
    });
    setDrawer(null);
  };

  // every recorded run is kept & shown now — nothing is ever "outdated".
  const recordedCount = (e) => (e?.runs || []).filter(r => r.outcomeValues).length;

  // ── edit a parameter / outcome — ALL fields are editable. (A parameter's
  //    TYPE is the one thing locked once created; the drawer enforces that.) ──
  const saveParamEdit = (edited) => { updateExp(current.id, e => stampParams({ ...e, parameters: e.parameters.map(p => p.id === edited.id ? edited : p) })); setDrawer(null); };
  // The outcome drawer never edits weight (weighting lives in its own Priorities
  // section), so an edit must carry the existing weight through untouched.
  const saveOutcomeEdit = (edited) => { updateExp(current.id, e => ({ ...e, outcomes: e.outcomes.map(o => o.id === edited.id ? { ...edited, weight: o.weight } : o) })); setDrawer(null); };

  // Set an outcome's weight (0–100). Saved to the outcome itself — it tunes the
  // NEXT run's score. Past runs are untouched: each run kept its own snapshot of
  // the weights as they were when it was recorded.
  const setOutcomeWeight = (outcomeId, weight) => {
    const w = Math.max(0, Math.min(100, Math.round(weight)));
    updateExp(current.id, e => ({ ...e, outcomes: e.outcomes.map(o => o.id === outcomeId ? { ...o, weight: w } : o) }));
  };

  // Rescale every outcome's weight so the priorities add up to exactly 100%,
  // keeping their relative proportions. Used by the "Normalize to 100%" button
  // and run automatically when an experiment is launched.
  const normalizeWeights = () => {
    updateExp(current.id, e => {
      const outs = e.outcomes || [];
      const nw = normalizeWeightList(outs.map(o => (o.weight != null ? o.weight : 0)));
      return { ...e, outcomes: outs.map((o, i) => ({ ...o, weight: nw[i] })) };
    });
  };

  // ── delete a parameter / outcome — past runs keep their own snapshot, so
  //    nothing in history is lost. Incompatible runs simply stop tuning future runs. ──
  const requestDeleteParam = (id) => setDrawer({ kind: 'confirmDelItem', target: 'parameter', id });
  const requestDeleteOutcome = (id) => setDrawer({ kind: 'confirmDelItem', target: 'outcome', id });

  const confirmDelItem = () => {
    const { target, id } = drawer;
    updateExp(current.id, e => target === 'parameter'
      ? stampParams({ ...e, parameters: e.parameters.filter(x => x.id !== id) })
      : ({ ...e, outcomes: e.outcomes.filter(x => x.id !== id) }));
    setDrawer(null);
  };

  // "Keep it" from the delete confirm → return to that item's edit drawer.
  const closeDelItem = () => setDrawer({ kind: drawer.target === 'parameter' ? 'editParam' : 'editOutput', id: drawer.id });

  const runExperiment = () => {
    normalizeWeights(); // outcome weights always sum to 100% for the run, proportions intact
    const map = {};
    current.parameters.forEach(p => { map[p.id] = suggestValue(p); });
    setSuggestion(map);
    setRoute({ name: 'run', expId: current.id });
  };

  // open a single run's details (from history list or best-run shortcut)
  const openRunDetail = (runId, from) => setRoute({ name: 'runDetail', expId: route.expId, runId, from });

  // ── share a run — package its mix + ratings and open the shareable card
  //    (a separate page the app turns into an image). Works for any run; the
  //    "Share best run" entry just feeds it the crowned run. ──
  const shareRun = (runId) => {
    const run = (current.runs || []).find(r => r.id === runId);
    if (!run) return;
    const params = runParamDefs(current, run);
    const outcomes = runOutcomeDefs(current, run);
    const pv = run.parameterValues || {};
    const ov = run.outcomeValues || {};
    const chrono = (current.runs || []).filter(r => r.outcomeValues)
      .sort((a, b) => (a.completedAt || a.createdAt || 0) - (b.completedAt || b.createdAt || 0));
    const num = chrono.findIndex(r => r.id === run.id) + 1;
    const when = run.completedAt || run.createdAt;
    const dateStr = when ? new Date(when * 1000).toLocaleDateString(undefined, { month: 'short', day: 'numeric' }) : '';
    const mix = params.map(p => {
      const v = pv[p.id];
      let value, unit;
      if (p.type === 'toggle') value = v ? onLabelOf(p) : offLabelOf(p);
      else if (p.type === 'choice') value = v != null ? String(v) : '—';
      else if (p.type === 'order') value = (v || []).join(' → ');
      else { value = v != null ? fmt(Number(v), 3) : '—'; unit = p.unit; }
      return { icon: PARAM_TYPES[p.type].icon, name: p.name, value: value == null || value === '' ? '—' : String(value), unit };
    });
    // color-coded rating breakdown rows (weight-aware contribution), so the
    // share card mirrors the in-app Rating breakdown exactly.
    const { rows: ratRows } = ratingRows(current, run);
    const outs = ratRows.map(r => ({
      name: r.o.name,
      value: r.v != null ? fmt(Number(r.v), 3) : '—',
      min: r.o.min != null ? r.o.min : 0,
      max: r.o.max != null ? r.o.max : 10,
      weight: r.weight,
      norm: r.norm,
      points: r.points,
    }));
    const ranked = [...chrono].sort((a, b) => runScore(current, b) - runScore(current, a));
    const rank = ranked.findIndex(r => r.id === run.id) + 1;
    const data = {
      experiment: current.name || 'Untitled experiment',
      meta: `Run ${num}${dateStr ? ' · ' + dateStr : ''}`,
      rating: Number((runScore(current, run) * 10).toFixed(1)),
      bestOf: chrono.length,
      isBest: run.id === bestRunId(current),
      num, rank,
      mix, outcomes: outs,
    };
    try { localStorage.setItem('mm_share_run', JSON.stringify(data)); } catch (e) { }
    setDrawer(null);
    window.open('Share Run.html', '_blank');
  };

  // ── rescore an existing run — same rating UI, prefilled with its values. The
  //    "best run" is always derived from scores, so once the new ratings land it
  //    is recrowned automatically: if this was the best and no longer is, the
  //    next-highest run becomes best. ──
  const startRescore = (runId) => {
    const run = (current.runs || []).find(r => r.id === runId);
    if (!run) return;
    const outcomes = runOutcomeDefs(current, run);
    const vals = {};
    outcomes.forEach(o => { vals[o.id] = (run.outcomeValues && run.outcomeValues[o.id] != null) ? run.outcomeValues[o.id] : midValue(o); });
    setRatingValues(vals);
    setRoute({ name: 'rating', expId: current.id, ratingIndex: 0, rescoreRunId: runId, from: route.from });
    setDrawer(null);
  };

  // ── delete a run — drops it from history. Best run recomputes automatically. ──
  const deleteRun = (runId) => {
    const from = route.from;
    updateExp(current.id, e => ({ ...e, runs: (e.runs || []).filter(r => r.id !== runId) }));
    setDrawer(null);
    setRoute({ name: from === 'history' ? 'history' : 'details', expId: current.id });
  };

  const startRecording = () => {
    const vals = {};
    current.outcomes.forEach(o => { vals[o.id] = midValue(o); });
    setRatingValues(vals);
    setRoute({ name: 'rating', expId: current.id, ratingIndex: 0 });
  };

  const ratingNext = () => {
    const outcomes = ratingOutcomes;
    if (route.ratingIndex + 1 < outcomes.length) {
      setRoute(r => ({ ...r, ratingIndex: r.ratingIndex + 1 }));
    } else if (route.rescoreRunId) {
      // rescore: overwrite the existing run's outcome values; best recomputes.
      const runId = route.rescoreRunId;
      updateExp(current.id, e => ({
        ...e,
        runs: (e.runs || []).map(r => r.id === runId ? { ...r, outcomeValues: { ...ratingValues } } : r),
      }));
      setRoute({ name: 'runDetail', expId: current.id, runId, from: route.from });
    } else {
      // save run
      const ts = Math.floor(Date.now() / 1000);
      const run = {
        id: 'r' + Date.now(),
        params: current.parameters.map(p => ({ ...p })),
        outcomes: current.outcomes.map(o => ({ ...o })),
        parameterValues: { ...suggestion }, outcomeValues: { ...ratingValues },
        createdAt: ts - 60, completedAt: ts,
      };
      updateExp(current.id, e => ({ ...e, runs: [...e.runs, run] }));
      setRoute({ name: 'details', expId: current.id });
    }
  };
  const ratingBack = () => {
    if (route.ratingIndex === 0) {
      if (route.rescoreRunId) setRoute({ name: 'runDetail', expId: current.id, runId: route.rescoreRunId, from: route.from });
      else setRoute({ name: 'run', expId: current.id });
    } else setRoute(r => ({ ...r, ratingIndex: r.ratingIndex - 1 }));
  };

  let screen = null;
  if (route.name === 'list') {
    screen = <ExperimentsListScreen experiments={experiments} onOpen={openExp} onAdd={addExperiment} onAccount={openAccount} signedIn={account.mode === 'signedIn'} />;
  } else if (route.name === 'details' && current) {
    screen = <ExperimentDetailsScreen exp={current} onBack={back}
      onRename={() => setDrawer({ kind: 'name' })}
      onAddParam={() => setDrawer({ kind: 'param' })}
      onAddOutput={() => setDrawer({ kind: 'output' })}
      onMenu={() => setDrawer({ kind: 'actions' })}
      onHistory={() => setRoute({ name: 'history', expId: current.id })}
      onOpenBest={() => { const id = bestRunId(current); if (id) openRunDetail(id, 'details'); }}
      onEditParam={(id) => setDrawer({ kind: 'editParam', id })}
      onEditOutput={(id) => setDrawer({ kind: 'editOutput', id })}
      onSetWeight={setOutcomeWeight}
      onNormalize={normalizeWeights}
      onRun={runExperiment} />;
  } else if (route.name === 'history' && current) {
    screen = <RunHistoryScreen exp={current} onBack={() => setRoute({ name: 'details', expId: current.id })}
      onOpenRun={(runId) => openRunDetail(runId, 'history')} />;
  } else if (route.name === 'runDetail' && current) {
    const run = (current.runs || []).find(r => r.id === route.runId);
    if (run) {
      const chrono = (current.runs || []).filter(r => r.outcomeValues)
        .sort((a, b) => (a.completedAt || a.createdAt || 0) - (b.completedAt || b.createdAt || 0));
      const num = chrono.findIndex(r => r.id === run.id) + 1;
      const isBest = run.id === bestRunId(current);
      screen = <RunDetailsScreen exp={current} run={run} num={num} isBest={isBest}
        onBack={() => setRoute({ name: route.from === 'history' ? 'history' : 'details', expId: current.id })}
        onMenu={() => setDrawer({ kind: 'runActions', runId: run.id, num, isBest })} />;
    }
  } else if (route.name === 'run' && current) {
    screen = <RunSuggestionScreen exp={current} suggestion={suggestion}
      onBack={() => setRoute({ name: 'details', expId: current.id })} onRecord={startRecording} />;
  } else if (route.name === 'rating' && current) {
    const o = ratingOutcomes[route.ratingIndex];
    screen = <RatingScreen exp={current} index={route.ratingIndex} outcomes={ratingOutcomes} rescore={!!route.rescoreRunId}
      value={ratingValues[o.id] != null ? ratingValues[o.id] : midValue(o)}
      onChange={(v) => setRatingValues(vals => ({ ...vals, [o.id]: v }))}
      onBack={ratingBack} onNext={ratingNext} />;
  }

  return (
    <div style={{ position: 'absolute', inset: 0, overflow: 'hidden' }}>
      {screen}
      {drawer && drawer.kind === 'name' && (
        <NameDrawer initial={drawer.isNew ? '' : (current?.name || '')}
          title={drawer.isNew ? 'Name your experiment' : 'Rename experiment'}
          onSave={saveName} onClose={() => setDrawer(null)} />
      )}
      {drawer && drawer.kind === 'param' && <AddParameterDrawer onSave={saveParam} onClose={() => setDrawer(null)} />}
      {drawer && drawer.kind === 'output' && <AddOutputDrawer onSave={saveOutput} onClose={() => setDrawer(null)} />}
      {drawer && drawer.kind === 'editParam' && current && (() => {
        const p = current.parameters.find(x => x.id === drawer.id);
        return p ? <ParameterDrawer initial={p}
          onSave={saveParamEdit} onDelete={() => requestDeleteParam(p.id)} onClose={() => setDrawer(null)} /> : null;
      })()}
      {drawer && drawer.kind === 'editOutput' && current && (() => {
        const o = current.outcomes.find(x => x.id === drawer.id);
        return o ? <OutcomeDrawer initial={o}
          onSave={saveOutcomeEdit} onDelete={() => requestDeleteOutcome(o.id)} onClose={() => setDrawer(null)} /> : null;
      })()}
      {drawer && drawer.kind === 'confirmDelItem' && current && (
        <ConfirmDeleteItemDrawer target={drawer.target} runCount={recordedCount(current)}
          onConfirm={confirmDelItem} onClose={closeDelItem} />
      )}
      {drawer && drawer.kind === 'actions' && current && (
        <ExperimentActionsDrawer exp={current}
          onRename={() => setDrawer({ kind: 'name' })}
          onShareBest={() => { const id = bestRunId(current); if (id) shareRun(id); }}
          onDelete={() => setDrawer({ kind: 'confirmDelete' })}
          onClose={() => setDrawer(null)} />
      )}
      {drawer && drawer.kind === 'confirmDelete' && current && (
        <ConfirmDeleteDrawer exp={current}
          onConfirm={() => deleteExperiment(current.id)}
          onClose={() => setDrawer(null)} />
      )}
      {drawer && drawer.kind === 'runActions' && current && (
        <RunActionsDrawer num={drawer.num} isBest={drawer.isBest}
          onShare={() => shareRun(drawer.runId)}
          onRescore={() => startRescore(drawer.runId)}
          onDelete={() => setDrawer({ kind: 'confirmDelRun', runId: drawer.runId, num: drawer.num, isBest: drawer.isBest })}
          onClose={() => setDrawer(null)} />
      )}
      {drawer && drawer.kind === 'confirmDelRun' && current && (() => {
        const run = (current.runs || []).find(r => r.id === drawer.runId);
        return run ? <ConfirmDeleteRunDrawer exp={current} run={run} num={drawer.num} isBest={drawer.isBest}
          onConfirm={() => deleteRun(drawer.runId)}
          onClose={() => setDrawer({ kind: 'runActions', runId: drawer.runId, num: drawer.num, isBest: drawer.isBest })} /> : null;
      })()}
      {drawer && drawer.kind === 'account' && (
        <AccountDrawer account={account}
          onGoogle={() => signIn('google')} onApple={() => signIn('apple')}
          onGuest={continueAsGuest}
          onSignOut={signOut} onDelete={requestDeleteAccount}
          onClose={() => setDrawer(null)} />
      )}
      {drawer && drawer.kind === 'confirmDelAccount' && (
        <ConfirmDeleteAccountDrawer experimentCount={experiments.length}
          onConfirm={confirmDeleteAccount}
          onClose={() => setDrawer({ kind: 'account' })} />
      )}
    </div>
  );
}

// fit the device to the viewport
function Fit({ children, w = 402, h = 874 }) {
  const [scale, setScale] = React.useState(1);
  React.useEffect(() => {
    const calc = () => {
      const pad = 48;
      const s = Math.min(1, (window.innerWidth - pad) / w, (window.innerHeight - pad) / h);
      setScale(s);
    };
    calc();
    window.addEventListener('resize', calc);
    return () => window.removeEventListener('resize', calc);
  }, [w, h]);
  return (
    <div style={{ width: w * scale, height: h * scale }}>
      <div style={{ width: w, height: h, transform: scale === 1 ? 'none' : `scale(${scale})`, transformOrigin: 'top left' }}>
        {children}
      </div>
    </div>
  );
}

function Root() {
  return (
    <Fit>
      <IOSDevice>
        <App />
      </IOSDevice>
    </Fit>
  );
}

ReactDOM.createRoot(document.getElementById('stage')).render(<Root />);
