// icons.jsx — clean line-icon set for Mix Max (UI glyphs, simple geometry)

function Icon({ name, size = 22, color = 'currentColor', stroke = 1.8, style }) {
  const p = {
    fill: 'none', stroke: color, strokeWidth: stroke,
    strokeLinecap: 'round', strokeLinejoin: 'round',
  };
  const paths = {
    hash: <g {...p}><path d="M9 4 7 20M17 4l-2 16M4 9h16M3 15h16" /></g>,
    timer: <g {...p}><circle cx="12" cy="13" r="8" /><path d="M12 13V8M12 13l3 2M9 2h6" /></g>,
    toggle: <g {...p}><rect x="2.5" y="7" width="19" height="10" rx="5" /><circle cx="16" cy="12" r="3.2" fill={color} stroke="none" /></g>,
    list: <g {...p}><path d="M9 6h11M9 12h11M9 18h11" /><circle cx="4.5" cy="6" r="1.1" fill={color} stroke="none" /><circle cx="4.5" cy="12" r="1.1" fill={color} stroke="none" /><circle cx="4.5" cy="18" r="1.1" fill={color} stroke="none" /></g>,
    order: <g {...p}><path d="M7 4v16M7 20l-3-3M7 20l3-3M17 20V4M17 4l-3 3M17 4l3 3" /></g>,
    up: <g {...p}><path d="M12 19V5M12 5l-6 6M12 5l6 6" /></g>,
    down: <g {...p}><path d="M12 5v14M12 19l-6-6M12 19l6-6" /></g>,
    play: <g {...p}><path d="M7 5.5v13a1 1 0 0 0 1.5.87l11-6.5a1 1 0 0 0 0-1.74l-11-6.5A1 1 0 0 0 7 5.5Z" /></g>,
    plus: <g {...p}><path d="M12 5v14M5 12h14" /></g>,
    chevR: <g {...p}><path d="M9 5l7 7-7 7" /></g>,
    chevL: <g {...p}><path d="M15 5l-7 7 7 7" /></g>,
    arrowR: <g {...p}><path d="M4 12h15M13 6l6 6-6 6" /></g>,
    arrowL: <g {...p}><path d="M20 12H5M11 6l-6 6 6 6" /></g>,
    check: <g {...p}><path d="M5 12.5l4.5 4.5L19 6.5" /></g>,
    x: <g {...p}><path d="M6 6l12 12M18 6 6 18" /></g>,
    sparkle: <g {...p}><path d="M12 3v6M12 15v6M3 12h6M15 12h6M6.5 6.5l3 3M14.5 14.5l3 3M17.5 6.5l-3 3M9.5 14.5l-3 3" /></g>,
    spark2: <g {...p}><path d="M12 2.5l1.9 5.6L19.5 10l-5.6 1.9L12 17.5l-1.9-5.6L4.5 10l5.6-1.9L12 2.5Z" /><path d="M19 15.5l.7 2.1 2.1.7-2.1.7-.7 2.1-.7-2.1-2.1-.7 2.1-.7.7-2.1Z" /></g>,
    flask: <g {...p}><path d="M9 3h6M10 3v6L5.5 17.5A2.5 2.5 0 0 0 7.7 21h8.6a2.5 2.5 0 0 0 2.2-3.5L14 9V3" /><path d="M7.7 14h8.6" /></g>,
    beaker: <g {...p}><path d="M7 3h10M8.5 3v6.5L5 17a2 2 0 0 0 1.8 3h10.4A2 2 0 0 0 19 17l-3.5-7.5V3" /><path d="M6.5 13.5c2-1 3.5 1 5.5 0s3.5 1 5.5 0" /></g>,
    edit: <g {...p}><path d="M4 20h4l10-10a2.1 2.1 0 0 0-3-3L5 17v3Z" /><path d="M13.5 6.5l3 3" /></g>,
    grip: <g {...p}><circle cx="9" cy="6" r="1.2" fill={color} stroke="none" /><circle cx="15" cy="6" r="1.2" fill={color} stroke="none" /><circle cx="9" cy="12" r="1.2" fill={color} stroke="none" /><circle cx="15" cy="12" r="1.2" fill={color} stroke="none" /><circle cx="9" cy="18" r="1.2" fill={color} stroke="none" /><circle cx="15" cy="18" r="1.2" fill={color} stroke="none" /></g>,
    info: <g {...p}><circle cx="12" cy="12" r="9" /><path d="M12 11v5M12 7.6v.2" /></g>,
    target: <g {...p}><circle cx="12" cy="12" r="8.5" /><circle cx="12" cy="12" r="4.2" /><circle cx="12" cy="12" r="0.6" fill={color} stroke="none" /></g>,
    trophy: <g {...p}><path d="M7 4h10v4a5 5 0 0 1-10 0V4Z" /><path d="M7 5H4.5a2.5 2.5 0 0 0 2.5 4M17 5h2.5a2.5 2.5 0 0 1-2.5 4M9 20h6M12 13v3.5" /></g>,
    ruler: <g {...p}><rect x="3" y="8" width="18" height="8" rx="1.5" /><path d="M7 8v3M11 8v4M15 8v3M19 8v3" /></g>,
    bag: <g {...p}><path d="M6 8h12l-1 12H7L6 8Z" /><path d="M9 8V6a3 3 0 0 1 6 0v2" /></g>,
    trash: <g {...p}><path d="M5 7h14M10 7V5h4v2M6 7l1 13h10l1-13" /></g>,
    clock: <g {...p}><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3.5 2" /></g>,
    more: <g {...p}><circle cx="5" cy="12" r="1.4" fill={color} stroke="none" /><circle cx="12" cy="12" r="1.4" fill={color} stroke="none" /><circle cx="19" cy="12" r="1.4" fill={color} stroke="none" /></g>,
    alert: <g {...p}><path d="M12 3.5 21 19H3L12 3.5Z" /><path d="M12 10v4.5M12 17.4v.2" /></g>,
    lock: <g {...p}><rect x="4.5" y="10.5" width="15" height="10" rx="2.5" /><path d="M8 10.5V7.5a4 4 0 0 1 8 0v3" /><circle cx="12" cy="15.2" r="1.1" fill={color} stroke="none" /></g>,
    eye: <g {...p}><path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12Z" /><circle cx="12" cy="12" r="3" /></g>,
    eyeOff: <g {...p}><path d="M4 4l16 16M9.9 5.2A9.9 9.9 0 0 1 12 5c6 0 9.5 7 9.5 7a16 16 0 0 1-3.2 3.9M6.3 7.8A16 16 0 0 0 2.5 12S6 19 12 19a9.6 9.6 0 0 0 3.4-.6M9.9 14.1a3 3 0 0 0 4.2-4.2" /></g>,
    share: <g {...p}><path d="M12 15V3.5M12 3.5 8.5 7M12 3.5 15.5 7M6 11H5a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-6a2 2 0 0 0-2-2h-1" /></g>,
    user: <g {...p}><circle cx="12" cy="8.2" r="3.7" /><path d="M5.5 19.5a6.5 6.5 0 0 1 13 0" /></g>,
    cloud: <g {...p}><path d="M7 18h9.4a3.8 3.8 0 0 0 .3-7.6 5.4 5.4 0 0 0-10.4 1.1A3.6 3.6 0 0 0 6.9 18Z" /></g>,
    signout: <g {...p}><path d="M9.5 4H6a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h3.5" /><path d="M14 12h7.5M18 8l4 4-4 4" /></g>,
  };
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" style={style} aria-hidden="true">
      {paths[name] || null}
    </svg>
  );
}

