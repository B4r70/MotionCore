/* ─────────────────────────────────────────────────────────────
   MotionCore — ActiveWorkoutView (redesign, calm)
   Recreation of the iOS active-strength-workout screen using the
   design-system components. Same content & vocabulary as the
   SwiftUI original (ActiveWorkoutView + ActiveSetCard +
   RestTimerCard + LiveHealthCard + PRBannerView + status bar),
   restyled to the 2026 calm direction.

   Exposes (window):
     MC_AW_StatusHeader, MC_AW_RestPill, MC_AW_PRBanner,
     MC_AW_SetCard, MC_AW_ExerciseList, MC_AW_AdjustSheet, MC_awIcon
   ───────────────────────────────────────────────────────────── */

const AWDS = window.MotionCoreDesignSystem_2f47a0;
const { Button, Card, Chip, Badge, SectionHeader, ProgressRing } = AWDS;

const Ai = (n, size) => <i data-lucide={n} style={size ? { width: size, height: size } : undefined}></i>;

/* Exercise thumbnail — the app shows a looping video frame; we have
   no exercise media, so a calm icon tile stands in (icon-led brand). */
function Thumb({ icon = 'dumbbell', size = 64 }) {
  return (
    <span style={{ width:size, height:size, flexShrink:0, borderRadius:'var(--r-md)',
      display:'flex', alignItems:'center', justifyContent:'center',
      background:'var(--readiness-soft)', color:'var(--accent)' }}>
      {Ai(icon, Math.round(size*0.42))}</span>
  );
}

/* ── Status header (timer · volume · sets · progress · live chip) ─ */
function StatusHeader({ elapsed, volume, done, total, progress, hr, kcal, plan, paused }) {
  return (
    <div style={{ padding:'4px 20px 14px' }}>
      <div style={{ display:'flex', alignItems:'flex-start', justifyContent:'space-between', gap:12 }}>
        {/* timer */}
        <div style={{ minWidth:0 }}>
          <div style={{ display:'flex', alignItems:'center', gap:6 }}>
            <span style={{ color: paused ? 'var(--warning)' : 'var(--accent)', display:'flex' }}>
              {Ai(paused ? 'pause' : 'clock', 16)}</span>
            <span style={{ fontFamily:'var(--font-rounded)', fontWeight:700, fontSize:'var(--fs-title)',
              fontVariantNumeric:'tabular-nums', color:'var(--text-primary)', letterSpacing:'-0.3px' }}>{elapsed}</span>
          </div>
          <div style={{ fontSize:'var(--fs-micro)', letterSpacing:'.6px', textTransform:'uppercase',
            fontWeight:700, color:'var(--text-tertiary)', marginTop:3 }}>{paused ? 'Pausiert' : plan}</div>
        </div>
        {/* volume */}
        <div style={{ textAlign:'center' }}>
          <div style={{ fontFamily:'var(--font-rounded)', fontWeight:700, fontSize:'var(--fs-title)',
            color:'var(--text-primary)', fontVariantNumeric:'tabular-nums' }}>{volume}</div>
          <div style={{ fontSize:'var(--fs-micro)', letterSpacing:'.6px', textTransform:'uppercase',
            fontWeight:700, color:'var(--text-tertiary)', marginTop:3 }}>Volumen</div>
        </div>
        {/* sets */}
        <div style={{ textAlign:'right' }}>
          <div style={{ fontFamily:'var(--font-rounded)', fontWeight:700, fontSize:'var(--fs-title)',
            color:'var(--text-primary)', fontVariantNumeric:'tabular-nums' }}>{done}/{total}</div>
          <div style={{ fontSize:'var(--fs-micro)', letterSpacing:'.6px', textTransform:'uppercase',
            fontWeight:700, color:'var(--text-tertiary)', marginTop:3 }}>Sätze</div>
        </div>
      </div>

      {/* progress */}
      <div style={{ height:6, borderRadius:'var(--r-pill)', background:'var(--surface-sunken)',
        overflow:'hidden', marginTop:12 }}>
        <div style={{ height:'100%', width:`${Math.round(progress*100)}%`, borderRadius:'var(--r-pill)',
          background:'var(--accent)', transition:'width var(--dur-slow) var(--ease-out)' }} />
      </div>

      {/* live health chips */}
      <div style={{ display:'flex', gap:8, marginTop:12 }}>
        <span style={{ display:'inline-flex', alignItems:'center', gap:7, height:30, padding:'0 12px',
          borderRadius:'var(--r-pill)', background:'var(--surface-card)', boxShadow:'inset 0 0 0 1px var(--line)' }}>
          <span style={{ color:'var(--danger)', display:'flex' }}>{Ai('heart', 15)}</span>
          <span style={{ fontSize:'var(--fs-caption)', fontWeight:600, color:'var(--text-primary)',
            fontVariantNumeric:'tabular-nums' }}>{hr}<span style={{ color:'var(--text-tertiary)', fontWeight:500 }}> bpm</span></span>
        </span>
        <span style={{ display:'inline-flex', alignItems:'center', gap:7, height:30, padding:'0 12px',
          borderRadius:'var(--r-pill)', background:'var(--surface-card)', boxShadow:'inset 0 0 0 1px var(--line)' }}>
          <span style={{ color:'var(--warning)', display:'flex' }}>{Ai('flame', 15)}</span>
          <span style={{ fontSize:'var(--fs-caption)', fontWeight:600, color:'var(--text-primary)',
            fontVariantNumeric:'tabular-nums' }}>{kcal}<span style={{ color:'var(--text-tertiary)', fontWeight:500 }}> kcal</span></span>
        </span>
        <span style={{ marginLeft:'auto', display:'inline-flex', alignItems:'center', gap:6, height:30, padding:'0 11px',
          borderRadius:'var(--r-pill)', background:'var(--recovery-soft)' }}>
          <span style={{ color:'var(--success)', display:'flex' }}>{Ai('watch', 14)}</span>
          <span style={{ fontSize:'var(--fs-micro)', fontWeight:700, color:'var(--success)',
            letterSpacing:'.3px', textTransform:'uppercase' }}>Live</span>
        </span>
      </div>
    </div>
  );
}

