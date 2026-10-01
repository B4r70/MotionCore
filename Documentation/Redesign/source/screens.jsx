/* ─────────────────────────────────────────────────────────────
   MotionCore — App UI Kit · shared screen library
   Redesign 2026 (Calm). Recreates the iOS app (5 tabs) with the
   design-system components from window.MotionCoreDesignSystem_2f47a0.
   Direction: airier spacing, flat hairline cards, teal lead accent,
   one quiet hue per metric, minimalist charts.
   ───────────────────────────────────────────────────────────── */

const DS = window.MotionCoreDesignSystem_2f47a0;
const { Button, Card, Chip, Badge, StatTile, SectionHeader,
        ProgressRing, Sparkline, FactorBar, TabBar } = DS;

const I = (n, size) => <i data-lucide={n} style={size ? { width: size, height: size } : undefined}></i>;

const GAP = 'var(--mc-gap, 16px)';   // outer stack gap — density-tweakable
const PAD = '0 20px 22px';
const chartProps = (chart) => chart === 'gefüllt'
  ? { fill: true, strokeWidth: 2.5 }
  : { fill: false, strokeWidth: 2 };

/* ── Small shared bits ───────────────────────────────────────── */

function ScreenHead({ title, sub }) {
  return (
    <div style={{ padding: '10px 20px 2px' }}>
      <div style={{ fontFamily: 'var(--font-sans)', fontSize: 'var(--fs-title)', fontWeight: 700,
        letterSpacing: '-0.5px', color: 'var(--text-primary)' }}>{title}</div>
      {sub && <div style={{ fontSize: 'var(--fs-subhead)', color: 'var(--text-secondary)', marginTop: 3 }}>{sub}</div>}
    </div>
  );
}

function WeekStrip() {
  const days = [['M',1],['D',1],['M',1],['D',0],['F',1],['S',0],['S',0]];
  return (
    <Card>
      <SectionHeader title="Diese Woche" eyebrow="4 von 5 Tagen"
        action={<span style={{ color:'var(--text-tertiary)' }}>{I('chevron-right')}</span>} />
      <div style={{ display:'flex', justifyContent:'space-between' }}>
        {days.map(([d, on], i) => (
          <div key={i} style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:8 }}>
            <span style={{ fontSize:'var(--fs-micro)', fontWeight:700, color:'var(--text-tertiary)' }}>{d}</span>
            <span style={{ width:30, height:30, borderRadius:'50%',
              display:'flex', alignItems:'center', justifyContent:'center',
              background: on ? 'var(--teal-600)' : 'var(--surface-sunken)',
              color: on ? '#fff' : 'var(--text-tertiary)' }}>
              {on ? I('check', 15) : <span style={{ fontSize:11 }}>{15+i}</span>}
            </span>
          </div>
        ))}
      </div>
    </Card>
  );
}

/* ── 1 · Übersicht (dashboard) ───────────────────────────────── */