// Brand marks for the auth buttons — standard, recognizable sign-in affordances.
function GoogleMark({ size = 20 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 48 48" aria-hidden="true">
      <path fill="#EA4335" d="M24 9.5c3.5 0 6.6 1.2 9.1 3.6l6.8-6.8C35.9 2.4 30.4 0 24 0 14.6 0 6.5 5.4 2.6 13.2l7.9 6.1C12.4 13.5 17.7 9.5 24 9.5z" />
      <path fill="#4285F4" d="M46.1 24.6c0-1.6-.1-3.1-.4-4.6H24v9.3h12.4c-.5 2.9-2.1 5.3-4.6 6.9l7.2 5.6c4.2-3.9 6.6-9.6 6.6-16.2z" />
      <path fill="#FBBC05" d="M10.5 28.3c-.5-1.4-.7-2.9-.7-4.3s.3-3 .7-4.3l-7.9-6.1C1 16.5 0 20.1 0 24s1 7.5 2.6 10.4l7.9-6.1z" />
      <path fill="#34A853" d="M24 48c6.5 0 11.9-2.1 15.9-5.8l-7.2-5.6c-2 1.4-4.6 2.2-8.7 2.2-6.3 0-11.6-4-13.5-9.5l-7.9 6.1C6.5 42.6 14.6 48 24 48z" />
    </svg>
  );
}
function AppleMark({ size = 20, color = '#fff' }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" aria-hidden="true">
      <path fill={color} d="M16.4 12.7c0-2.3 1.9-3.4 2-3.5-1.1-1.6-2.8-1.8-3.4-1.85-1.4-.14-2.83.82-3.55.82-.72 0-1.9-.8-3.12-.78-1.6.02-3.08.93-3.9 2.37-1.66 2.88-.43 7.15 1.2 9.5.8 1.14 1.74 2.42 2.98 2.38 1.2-.05 1.65-.78 3.1-.78 1.44 0 1.85.78 3.12.75 1.29-.02 2.1-1.17 2.89-2.32.5-.74.88-1.55 1.16-2.42-.06-.02-2.34-.9-2.34-3.55zM14.13 5.83c.65-.79 1.09-1.89.97-2.98-.94.04-2.07.62-2.74 1.41-.6.7-1.13 1.82-.99 2.89 1.05.08 2.11-.53 2.76-1.32z" />
    </svg>
  );
}

Object.assign(window, { Icon, GoogleMark, AppleMark });