/* ── Compact rest pill (slim, non-blocking) ──────────────────── */
function RestPill({ remaining, target, next, onSkip, onAdjust }) {
  const pct = target > 0 ? remaining / target : 0;
  const tone = remaining > 30 ? 'var(--accent)' : remaining > 10 ? 'var(--warning)' : 'var(--danger)';
  const mmss = remaining < 60 ? `${remaining}s` : `${Math.floor(remaining/60)}:${String(remaining%60).padStart(2,'0')}`;
  const R = 15, C = 2*Math.PI*R;
  return (
    <div style={{ margin:'0 20px', padding:'10px 12px 10px 14px', borderRadius:'var(--r-lg)',
      background:'var(--surface-card)', boxShadow:'var(--shadow-card)',
      display:'flex', alignItems:'center', gap:13 }}>
      {/* mini ring */}
      <span style={{ position:'relative', width:38, height:38, flexShrink:0 }}>
        <svg width="38" height="38" viewBox="0 0 38 38">
          <circle cx="19" cy="19" r={R} fill="none" strokeWidth="4" style={{ stroke:'var(--surface-sunken)' }} />
          <circle cx="19" cy="19" r={R} fill="none" strokeWidth="4" strokeLinecap="round"
            strokeDasharray={`${pct*C} ${C}`} transform="rotate(-90 19 19)" style={{ stroke:tone }} />
        </svg>
      </span>
      <div style={{ flex:1, minWidth:0 }}>
        <div style={{ display:'flex', alignItems:'baseline', gap:8 }}>
          <span style={{ fontSize:'var(--fs-micro)', letterSpacing:'.6px', textTransform:'uppercase',
            fontWeight:700, color:'var(--text-tertiary)' }}>Pause</span>
          <span style={{ fontFamily:'var(--font-rounded)', fontWeight:700, fontSize:'var(--fs-headline)',
            color:'var(--text-primary)', fontVariantNumeric:'tabular-nums' }}>{mmss}</span>
        </div>
        <div style={{ fontSize:'var(--fs-caption)', color:'var(--text-secondary)', marginTop:1, whiteSpace:'nowrap',
          overflow:'hidden', textOverflow:'ellipsis' }}>Nächster: {next}</div>
      </div>
      <div style={{ display:'flex', alignItems:'center', gap:6, flexShrink:0 }}>
        <button onClick={() => onAdjust(15)} style={pillBtn}>+15s</button>
        <button onClick={onSkip} style={{ ...pillBtn, background:'var(--accent)', color:'#fff', boxShadow:'none' }}>
          {Ai('forward', 15)}</button>
      </div>
    </div>
  );
}
const pillBtn = {
  display:'inline-flex', alignItems:'center', justifyContent:'center', gap:4, height:34, minWidth:34, padding:'0 11px',
  borderRadius:'var(--r-pill)', border:'none', cursor:'pointer', background:'var(--surface-sunken)',
  color:'var(--text-secondary)', fontFamily:'var(--font-sans)', fontSize:'var(--fs-caption)', fontWeight:600 };

