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
      { id: 'o1', name: 'taste', min: 1, max: 10, step: 1, goal: 'maximize' },
      { id: 'o2', name: 'smell', min: 1, max: 10, step: 1, goal: 'maximize' },
      { id: 'o3', name: 'appearance', min: 1, max: 10, step: 1, goal: 'maximize' },
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
      { id: 'co1', name: 'strength', min: 1, max: 10, step: 1, goal: 'maximize' },
      { id: 'co2', name: 'bitterness', min: 1, max: 10, step: 1, goal: 'minimize' },
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
      { id: 'ro1', name: 'energy', min: 1, max: 10, step: 1, goal: 'maximize' },
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

  const current = experiments.find(e => e.id === route.expId);

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

  const addExperiment = () => {
    const id = 'exp-' + Date.now();
    const exp = { id, name: '', parameters: [], outcomes: [], runs: [] };
    setExperiments(list => [exp, ...list]);
    setRoute({ name: 'details', expId: id });
    setDrawer({ kind: 'name', isNew: true });
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
  const saveOutput = (out) => { updateExp(route.expId, e => ({ ...e, outcomes: [...e.outcomes, out] })); setDrawer(null); };

  // every recorded run is kept & shown now — nothing is ever "outdated".
  const recordedCount = (e) => (e?.runs || []).filter(r => r.outcomeValues).length;

  // ── edit a parameter / outcome — ALL fields are editable. (A parameter's
  //    TYPE is the one thing locked once created; the drawer enforces that.) ──
  const saveParamEdit = (edited) => { updateExp(current.id, e => stampParams({ ...e, parameters: e.parameters.map(p => p.id === edited.id ? edited : p) })); setDrawer(null); };
  const saveOutcomeEdit = (edited) => { updateExp(current.id, e => ({ ...e, outcomes: e.outcomes.map(o => o.id === edited.id ? edited : o) })); setDrawer(null); };

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
    const map = {};
    current.parameters.forEach(p => { map[p.id] = suggestValue(p); });
    setSuggestion(map);
    setRoute({ name: 'run', expId: current.id });
  };

  // open a single run's details (from history list or best-run shortcut)
  const openRunDetail = (runId, from) => setRoute({ name: 'runDetail', expId: route.expId, runId, from });

  const startRecording = () => {
    const vals = {};
    current.outcomes.forEach(o => { vals[o.id] = midValue(o); });
    setRatingValues(vals);
    setRoute({ name: 'rating', expId: current.id, ratingIndex: 0 });
  };

  const ratingNext = () => {
    const outcomes = current.outcomes;
    if (route.ratingIndex + 1 < outcomes.length) {
      setRoute(r => ({ ...r, ratingIndex: r.ratingIndex + 1 }));
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
    if (route.ratingIndex === 0) setRoute({ name: 'run', expId: current.id });
    else setRoute(r => ({ ...r, ratingIndex: r.ratingIndex - 1 }));
  };

  let screen = null;
  if (route.name === 'list') {
    screen = <ExperimentsListScreen experiments={experiments} onOpen={openExp} onAdd={addExperiment} />;
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
      screen = <RunDetailsScreen exp={current} run={run} num={num} isBest={run.id === bestRunId(current)}
        onBack={() => setRoute({ name: route.from === 'history' ? 'history' : 'details', expId: current.id })} />;
    }
  } else if (route.name === 'run' && current) {
    screen = <RunSuggestionScreen exp={current} suggestion={suggestion}
      onBack={() => setRoute({ name: 'details', expId: current.id })} onRecord={startRecording} />;
  } else if (route.name === 'rating' && current) {
    const o = current.outcomes[route.ratingIndex];
    screen = <RatingScreen exp={current} index={route.ratingIndex}
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
          onDelete={() => setDrawer({ kind: 'confirmDelete' })}
          onClose={() => setDrawer(null)} />
      )}
      {drawer && drawer.kind === 'confirmDelete' && current && (
        <ConfirmDeleteDrawer exp={current}
          onConfirm={() => deleteExperiment(current.id)}
          onClose={() => setDrawer(null)} />
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