function SummaryScreen({ onStart, chart = 'minimal' }) {
  return (
    <div style={{ display:'flex', flexDirection:'column', gap:GAP, padding:PAD }}>
      <div style={{ padding:'6px 0 0' }}>
        <div style={{ fontFamily:'var(--font-sans)', fontSize:'var(--fs-title)', fontWeight:700,
          letterSpacing:'-0.5px', color:'var(--text-primary)' }}>Guten Morgen, Bartosz</div>
        <div style={{ fontSize:'var(--fs-subhead)', color:'var(--text-secondary)', marginTop:3 }}>Montag, 16. Juni</div>
      </div>

      {/* Hero — readiness ring + recommended session */}
      <Card>
        <div style={{ display:'flex', alignItems:'center', gap:18 }}>
          <ProgressRing value={82} size={104} stroke={9} tone="signal" display="82" label="Tagesform" />
          <div style={{ flex:1, minWidth:0 }}>
            <div style={{ fontSize:'var(--fs-micro)', letterSpacing:'.6px', textTransform:'uppercase',
              fontWeight:700, color:'var(--text-tertiary)' }}>Empfohlen heute</div>
            <div style={{ fontSize:'var(--fs-headline)', fontWeight:700, color:'var(--text-primary)',
              marginTop:4, letterSpacing:'-0.2px' }}>Push · Brust · Schultern</div>
            <div style={{ fontSize:'var(--fs-caption)', color:'var(--text-secondary)', marginTop:2 }}>2 Muskelgruppen erholt · ~55 min</div>
            <Button size="sm" onClick={onStart} icon={I('play',15)} style={{ marginTop:12 }}>Training starten</Button>
          </div>
        </div>
      </Card>

      {/* Quiet metric strip */}
      <div style={{ display:'grid', gridTemplateColumns:'repeat(3,1fr)', gap:10 }}>
        <StatTile label="Erholung" value="88" unit="%" tone="sage" />
        <StatTile label="Streak" value="10" unit="d" tone="alert" />
        <StatTile label="Ø Puls" value="132" tone="info" />
      </div>

      {/* Chip row */}
      <div style={{ display:'flex', gap:8, overflowX:'auto', paddingBottom:2 }}>
        <Chip tone="signal" icon={I('zap',15)}>Level 7</Chip>
        <Chip tone="sage" icon={I('trending-up',15)}>Volumen +6%</Chip>
        <Chip tone="neutral" icon={I('heart',15)}>Ø 132 bpm</Chip>
      </div>

      {/* Recovery */}
      <Card>
        <SectionHeader title="Muskel-Erholung" eyebrow="Bereit zu trainieren"
          action={<span style={{ color:'var(--text-tertiary)' }}>{I('chevron-right')}</span>} />
        <div style={{ display:'flex', flexDirection:'column', gap:13, marginTop:2 }}>
          <FactorBar label="Brust" value={92} display="erholt" tone="sage" />
          <FactorBar label="Rücken" value={68} tone="signal" />
          <FactorBar label="Beine" value={42} display="Schonung" tone="alert" />
        </div>
      </Card>

      {/* Week volume */}
      <Card>
        <SectionHeader title="Trainingsvolumen" subtitle="Diese Woche · 184 t" />
        <div style={{ marginTop:6 }}>
          <Sparkline data={[62,65,60,70,74,71,78,82]} width={300} height={58} tone="signal" {...chartProps(chart)} />
        </div>
      </Card>

      <WeekStrip />
    </div>
  );
}

/* ── 2 · Workouts ────────────────────────────────────────────── */

const SESSIONS = [
  { icon:'dumbbell', tone:'signal', title:'Push · Oberkörper', date:'Heute · 14:20', meta:'12 480 kg · 48 min', pr:true },
  { icon:'bike', tone:'sage', title:'E-Bike Tour', date:'Gestern · 08:05', meta:'28,4 km · 412 m ↑', pr:false },
  { icon:'dumbbell', tone:'signal', title:'Pull · Rücken', date:'Sa · 16:40', meta:'9 850 kg · 52 min', pr:false },
  { icon:'heart-pulse', tone:'info', title:'Crosstrainer', date:'Fr · 19:10', meta:'540 kcal · 35 min', pr:false },
];