/* ── Full rest card (big ring) — for 'inline' & 'vollbild' tweaks ─ */
function RestCard({ remaining, target, next, onSkip, onAdjust }) {
  const pct = target > 0 ? remaining / target : 0;
  const tone = remaining > 30 ? 'var(--accent)' : remaining > 10 ? 'var(--warning)' : 'var(--danger)';
  const mmss = remaining < 60 ? `${remaining}s` : `${Math.floor(remaining/60)}:${String(remaining%60).padStart(2,'0')}`;
  const R = 92, C = 2*Math.PI*R;
  return (
    <Card>
      <div style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:18, padding:'6px 0' }}>
        <span style={{ fontSize:'var(--fs-micro)', letterSpacing:'.6px', textTransform:'uppercase',
          fontWeight:700, color:'var(--text-tertiary)' }}>Pause</span>
        <span style={{ position:'relative', width:210, height:210 }}>
          <svg width="210" height="210" viewBox="0 0 210 210">
            <circle cx="105" cy="105" r={R} fill="none" strokeWidth="13" style={{ stroke:'var(--surface-sunken)' }} />
            <circle cx="105" cy="105" r={R} fill="none" strokeWidth="13" strokeLinecap="round"
              strokeDasharray={`${pct*C} ${C}`} transform="rotate(-90 105 105)" style={{ stroke:tone }} />
          </svg>
          <span style={{ position:'absolute', inset:0, display:'flex', alignItems:'center', justifyContent:'center',
            fontFamily:'var(--font-rounded)', fontWeight:700, fontSize:60, color: remaining>10?'var(--text-primary)':'var(--warning)',
            fontVariantNumeric:'tabular-nums' }}>{mmss}</span>
        </span>
        <div style={{ display:'flex', alignItems:'center', gap:14 }}>
          <button onClick={() => onAdjust(-15)} style={pillBtn}>−15s</button>
          <button onClick={() => onAdjust(15)} style={pillBtn}>+15s</button>
        </div>
        <div style={{ textAlign:'center' }}>
          <div style={{ fontSize:'var(--fs-subhead)', fontWeight:600, color:'var(--text-primary)' }}>{next}</div>
          <div style={{ fontSize:'var(--fs-caption)', color:'var(--text-secondary)', marginTop:1 }}>Nächster Satz vorbereiten</div>
        </div>
        <Button fullWidth size="lg" icon={Ai('forward',16)} onClick={onSkip}>Pause überspringen</Button>
      </div>
    </Card>
  );
}

/* ── PR banner (medium, stylish) ─────────────────────────────── */
function PRBanner({ exercise, oneRM }) {
  return (
    <div style={{ margin:'0 20px', padding:'12px 16px', borderRadius:'var(--r-lg)',
      display:'flex', alignItems:'center', gap:13,
      background:'var(--streak-soft)', boxShadow:'inset 0 0 0 1px rgba(199,144,47,0.35)' }}>
      <span style={{ width:38, height:38, borderRadius:'50%', flexShrink:0, display:'flex',
        alignItems:'center', justifyContent:'center', background:'rgba(199,144,47,0.16)', color:'var(--warning)' }}>
        {Ai('crown', 20)}</span>
      <div style={{ flex:1, minWidth:0 }}>
        <div style={{ fontSize:'var(--fs-subhead)', fontWeight:700, color:'var(--text-primary)' }}>Neuer PR!</div>
        <div style={{ fontSize:'var(--fs-caption)', color:'var(--text-secondary)' }}>{exercise} · {oneRM} kg 1RM</div>
      </div>
      <Badge tone="alert" solid dot>Rekord</Badge>
    </div>
  );
}

