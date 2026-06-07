// main.jsx — Mix Max prototype root: state, navigation, seed data, mount

const SEED = [
  {
    id: 'best-tea', name: 'Best Tea',
    parameters: [
      { id: 'p1', name: 'Ounces of water', type: 'number', unit: 'oz', min: 10, max: 12 },
      { id: 'p2', name: 'Steep time', type: 'duration', unit: 'minutes', min: 1, max: 10 },
      { id: 'p3', name: 'Squeeze bag after steeping', type: 'toggle' },
      { id: 'p4', name: 'Sweetener', type: 'choice', options: ['honey', 'sugar', 'none'] },
    ],
    outcomes: [
      { id: 'o1', name: 'taste', min: 1, max: 10, step: 1, goal: 'maximize' },
      { id: 'o2', name: 'smell', min: 1, max: 10, step: 1, goal: 'maximize' },
      { id: 'o3', name: 'appearance', min: 1, max: 10, step: 1, goal: 'maximize' },
    ],
    runs: [
      { id: 'r1', outcomeValues: { o1: 5, o2: 6, o3: 5 } },
      { id: 'r2', outcomeValues: { o1: 8, o2: 7, o3: 6 } },
      { id: 'r3', outcomeValues: { o1: 6, o2: 6, o3: 7 } },
    ],
  },
  {
    id: 'cold-brew', name: 'House Cold Brew',
    parameters: [
      { id: 'cp1', name: 'Coffee grounds', type: 'number', unit: 'g', min: 60, max: 120 },
      { id: 'cp2', name: 'Brew time', type: 'duration', unit: 'hours', min: 8, max: 24 },
      { id: 'cp3', name: 'Grind', type: 'choice', options: ['coarse', 'medium', 'fine'] },
    ],
    outcomes: [
      { id: 'co1', name: 'strength', min: 1, max: 10, step: 1, goal: 'maximize' },
      { id: 'co2', name: 'bitterness', min: 1, max: 10, step: 1, goal: 'minimize' },
    ],
    runs: [
      { id: 'cr1', outcomeValues: { co1: 7, co2: 4 } },
      { id: 'cr2', outcomeValues: { co1: 6, co2: 6 } },
    ],
  },
  {
    id: 'run-routine', name: 'Pre-Run Routine',
    parameters: [
      { id: 'rp1', name: 'Warm-up', type: 'duration', unit: 'minutes', min: 0, max: 20 },
      { id: 'rp2', name: 'Caffeine', type: 'toggle' },
    ],
    outcomes: [
      { id: 'ro1', name: 'energy', min: 1, max: 10, step: 1, goal: 'maximize' },
    ],
    runs: [],
  },
];

function midValue(o) {
  const min = o.min != null ? o.min : 0, max = o.max != null ? o.max : 10;
  const step = o.step && o.step > 0 ? o.step : 1;
  const mid = (min + max) / 2;
  const snapped = min + Math.round((mid - min) / step) * step;
  return Math.min(Math.max(snapped, min), max);
}

function App() {
  const [experiments, setExperiments] = React.useState(SEED);
  const [route, setRoute] = React.useState({ name: 'list' }); // {name, expId, ratingIndex}
  const [drawer, setDrawer] = React.useState(null); // null | {kind, ...}
  const [suggestion, setSuggestion] = React.useState({});
  const [ratingValues, setRatingValues] = React.useState({});

  const current = experiments.find(e => e.id === route.expId);

  const updateExp = (id, fn) => setExperiments(list => list.map(e => e.id === id ? fn(e) : e));

  // navigation
  const openExp = (id) => setRoute({ name: 'details', expId: id });
  const back = () => setRoute({ name: 'list' });

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
  const saveParam = (param) => { updateExp(route.expId, e => ({ ...e, parameters: [...e.parameters, param] })); setDrawer(null); };
  const saveOutput = (out) => { updateExp(route.expId, e => ({ ...e, outcomes: [...e.outcomes, out] })); setDrawer(null); };

  const runExperiment = () => {
    const map = {};
    current.parameters.forEach(p => { map[p.id] = suggestValue(p); });
    setSuggestion(map);
    setRoute({ name: 'run', expId: current.id });
  };

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
      const run = { id: 'r' + Date.now(), outcomeValues: { ...ratingValues } };
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
      onRun={runExperiment} />;
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