function WorkoutsScreen({ filter, setFilter, onStart }) {
  const tones = { signal:'var(--readiness-soft)', sage:'var(--recovery-soft)', info:'var(--info-soft)' };
  const fg = { signal:'var(--teal-600)', sage:'var(--green-700)', info:'var(--sky-600)' };
  return (
    <div style={{ display:'flex', flexDirection:'column', gap:GAP, padding:PAD }}>
      <ScreenHead title="Workouts" />
      <div style={{ display:'flex', gap:8, overflowX:'auto', padding:'0 20px', margin:'0 -20px' }}>
        {['Alle','Kraft','Cardio','Outdoor'].map(f => (
          <Chip key={f} selected={filter===f} onClick={()=>setFilter(f)}>{f}</Chip>
        ))}
      </div>
      <div style={{ display:'flex', flexDirection:'column', gap:10 }}>
        {SESSIONS.map((s, i) => (
          <Card key={i} padding="md" interactive>
            <div style={{ display:'flex', alignItems:'center', gap:13 }}>
              <span style={{ width:44, height:44, borderRadius:'var(--r-md)', flexShrink:0,
                display:'flex', alignItems:'center', justifyContent:'center',
                background:tones[s.tone], color:fg[s.tone] }}>{I(s.icon, 21)}</span>
              <div style={{ minWidth:0, flex:1 }}>
                <div style={{ display:'flex', alignItems:'center', gap:8 }}>
                  <span style={{ fontSize:'var(--fs-subhead)', fontWeight:600, color:'var(--text-primary)' }}>{s.title}</span>
                  {s.pr && <Badge tone="alert" solid dot>PR</Badge>}
                </div>
                <div style={{ fontSize:'var(--fs-caption)', color:'var(--text-tertiary)', marginTop:2 }}>{s.date}</div>
              </div>
              <div style={{ textAlign:'right' }}>
                <div style={{ fontSize:'var(--fs-caption)', fontWeight:600, color:'var(--text-secondary)',
                  fontVariantNumeric:'tabular-nums' }}>{s.meta}</div>
              </div>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}

/* ── 3 · Statistik ───────────────────────────────────────────── */

function StatsScreen({ tf, setTf, chart = 'minimal' }) {
  return (
    <div style={{ display:'flex', flexDirection:'column', gap:GAP, padding:PAD }}>
      <ScreenHead title="Statistik" />
      <div style={{ display:'flex', gap:8 }}>
        {['Woche','Monat','Jahr'].map(f => (
          <Chip key={f} selected={tf===f} onClick={()=>setTf(f)}>{f}</Chip>
        ))}
      </div>
      <Card>
        <SectionHeader title="Trainingsvolumen" subtitle="Gesamt 184 t · +6% vs. Vorwoche" />
        <div style={{ marginTop:6 }}>
          <Sparkline data={[120,132,128,140,138,150,162,158,170,184]} width={300} height={74} tone="signal" {...chartProps(chart)} />
        </div>
      </Card>
      <Card>
        <SectionHeader title="Persönliche Rekorde" action={<Badge tone="alert">3 neu</Badge>} />
        <div style={{ display:'flex', flexDirection:'column' }}>
          {[['Bankdrücken','92,5 kg','heute'],['Kreuzheben','160 kg','vor 3 T'],['Kniebeuge','130 kg','vor 1 W']].map(([n,v,d],i)=>(
            <div key={i} style={{ display:'flex', alignItems:'center', gap:12, padding:'12px 0',
              borderBottom: i<2 ? '1px solid var(--line-soft)' : 'none' }}>
              <span style={{ color:'var(--amber-600)' }}>{I('trophy',19)}</span>
              <span style={{ flex:1, fontSize:'var(--fs-subhead)', fontWeight:500, color:'var(--text-primary)' }}>{n}</span>
              <span style={{ fontFamily:'var(--font-rounded)', fontWeight:700, fontSize:'var(--fs-subhead)',
                color:'var(--text-primary)', fontVariantNumeric:'tabular-nums' }}>{v}</span>
              <span style={{ fontSize:'var(--fs-caption)', color:'var(--text-tertiary)', width:48, textAlign:'right' }}>{d}</span>
            </div>
          ))}
        </div>
      </Card>
      <Card>
        <SectionHeader title="Workouts nach Typ" />
        <div style={{ display:'flex', flexDirection:'column', gap:13 }}>
          <FactorBar label="Kraft" value={64} display="23×" tone="signal" />
          <FactorBar label="Cardio" value={28} display="10×" tone="sage" />
          <FactorBar label="Outdoor" value={8} display="3×" tone="info" />
        </div>
      </Card>
    </div>
  );
}

/* ── 4 · Body ─────────────────────────────────────────────────── */

function BodyScreen() {
  return (
    <div style={{ display:'flex', flexDirection:'column', gap:GAP, padding:PAD }}>
      <ScreenHead title="Body" />
      <Card>
        <SectionHeader title="Erholung gesamt" eyebrow="Heute" />
        <div style={{ display:'flex', justifyContent:'center', padding:'6px 0 10px' }}>
          <ProgressRing value={78} size={172} stroke={11} tone="sage" label="erholt" sublabel="3 Gruppen bereit" />
        </div>
      </Card>
      <Card>
        <SectionHeader title="Körpermaße" subtitle="Zuletzt vor 2 Tagen"
          action={<Button variant="ghost" size="sm" icon={I('plus',15)}>Eintrag</Button>} />
        <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:10 }}>
          <StatTile label="Gewicht" value="82,4" unit="kg" tone="signal" trend="0,6" trendDir="down" />
          <StatTile label="Körperfett" value="14,2" unit="%" tone="sage" trend="0,4" trendDir="down" />
          <StatTile label="Muskelmasse" value="38,1" unit="kg" tone="info" trend="0,3" trendDir="up" />
          <StatTile label="Taille" value="81" unit="cm" tone="alert" trend="1,0" trendDir="down" />
        </div>
      </Card>
      <Card>
        <SectionHeader title="Erholung nach Gruppe" />
        <div style={{ display:'flex', flexDirection:'column', gap:13 }}>
          <FactorBar label="Brust" value={92} display="erholt" tone="sage" />
          <FactorBar label="Schultern" value={84} display="erholt" tone="sage" />
          <FactorBar label="Rücken" value={68} tone="signal" />
          <FactorBar label="Arme" value={55} tone="signal" />
          <FactorBar label="Beine" value={42} display="Schonung" tone="alert" />
        </div>
      </Card>
    </div>
  );
}

/* ── 5 · Training ─────────────────────────────────────────────── */

const PLANS = [
  { name:'Push', sub:'Brust · Schultern · Trizeps', ex:6, min:55, tone:'signal' },
  { name:'Pull', sub:'Rücken · Bizeps', ex:5, min:48, tone:'sage' },
  { name:'Legs', sub:'Beine · Waden · Core', ex:7, min:60, tone:'info' },
];

function TrainingScreen({ onStart }) {
  const tones = { signal:'var(--readiness-soft)', sage:'var(--recovery-soft)', info:'var(--info-soft)' };
  const fg = { signal:'var(--teal-600)', sage:'var(--green-700)', info:'var(--sky-600)' };
  return (
    <div style={{ display:'flex', flexDirection:'column', gap:GAP, padding:PAD }}>
      <ScreenHead title="Training" sub="3 Pläne · Push/Pull/Legs Split" />
      <div style={{ display:'flex', flexDirection:'column', gap:10 }}>
        {PLANS.map((p, i) => (
          <Card key={i}>
            <div style={{ display:'flex', alignItems:'flex-start', gap:13 }}>
              <span style={{ width:46, height:46, borderRadius:'var(--r-md)', flexShrink:0,
                display:'flex', alignItems:'center', justifyContent:'center', fontFamily:'var(--font-rounded)',
                fontWeight:700, fontSize:18, background:tones[p.tone], color:fg[p.tone] }}>{p.name[0]}</span>
              <div style={{ flex:1, minWidth:0 }}>
                <div style={{ fontSize:'var(--fs-headline)', fontWeight:700, color:'var(--text-primary)',
                  letterSpacing:'-0.2px' }}>{p.name}</div>
                <div style={{ fontSize:'var(--fs-caption)', color:'var(--text-secondary)', marginTop:1 }}>{p.sub}</div>
                <div style={{ display:'flex', gap:8, marginTop:10 }}>
                  <Badge tone="neutral">{p.ex} Übungen</Badge>
                  <Badge tone="neutral">~{p.min} min</Badge>
                </div>
              </div>
            </div>
            <Button fullWidth tone={p.tone} variant="secondary"
              size="sm" style={{ marginTop:14 }} icon={I('play',15)} onClick={onStart}>Plan starten</Button>
          </Card>
        ))}
      </div>
    </div>
  );
}

Object.assign(window, {
  MC_SummaryScreen: SummaryScreen,
  MC_WorkoutsScreen: WorkoutsScreen,
  MC_StatsScreen: StatsScreen,
  MC_BodyScreen: BodyScreen,
  MC_TrainingScreen: TrainingScreen,
  MC_icon: I,
});