/* ── Active set card (centerpiece) ───────────────────────────── */
function SetCard({ s, showLast, onAdjust, onComplete, variant = 'stacked' }) {
  return (
    <Card>
      {/* header */}
      <div style={{ display:'flex', alignItems:'center', gap:14 }}>
        <Thumb icon={s.icon} size={64} />
        <div style={{ flex:1, minWidth:0 }}>
          {s.kind && s.kind !== 'work' && (
            <div style={{ fontSize:'var(--fs-micro)', letterSpacing:'.6px', textTransform:'uppercase',
              fontWeight:700, color:'var(--warning)' }}>{s.kind}</div>
          )}
          <div style={{ fontSize:'var(--fs-headline)', fontWeight:700, color:'var(--text-primary)',
            letterSpacing:'-0.2px', whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{s.ex}</div>
          <div style={{ display:'flex', alignItems:'center', gap:8, marginTop:3 }}>
            <span style={{ fontSize:'var(--fs-caption)', color:'var(--text-secondary)' }}>Satz {s.set} von {s.of}</span>
            {s.suggestion && <Badge tone="neutral">Vorschlag</Badge>}
          </div>
        </div>
        <button style={iconBtn} aria-label="Anleitung">{Ai('book-open', 18)}</button>
      </div>

      {/* superset tracker */}
      {s.superset && (
        <div style={{ marginTop:14, padding:'9px 12px', borderRadius:'var(--r-md)', background:'var(--recovery-soft)' }}>
          <div style={{ display:'flex', alignItems:'center', gap:6, marginBottom:8 }}>
            <span style={{ color:'var(--success)', display:'flex' }}>{Ai('zap', 14)}</span>
            <span style={{ fontSize:'var(--fs-micro)', letterSpacing:'.4px', textTransform:'uppercase',
              fontWeight:700, color:'var(--success)' }}>Superset · Runde {s.superset.round}/{s.superset.rounds}</span>
          </div>
          <div style={{ display:'flex', alignItems:'center', gap:7, flexWrap:'wrap' }}>
            {s.superset.names.map((n, i) => (
              <React.Fragment key={i}>
                <span style={{ display:'inline-flex', alignItems:'center', gap:5 }}>
                  <span style={{ width:14, height:14, display:'flex', alignItems:'center', justifyContent:'center' }}>
                    {i < s.superset.cur
                      ? <span style={{ color:'var(--success)' }}>{Ai('check', 13)}</span>
                      : <span style={{ width:8, height:8, borderRadius:'50%',
                          background: i === s.superset.cur ? 'var(--success)' : 'transparent',
                          boxShadow: i === s.superset.cur ? 'none' : 'inset 0 0 0 1.5px rgba(31,158,110,0.5)' }} />}
                  </span>
                  <span style={{ fontSize:'var(--fs-caption)', fontWeight: i === s.superset.cur ? 600 : 500,
                    color: i === s.superset.cur ? 'var(--text-primary)' : 'var(--text-secondary)' }}>{n}</span>
                </span>
                {i < s.superset.names.length-1 && <span style={{ color:'var(--text-tertiary)', display:'flex' }}>{Ai('chevron-right', 12)}</span>}
              </React.Fragment>
            ))}
          </div>
        </div>
      )}

      {/* values */}
      <div style={{ height:1, background:'var(--line-soft)', margin:'18px 0' }} />
      {variant === 'target' ? (
        <ValuesTarget s={s} showLast={showLast} />
      ) : (
        <ValuesStacked s={s} showLast={showLast} />
      )}

      {/* actions */}
      <div style={{ display:'flex', gap:10, marginTop:18 }}>
        <Button variant="secondary" size="md" icon={Ai('sliders-horizontal',16)} onClick={onAdjust}
          style={{ flex:'0 0 auto' }}>Anpassen</Button>
        <Button size="md" icon={Ai('check',17)} onClick={onComplete} style={{ flex:1 }}>Satz abschließen</Button>
      </div>
    </Card>
  );
}

/* values — variant A: stacked weight | reps, reference below */
function ValuesStacked({ s, showLast }) {
  return (
    <div>
      <div style={{ display:'flex', alignItems:'stretch' }}>
        <ValueCell value={s.kg} unit={s.kg === '0' ? 'Körpergewicht' : 'kg'} />
        <div style={{ width:1, background:'var(--line)', margin:'4px 0' }} />
        <ValueCell value={s.reps} unit="Wdh." />
      </div>
      {showLast && s.lastReps && (
        <div style={{ textAlign:'center', marginTop:12, fontSize:'var(--fs-caption)', color:'var(--text-tertiary)' }}>
          Letztes Mal: {s.lastReps} Wdh. × {s.lastKg} kg
        </div>
      )}
    </div>
  );
}

/* values — variant B: current vs. last side-by-side (target-led) */
function ValuesTarget({ s, showLast }) {
  return (
    <div style={{ display:'flex', alignItems:'stretch', gap:10 }}>
      <div style={{ flex:1, padding:'2px 0' }}>
        <div style={{ fontSize:'var(--fs-micro)', letterSpacing:'.5px', textTransform:'uppercase',
          fontWeight:700, color:'var(--accent)', textAlign:'center' }}>Jetzt</div>
        <div style={{ display:'flex', alignItems:'baseline', justifyContent:'center', gap:6, marginTop:6 }}>
          <span style={bigNum}>{s.kg}</span><span style={numUnit}>kg</span>
          <span style={{ color:'var(--text-tertiary)', fontWeight:600, margin:'0 2px' }}>×</span>
          <span style={bigNum}>{s.reps}</span>
        </div>
      </div>
      {showLast && s.lastReps && (
        <>
          <div style={{ width:1, background:'var(--line)', margin:'4px 0' }} />
          <div style={{ flex:1, padding:'2px 0', opacity:0.7 }}>
            <div style={{ fontSize:'var(--fs-micro)', letterSpacing:'.5px', textTransform:'uppercase',
              fontWeight:700, color:'var(--text-tertiary)', textAlign:'center' }}>Letztes Mal</div>
            <div style={{ display:'flex', alignItems:'baseline', justifyContent:'center', gap:6, marginTop:6 }}>
              <span style={{ ...bigNum, color:'var(--text-secondary)' }}>{s.lastKg}</span><span style={numUnit}>kg</span>
              <span style={{ color:'var(--text-tertiary)', fontWeight:600, margin:'0 2px' }}>×</span>
              <span style={{ ...bigNum, color:'var(--text-secondary)' }}>{s.lastReps}</span>
            </div>
          </div>
        </>
      )}
    </div>
  );
}

function ValueCell({ value, unit }) {
  return (
    <div style={{ flex:1, textAlign:'center' }}>
      <div style={bigNum}>{value}</div>
      <div style={{ fontSize:'var(--fs-caption)', color:'var(--text-secondary)', marginTop:2 }}>{unit}</div>
    </div>
  );
}
const bigNum = { fontFamily:'var(--font-rounded)', fontWeight:700, fontSize:36, lineHeight:1.05,
  color:'var(--text-primary)', fontVariantNumeric:'tabular-nums' };
const numUnit = { fontSize:'var(--fs-subhead)', fontWeight:600, color:'var(--text-secondary)' };
const iconBtn = { width:36, height:36, flexShrink:0, borderRadius:'50%', border:'none', cursor:'pointer',
  background:'var(--surface-sunken)', color:'var(--text-secondary)', display:'flex', alignItems:'center', justifyContent:'center' };

/* ── Exercise overview (collapsible session list) ────────────── */
function ExerciseList({ items, openIdx }) {
  const [open, setOpen] = React.useState(true);
  return (
    <Card>
      <SectionHeader title="Übungen" eyebrow={`${items.filter(i=>i.state==='done').length} von ${items.length} erledigt`}
        onClick={() => setOpen(o => !o)} style={{ cursor:'pointer', marginBottom: open ? 'var(--sp-3)' : 0 }}
        action={<span style={{ color:'var(--text-tertiary)', display:'flex',
          transform: open ? 'rotate(0deg)' : 'rotate(-90deg)',
          transition:'transform var(--dur-base) var(--ease-out)' }}>{Ai('chevron-down')}</span>} />
      <div style={{ display:'grid', gridTemplateRows: open ? '1fr' : '0fr',
        transition:'grid-template-rows var(--dur-base) var(--ease-out)' }}>
        <div style={{ overflow:'hidden', minHeight:0 }}>
          <div style={{ display:'flex', flexDirection:'column' }}>
            {items.map((it, i) => {
              const active = it.state === 'active';
              return (
                <div key={i} style={{ display:'flex', alignItems:'center', gap:12, padding:'11px 0',
                  borderBottom: i < items.length-1 ? '1px solid var(--line-soft)' : 'none' }}>
                  <span style={{ width:24, height:24, flexShrink:0, borderRadius:'50%', display:'flex',
                    alignItems:'center', justifyContent:'center',
                    background: it.state==='done' ? 'var(--accent)' : active ? 'var(--accent-soft)' : 'var(--surface-sunken)',
                    color: it.state==='done' ? '#fff' : active ? 'var(--accent)' : 'var(--text-tertiary)' }}>
                    {it.state==='done' ? Ai('check',14) : <span style={{ fontSize:11, fontWeight:700 }}>{i+1}</span>}
                  </span>
                  <span style={{ flex:1, fontSize:'var(--fs-subhead)', fontWeight: active ? 600 : 500,
                    color: it.state==='pending' ? 'var(--text-secondary)' : 'var(--text-primary)',
                    whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{it.ex}</span>
                  {active && <Badge tone="signal">aktiv</Badge>}
                  <span style={{ fontSize:'var(--fs-caption)', color:'var(--text-tertiary)', fontVariantNumeric:'tabular-nums' }}>{it.sets}</span>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </Card>
  );
}

/* ── Adjust sheet (weight / reps steppers) ───────────────────── */
function AdjustSheet({ open, s, onClose, onSave }) {
  const [kg, setKg] = React.useState(0);
  const [reps, setReps] = React.useState(0);
  React.useEffect(() => { if (open && s) { setKg(parseFloat(String(s.kg).replace(',','.'))||0); setReps(s.reps); } }, [open, s]);
  if (!s) return null;
  const fmt = v => (Number.isInteger(v) ? String(v) : v.toFixed(1)).replace('.', ',');
  return (
    <div onClick={onClose} style={{ position:'absolute', inset:0, zIndex:50, display:'flex', alignItems:'flex-end',
      background:'rgba(20,35,59,0.34)', backdropFilter:'blur(2px)',
      opacity: open ? 1 : 0, pointerEvents: open ? 'auto' : 'none', transition:'opacity var(--dur-base) var(--ease-standard)' }}>
      <div onClick={e=>e.stopPropagation()} style={{ width:'100%', background:'var(--surface-card)',
        borderRadius:'var(--r-xl) var(--r-xl) 0 0', padding:'14px 20px 28px',
        transform: open ? 'translateY(0)' : 'translateY(100%)', transition:'transform var(--dur-base) var(--ease-out)',
        boxShadow:'0 -8px 40px rgba(20,35,59,0.18)' }}>
        <div style={{ width:38, height:5, borderRadius:3, background:'var(--line)', margin:'0 auto 16px' }} />
        <div style={{ fontSize:'var(--fs-headline)', fontWeight:700, color:'var(--text-primary)', marginBottom:4 }}>Satz anpassen</div>
        <div style={{ fontSize:'var(--fs-caption)', color:'var(--text-secondary)', marginBottom:18 }}>{s.ex} · Satz {s.set}</div>
        <Stepper label="Gewicht" unit="kg" value={fmt(kg)} onMinus={()=>setKg(v=>Math.max(0, +(v-2.5).toFixed(1)))} onPlus={()=>setKg(v=>+(v+2.5).toFixed(1))} />
        <div style={{ height:12 }} />
        <Stepper label="Wiederholungen" unit="Wdh." value={reps} onMinus={()=>setReps(v=>Math.max(0,v-1))} onPlus={()=>setReps(v=>v+1)} />
        <Button fullWidth size="lg" style={{ marginTop:22 }} onClick={()=>onSave({ kg: fmt(kg), reps })}>Übernehmen</Button>
      </div>
    </div>
  );
}
function Stepper({ label, unit, value, onMinus, onPlus }) {
  return (
    <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between',
      padding:'14px 16px', borderRadius:'var(--r-md)', background:'var(--surface-sunken)' }}>
      <div>
        <div style={{ fontSize:'var(--fs-micro)', letterSpacing:'.5px', textTransform:'uppercase',
          fontWeight:700, color:'var(--text-tertiary)' }}>{label}</div>
        <div style={{ display:'flex', alignItems:'baseline', gap:5, marginTop:3 }}>
          <span style={{ fontFamily:'var(--font-rounded)', fontWeight:700, fontSize:26, color:'var(--text-primary)',
            fontVariantNumeric:'tabular-nums' }}>{value}</span>
          <span style={{ fontSize:'var(--fs-caption)', color:'var(--text-secondary)' }}>{unit}</span>
        </div>
      </div>
      <div style={{ display:'flex', gap:8 }}>
        <button onClick={onMinus} style={stepBtn}>{Ai('minus',18)}</button>
        <button onClick={onPlus} style={{ ...stepBtn, background:'var(--accent)', color:'#fff' }}>{Ai('plus',18)}</button>
      </div>
    </div>
  );
}
const stepBtn = { width:40, height:40, borderRadius:'var(--r-sm)', border:'none', cursor:'pointer',
  background:'var(--surface-card)', color:'var(--text-primary)', display:'flex', alignItems:'center', justifyContent:'center',
  boxShadow:'inset 0 0 0 1px var(--line)' };

/* ── Full orchestrating screen (shared by standalone + merged app) ──
   Renders navbar + scrollable content + rest/adjust overlays. NOT the
   phone frame, status bar, or tweaks panel — the host provides those.
   Props: onClose() · restStyle ('inline'|'kompakt'|'vollbild') · showLast
   ─────────────────────────────────────────────────────────────────── */
const AW_SEQ = [
  { ex:'Bankdrücken', icon:'dumbbell', set:3, of:4, kg:'82,5', reps:8, lastKg:'80', lastReps:8,
    pr:{ oneRM:'104,2' }, rest:90, restNow:72, next:'Bankdrücken · Satz 4' },
  { ex:'Bankdrücken', icon:'dumbbell', set:4, of:4, kg:'82,5', reps:7, lastKg:'80', lastReps:7,
    rest:120, restNow:96, next:'Schrägbankdrücken KH · Satz 1' },
  { ex:'Schrägbankdrücken KH', icon:'dumbbell', set:1, of:3, kg:'30', reps:10, lastKg:'30', lastReps:9,
    suggestion:true, rest:90, restNow:74, next:'Schrägbankdrücken KH · Satz 2' },
  { ex:'Trizeps-Pushdown', icon:'cable', set:1, of:3, kg:'35', reps:12, lastKg:'32,5', lastReps:12,
    superset:{ round:1, rounds:3, names:['Pushdown','Dips'], cur:0 }, rest:60, restNow:48, next:'Dips · Runde 1' },
];
const AW_LIST = [
  { ex:'Aufwärmen', sets:'fertig', state:'done' },
  { ex:'Bankdrücken', sets:'3/4', state:'active' },
  { ex:'Schrägbankdrücken KH', sets:'0/3', state:'pending' },
  { ex:'Butterfly', sets:'0/3', state:'pending' },
  { ex:'Trizeps · Superset', sets:'0/3', state:'pending' },
];

const awNavBtn = { width:38, height:38, flexShrink:0, borderRadius:'50%', border:'none', cursor:'pointer',
  display:'flex', alignItems:'center', justifyContent:'center',
  background:'var(--surface-card)', boxShadow:'var(--shadow-sm)', color:'var(--text-secondary)' };
const awFinish = { width:'auto', padding:'0 14px', height:36, gap:6, borderRadius:'var(--r-pill)', border:'none', cursor:'pointer',
  display:'inline-flex', alignItems:'center', background:'var(--accent-soft)', color:'var(--accent)',
  fontFamily:'var(--font-sans)', fontWeight:600, fontSize:13 };

function ActiveWorkoutScreen({ onClose, restStyle = 'inline', showLast = true }) {
  const [idx, setIdx] = React.useState(0);
  const [mode, setMode] = React.useState('logging');
  const [done, setDone] = React.useState(5);
  const [vol, setVol] = React.useState(4280);
  const [pr, setPr] = React.useState(null);
  const [rest, setRest] = React.useState({ remaining:72, target:90, next:'' });
  const [sheet, setSheet] = React.useState(false);
  const [seq, setSeq] = React.useState(AW_SEQ);
  const scrollRef = React.useRef(null);
  const close = onClose || (() => {});

  React.useEffect(() => { if (window.lucide) lucide.createIcons(); });

  const s = seq[idx];
  const complete = () => {
    const cur = seq[idx];
    const w = parseFloat(String(cur.kg).replace(',','.')) || 0;
    setVol(v => Math.round(v + w * cur.reps));
    setDone(d => Math.min(14, d + 1));
    if (cur.pr) setPr({ exercise: cur.ex, oneRM: cur.pr.oneRM });
    const nextIdx = (idx + 1) % seq.length;
    const ns = seq[nextIdx];
    setRest({ remaining: cur.restNow, target: cur.rest, next: `${ns.ex} · Satz ${ns.set}` });
    setIdx(nextIdx);
    setMode('resting');
    if (scrollRef.current) scrollRef.current.scrollTop = 0;
  };
  const skipRest = () => { setPr(null); setMode('logging'); if (scrollRef.current) scrollRef.current.scrollTop = 0; };
  const adjustRest = (d) => setRest(r => ({ ...r, remaining: Math.max(0, r.remaining + d) }));
  const saveAdjust = ({ kg, reps }) => { setSeq(arr => arr.map((x,i) => i===idx ? { ...x, kg, reps } : x)); setSheet(false); };

  const resting = mode === 'resting';
  const restCompact = resting && restStyle === 'kompakt';
  const restInline  = resting && restStyle === 'inline';
  const restFull    = resting && restStyle === 'vollbild';
  const restProps = { remaining: rest.remaining, target: rest.target, next: rest.next, onSkip: skipRest, onAdjust: adjustRest };

  return (
    <div style={{ position:'relative', height:'100%', display:'flex', flexDirection:'column', overflow:'hidden' }}>
      {/* navbar */}
      <div style={{ flexShrink:0, display:'flex', alignItems:'center', justifyContent:'space-between', padding:'2px 16px 8px' }}>
        <button style={awNavBtn} onClick={close} aria-label="Zurück">{Ai('chevron-left',19)}</button>
        <span style={{ fontSize:15, fontWeight:700, letterSpacing:'-0.2px', color:'var(--text-primary)' }}>Aktives Training</span>
        <button style={awFinish} onClick={close}>{Ai('flag',16)} Beenden</button>
      </div>

      {/* scroll */}
      <div ref={scrollRef} style={{ flex:1, overflowY:'auto', overflowX:'hidden' }}>
        <StatusHeader elapsed="24:18" volume={vol >= 1000 ? (vol/1000).toFixed(1).replace('.',',')+' t' : vol+' kg'}
          done={done} total={14} progress={done/14} hr={138} kcal={214} plan="Push Day A" paused={false} />
        {restCompact && <RestPill {...restProps} />}
        {pr && <div style={{ marginTop: restCompact ? 14 : 0 }}><PRBanner exercise={pr.exercise} oneRM={pr.oneRM} /></div>}
        <div style={{ display:'flex', flexDirection:'column', gap:14, padding:'14px 0 26px' }}>
          <div style={{ padding:'0 20px' }}>
            {restInline
              ? <RestCard {...restProps} />
              : <SetCard s={s} showLast={showLast} onAdjust={()=>setSheet(true)} onComplete={complete} />}
          </div>
          <div style={{ padding:'0 20px' }}>
            <ExerciseList items={AW_LIST} />
          </div>
        </div>
      </div>

      {/* vollbild rest overlay */}
      <div style={{ position:'absolute', inset:0, zIndex:45, background:'rgba(20,35,59,0.40)', backdropFilter:'blur(3px)',
        display:'flex', alignItems:'center', padding:'0 20px',
        opacity: restFull ? 1 : 0, pointerEvents: restFull ? 'auto' : 'none',
        transition:'opacity var(--dur-base) var(--ease-standard)' }}>
        <div style={{ width:'100%' }}>{restFull && <RestCard {...restProps} />}</div>
      </div>

      <AdjustSheet open={sheet} s={s} onClose={()=>setSheet(false)} onSave={saveAdjust} />
    </div>
  );
}

Object.assign(window, {
  MC_AW_StatusHeader: StatusHeader,
  MC_AW_RestPill: RestPill,
  MC_AW_RestCard: RestCard,
  MC_AW_PRBanner: PRBanner,
  MC_AW_SetCard: SetCard,
  MC_AW_ExerciseList: ExerciseList,
  MC_AW_AdjustSheet: AdjustSheet,
  MC_ActiveWorkoutScreen: ActiveWorkoutScreen,
  MC_awIcon: Ai,
});
