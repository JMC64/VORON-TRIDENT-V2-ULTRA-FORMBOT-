#!/usr/bin/env bash
# Formbot Voron Trident R2 Ultra - offline interactive manuals with kit notes
#
# Builds a fully offline copy of the unofficial interactive manuals by Mairis Skuja:
#   - Voron Trident R2, with the Formbot R2 Ultra kit notes overlaid  -> http://localhost:8766/
#   - Voron Stealthburner R2                                          -> http://localhost:8766/stealthburner/
# and serves them locally (browser cache disabled).
#
# Requirements: git, node/npm, python3.  Usage: bash trident-formbot-offline.sh
# Keep this script OUTSIDE the output folder ($OUT below): that folder is deleted and rebuilt on every run.
set -euo pipefail

BASE="$HOME/voron-trident-formbot-manual"
REPO="$BASE/repo"
REPO_SB="$BASE/repo-stealthburner"
DEPS="$BASE/deps"
OUT="$BASE/offline"
PORT=8766

SELF="$(readlink -f "$0")"
case "$SELF" in
  "$OUT"/*) echo "ERROR: this script is inside $OUT, which is deleted on every run. Move it elsewhere first." >&2; exit 1 ;;
esac

mkdir -p "$BASE"

# 1. Clone (or update) both manuals
clone_or_pull() {
  if [ -d "$2/.git" ]; then
    git -C "$2" pull --ff-only
  else
    git clone --depth 1 "$1" "$2"
  fi
}
clone_or_pull https://github.com/mairisskuja/voron-trident-r2-interactive-manual.git "$REPO"
clone_or_pull https://github.com/mairisskuja/voron-stealthburner-r2-interactive-manual.git "$REPO_SB"

# 2. Libraries, at the exact versions the pages use
mkdir -p "$DEPS"
cd "$DEPS"
[ -f "$DEPS/package.json" ] || npm init -y >/dev/null
npm install --no-audit --no-fund three@0.160.0 jspdf@2.5.1 svg2pdf.js@2.2.1 @fontsource-variable/nunito

# 3. Copy the built pages and a shared vendor/ folder
rm -rf "$OUT"
cp -r "$REPO/dist" "$OUT"
cp -r "$REPO_SB/dist" "$OUT/stealthburner"
mkdir -p "$OUT/vendor/three" "$OUT/vendor/fonts" "$OUT/formbot"
cp -r "$DEPS/node_modules/three/build" "$DEPS/node_modules/three/examples" "$OUT/vendor/three/"
cp "$DEPS/node_modules/jspdf/dist/jspdf.umd.min.js" "$OUT/vendor/"
cp "$DEPS/node_modules/svg2pdf.js/dist/svg2pdf.umd.min.js" "$OUT/vendor/"
cp "$DEPS/node_modules/@fontsource-variable/nunito/files/nunito-latin-wght-normal.woff2" "$OUT/vendor/fonts/"

# 4. Formbot notes (data, overlay script and style) - Trident manual only
cat > "$OUT/formbot/notes.js" <<'FORMBOT_EOF'
// Formbot Voron Trident R2 Ultra kit notes, mapped onto the steps of the unofficial
// Voron Trident R2 interactive manual (github.com/mairisskuja/voron-trident-r2-interactive-manual).
// Sources: Formbot "Functional parts build notes" (page numbers refer to the Voron Trident R1 manual),
// "Instruction of Trident R2 Ultra" (PDF) and "Wiring Diagram of Trident R2 Ultra" (PDF).
// Fields: steps = interactive-manual step ids ("_general" = general list), kind = skip | change | info | warn,
//         src = source, text = Formbot note, tap = true when the note refers to TAP,
//         remark = note about how the R1 page was mapped to the R2 step (not from Formbot).
window.FB_NOTES = [
  // ---------- General ----------
  {steps: ['_general'], kind: 'info', src: 'Formbot notes · intro',
   text: "Start with the Stock Voron Trident R1 Manual (the one on the Voron Trident R1 Git is not the most recent one). Be aware that the vT Manual uses a 250mm Version of the Trident, so some dimensions may seem wrong if you build a 300mm/350mm Version."},
  {steps: ['_general'], kind: 'info', src: 'How the notes were mapped', remark:
   "The Formbot notes cite pages of the Voron Trident R1 manual. Each cited page was compared with the latest R1 manual (VoronDesign/Voron-Trident, commit 8d08cd9, 2025-11-28) and attached to the R2 step that does the same job. The original R1 page is shown on every note."},
  {steps: ['_general'], kind: 'warn', src: 'TAP or Cartographer', remark:
   "The build notes describe the base kit with TAP / OptoTap (probe and Z endstop). The R2 Ultra instruction and wiring diagram show a Cartographer probe on the CAN board instead, with no Z endstop. Notes marked \"TAP\" apply to kits built with TAP."},

  // ---------- Y axis ----------
  {steps: ['y-endstop-pod'], kind: 'info', src: 'Formbot notes · R1 p.48',
   text: "Skip this step, we use physical endstops and no hall effect ones.",
   remark: "In the R2 manual the microswitch pod is already the default; nothing to change here."},
  {steps: ['y-endstop-pod', 'y-endstop-mount'], kind: 'info', src: 'R2 Ultra wiring diagram',
   text: "The endstop with the long wire labelled \"Y end stop\" goes in this pod under the A motor. It plugs into the Y Endstop port of the Manta M8P."},
  {steps: ['y-rails-prep', 'y-rail-l-place', 'y-rail-r-place'], kind: 'change', src: 'Formbot notes · R1 p.56-60',
   text: "If you are building a 300mm machine you will need to start you screws from the second screw hole in the rails leaving the end holes open to allow space for T-nuts at later steps. Small reminder: The carriages are designed to slide along the rail easily. This unfortunately also includes sliding off the rails. Dropping the carriage likely irreparably damages it. ALWAYS put the little black rubber Carriage stoppers back on the rail (into the holes without screws) until your printer ist up and runnning!"},

  // ---------- X axis ----------
  {steps: ['x-prep-carriage', 'x-prep-bridge'], kind: 'skip', src: 'Formbot notes · R1 p.100-101',
   text: "Skip these steps, you wont use either the inductive probe or a Cable chain on XY.",
   remark: "R1 p.100-101 cover part prep (inserts) and the XY cable chains. Mapped to the probe bracket inserts (step 79) and the cable bridge inserts (step 80). The X carriage inserts themselves are still needed."},
  {steps: ['x-rail'], kind: 'change', src: 'Formbot notes · R1 p.111',
   text: "Again, if you are building a bigger printer than the 250mm version, start at the outer holes and screw the rail down every second hole. Small reminder (again): The carriages are designed to slide along the rail easily. This unfortunately also includes sliding off the rails. Dropping the carriage likely irreparably damages it. ALWAYS put the little black rubber Carriage stoppers back on the rail (into the holes without screws) until your printer ist up and runnning!"},
  {steps: ['x-joint-right'], kind: 'change', src: 'Formbot notes · R1 p.114',
   text: "Install all 4 screws on the right XY Joint.",
   remark: "In R1, two of these screws waited for the XY endstop pod. In R2 the top screws come with the cable bridge (step 97), which these notes skip."},
  {steps: ['x-bridge'], kind: 'skip', src: 'Formbot notes · R1 p.115',
   text: "Leave this step out, you dont use a cable chain on X and Y.",
   remark: "See step 95: in R2 the cable bridge also carries the top screws of the right XY joint."},

  // ---------- Belts / X carriage ----------
  {steps: ['bt-hooks', 'bt-clamp'], kind: 'change', tap: true, src: 'Formbot notes · R1 p.122-123',
   text: "You use a different X carriage / Probe. Fix the belts with some tape and proceed with the belt Routing. After you routed the belts, fix them on the other side with some tape as well."},
  {steps: ['bt-capture', 'bt-tension'], kind: 'skip', tap: true, src: 'Formbot notes · R1 p.131-133',
   text: "Skip these steps, you will do it later after tap is assembled."},
  {steps: ['bt-capture', 'bt-tension'], kind: 'change', tap: true, src: 'Formbot notes · R1 p.133 + Tap p.33',
   text: "X Carriage: After finishing the AB-Belts Routing, switch to the TAP Manual. Optotap is used as the sensor. Be sure to take a look into the R8_errata.md document, it Highlights some important changes from the Manual and install the X Endstop switch. After you have installed Tap successfully and have the AB belts fixed in the tap carriage, switch to page 134 of the Trident Manual."},
  {steps: ['bt-probe'], kind: 'skip', tap: true, src: 'Formbot notes · R1 p.135-137',
   text: "Skip these steps since you don't use the stock X carriage but instead you use tap."},

  // ---------- Z endstop ----------
  {steps: ['bed-zend-build', 'bed-zend-shaft', 'bed-zend-mount'], kind: 'skip', tap: true, src: 'Formbot notes · R1 p.144-145 & 159',
   text: "You don't use this endstop. Your endstop is Tap."},
  {steps: ['bed-zend-build', 'bed-zend-shaft', 'bed-zend-mount'], kind: 'info', src: 'R2 Ultra wiring diagram',
   text: "The R2 Ultra wiring diagram has no Z endstop: the Cartographer probe connects to the CAN board."},

  // ---------- Stealthburner / CAN ----------
  {steps: ['sb-build'], kind: 'info', src: 'Formbot notes · R1 p.162-163', text: "Switch to the Stealthburner manual."},
  {steps: ['sb-build'], kind: 'change', src: 'Formbot notes · Stealthburner p.13', text: "You use a Toolhead PCB, so install these two heat inserts."},
  {steps: ['sb-build'], kind: 'skip', src: 'Formbot notes · Stealthburner p.14', text: "Skip"},
  {steps: ['sb-build'], kind: 'info', src: 'Formbot notes · Stealthburner p.30',
   text: "Follow this Video Guide on how to set the gear mesh on your CW2. Follow this video Guide on how to set the Anti-Squish as well."},
  {steps: ['sb-build'], kind: 'skip', src: 'Formbot notes · Stealthburner p.31', text: "Skip for now, we will install our Version of the Anchor later."},
  {steps: ['sb-build'], kind: 'change', src: 'Formbot notes · Stealthburner p.34', text: "You dont need to fix the Cable Cover down with the m3x6 BHCS now, you will need to access this later."},
  {steps: ['sb-build'], kind: 'info', src: 'Formbot notes · Stealthburner p.36-43', text: "All Hotends are mounted in a similar pattern and pretty self-explaining, your hotend mount and hotend will look different."},
  {steps: ['sb-build'], kind: 'warn', src: 'Formbot notes · Stealthburner p.46-51', text: "Be very careful with the cables, you can easily rip them off the LED PCB which leads to this LED and the following ones not working."},
  {steps: ['sb-build'], kind: 'warn', src: 'Formbot notes · Stealthburner p.53',
   text: "Be sure that your fan blows in the right Direction. Look at the arrows on the fan. Additionally, the Sticker on the fan is on the back pointing towards the Hotend. You want the fan to blow air into the hotend, not trying to pull the air out. This destroys your fan and your whole hotend mount because of heatcreep."},
  {steps: ['sb-build'], kind: 'change', src: 'Formbot notes · Stealthburner p.56', text: "You dont need to screw the 5015 fan into the SB Face, you will install the SB0000 Fan PCB there later."},
  {steps: ['sb-build'], kind: 'info', src: 'Formbot notes · Stealthburner p.58',
   text: "All parts of the Stealthburner are now pretty much finished. Now you will need to install the Can-Board on there and do some basic wiring. Switch to the SB2209 RP2040 Manual."},
  {steps: ['sb-build'], kind: 'change', src: 'Formbot notes · SB2209 p.2', text: "Now you need to screw down the 5015 fan with the SB0000 PCB :)"},
  {steps: ['sb-build'], kind: 'warn', src: 'Formbot notes · SB2209 p.3-4',
   text: "You need to select Vin (24V) for all fans. Be sure to wire Gnd to Gnd and 24V to 24V! Otherwise you will experience magic smoke later."},
  {steps: ['sb-build'], kind: 'skip', src: 'Formbot notes · SB2209 p.5', text: "Skip"},
  {steps: ['sb-build'], kind: 'warn', src: 'Formbot notes · SB2209 p.6', text: "Be sure to wire Gnd to Gnd, Signal to Signal and 24V to 24V! Otherwise you will experience magic smoke later."},
  {steps: ['sb-build'], kind: 'change', src: 'Formbot notes · SB2209 p.13', text: "You Need to set the switch to 1: on; 2: on; 3: off; 4: on (same on the R2 Ultra wiring diagram)."},
  {steps: ['sb-build'], kind: 'skip', src: 'Formbot notes · SB2209 p.15', text: "Skip"},
  {steps: ['sb-build'], kind: 'change', src: 'Formbot notes · SB2209 p.16',
   text: "Be sure to use the endstop labeled \"To CAN_Endstop\" which is the one with the short wires. (X endstop, Endstop port of the CAN board.)"},
  {steps: ['sb-build'], kind: 'skip', src: 'Formbot notes · SB2209 p.18', text: "Skip"},
  {steps: ['sb-build'], kind: 'skip', src: 'Formbot notes · SB2209 p.19', text: "Skip, Stealthburner will be assembled later."},
  {steps: ['sb-build'], kind: 'change', tap: true, src: 'Formbot notes · SB2209 p.24',
   text: "You will need to Strip down the Isolation a bit so you have enough cable length to connect the cable to the PSU and to the Can port. Go back to the Tap Manual page 34 now, flashing the toolhead will be done later. Use the tight cable sleeve around the cable."},
  {steps: ['sb-build', 'wr-toolhead'], kind: 'info', src: 'R2 Ultra wiring diagram',
   text: "On the CAN board (EBB SB2209): X endstop, extruder motor, NTC 100K thermistor, heater, 4010 fan, 5015 blower, 5V RGB and the Cartographer probe."},
  {steps: ['sb-mount'], kind: 'info', tap: true, src: 'Formbot notes · Tap p.36',
   text: "Stealthburner and Tap are now completed and installed. Switch back to p. 164 of the original Trident manual."},

  // ---------- DIN rails / electronics ----------
  {steps: ['wp-din-tnuts', 'wp-din-rails', 'wp-din-slide'], kind: 'change', src: 'Formbot notes · R1 p.173 + wiring diagram',
   text: "Rotate the din rails 90° compared to the original layout. (Wiring diagram: the DIN rails should be parallel to bed extrusions, or else, the wires may be not long enough.)",
   remark: "With the rails rotated, the T-nut positions of step 145 change accordingly."},
  {steps: ['el-pi-bracket', 'el-pi', 'el-psu5'], kind: 'skip', src: 'Formbot notes · R1 p.181-183',
   text: "Skip; Raspberry Pi mounting and 5v PSU mounting is not needed. Instead, mount the CB1 / CM4 on the Manta."},
  {steps: ['el-wago-prep', 'el-wago-mount'], kind: 'change', src: 'Formbot notes · R1 p.191', text: "You use the 3in6 Power Distributor instead."},
  {steps: ['el-psu5-mount'], kind: 'skip', src: 'Formbot notes · R1 p.195', text: "another small reminder, you don't use a 5v PSU."},
  {steps: ['el-pi-mount'], kind: 'skip', src: 'Formbot notes · R1 p.196', text: "small reminder, you dont use a Raspberry Pi."},
  {steps: ['el-xy-pcb'], kind: 'skip', tap: true, src: 'Formbot notes · R1 p.198-200',
   text: "Skip; TAP is your Z-Endstop, your X Endstop sits on Tap and your Y endstop will be mounted on the A Motor mount later."},
  {steps: ['cp-jumpers-remove', 'cp-jumpers-set', 'cp-drivers'], kind: 'change', src: 'Formbot notes · R1 p.202-205',
   text: "Skip these steps, instead configure your Manta like this: M8P_v2 Jumper / Driver marking. Place a Jumper on all yellow marked pins and place the TMC2209s with attached heatsink on all driver ports with a blue circle after installing the jumpers."},

  // ---------- Wiring ----------
  {steps: ['wr-psu-voltage'], kind: 'warn', src: 'Formbot notes · end', text: "Don't power on the printer if you are not 100% sure you wired everything correct!"},
  {steps: ['wr-mains', 'wr-dc'], kind: 'skip', src: 'Formbot notes · R1 p.210, 211, 216', text: "Leave the cables to the 5v PSU out."},
  {steps: ['wr-pi-power'], kind: 'skip', src: 'Formbot notes · R1 p.217', text: "Skip, you dont use a standart Raspberry."},
  {steps: ['wr-controller'], kind: 'change', src: 'Formbot notes · R1 p.218-237',
   text: "The Z-Endstop cables are not needed. For a better Overview of the wiring, use the wiring diagram. Connect the CAN-Cable to the right CAN-Port on the M8P and 24V / GND to the 24V PSU. If you think the cables are not Long enough, you haven't done this step (SB2209 p.24)."},
  {steps: ['wr-b-motor'], kind: 'change', src: 'Formbot notes · R1 p.218-237', text: "Connect the B motor (left motor) to X Motor."},
  {steps: ['wr-a-motor-fans'], kind: 'change', src: 'Formbot notes · R1 p.218-237', text: "Connect the A motor (right motor) to Y Motor."},
  {steps: ['wr-chains-overview', 'wr-chain-x', 'wr-chain-y'], kind: 'skip', src: 'Formbot notes · R1 p.115 + R2 Ultra instruction p.7-13',
   text: "No cable chains on X and Y: the toolhead uses a CAN umbilical on the Metal Movable Hinge. Instruction summary: red bracket and PG7 gland on the cable (14 cm), corrugated sleeve, hinge tied to the cable (13 cm), red bracket on the extruder (M3x20 + M3x8 SHCS), cable to the CAN board, hinge on the top extrusion (M5x10 FHCS + M5 nut), cable down to the bottom chamber, cable clips and sleeve, cable ties, decorative part (M3x8 SHCS + M3 nut), CAN cable to the M8P, red wire to + and black wire to - on the PSU."},
  {steps: ['wr-wiring-path', 'wr-rear-right-post'], kind: 'change', src: 'Formbot notes · R1 p.232',
   text: "Route the Y Endstop cable and the A Motor cables down like the B Motor cable (but on the right side of the printer)."},
  {steps: ['wr-endstops'], kind: 'change', src: 'R2 Ultra wiring diagram',
   text: "Y endstop (long wire) to the Y Endstop port of the M8P. X endstop (short wire, \"To CAN endstop\") to the Endstop port of the CAN board, not the M8P."},

  // ---------- LCD / skirts / panels ----------
  {steps: ['sk-lcd-prep', 'sk-lcd-screen', 'sk-lcd-knob', 'sk-lcd-hinge', 'sk-wiring'], kind: 'change', src: 'Formbot notes · R1 p.242-244, 257',
   text: "Skip these steps and instead mount the klipperscreen. (Display mount referenced by Formbot: printables.com/model/926845-btt-hdmi5-v12-display-mount-voron)"},
  {steps: ['bp-panel'], kind: 'warn', src: 'Formbot notes · R1 p.258',
   text: "Don't close the electronics compartment yet, you will need to acces this while flashing the boards."},
  {steps: ['pn-inlet', 'pn-grill'], kind: 'info', src: 'Formbot notes · R1 p.281',
   text: "Use the big cable sleeve around the exhaust fan cable (if you use the stock exhaust).",
   remark: "The R2 manual has no exhaust fan wiring step; attached to the exhaust cover steps."},

  // ---------- Extras (R2 Ultra instruction) ----------
  {steps: ['pn-next'], kind: 'info', src: 'R2 Ultra instruction p.1-5',
   text: "Wide-angle camera: 2 M5 nuts in the top front extrusion; USB cable through the small hole from below, into the extrusion slot under the trim strip; black part fixed with M5x10 BHCS; camera on the red part (M2x10 self-tapping screws), then clipped into the black part."},
  {steps: ['pn-next'], kind: 'info', src: 'R2 Ultra instruction p.5-7',
   text: "RGB light strips: cable through the rear right corner, one end to the left extrusion and one to the right; strips on the top extrusions with bakelite insulating columns, M3 T-nuts and M3x12 SHCS."},
  {steps: ['pn-next'], kind: 'info', src: 'R2 Ultra instruction p.14-19',
   text: "Nevermore filter: M3 brass inserts, activated carbon bag in the red part, magnets join the two housings, cables in the slot, blowers, WAGO connectors, bracket with M3x12 BHCS, red wires to + and black to -, housing under the bed on the left extrusion (M5 nuts + M5x10 BHCS), cables through the chain to the bottom chamber, connected to the mainboard (blue circle on the diagram)."}
];
FORMBOT_EOF

cat > "$OUT/formbot/overlay.js" <<'FORMBOT_EOF'
// Formbot notes overlay for the Voron Trident R2 interactive manual.
// Reads window.FB_STEPS (step ids in order, generated at build time) and window.FB_NOTES.
(() => {
  const STEPS = window.FB_STEPS || [];
  const NOTES = window.FB_NOTES || [];
  const $ = id => document.getElementById(id);
  const esc = s => String(s).replace(/[&<>"]/g, c => ({'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;'}[c]));
  const KIND = {skip: 'Skip', change: 'Change', info: 'Info', warn: 'Caution'};

  const byStep = new Map();
  for (const n of NOTES) for (const id of n.steps) {
    if (!byStep.has(id)) byStep.set(id, []);
    byStep.get(id).push(n);
  }

  const noteHtml = n => `<div class="fb-note fb-${n.kind}">
      <div class="fb-head"><span class="fb-badge">Formbot</span><span class="fb-kind">${KIND[n.kind] || ''}</span>${n.tap ? '<span class="fb-tap" title="Applies to kits built with TAP">TAP</span>' : ''}<span class="fb-src">${esc(n.src)}</span></div>
      ${n.text ? `<p>${esc(n.text)}</p>` : ''}
      ${n.remark ? `<p class="fb-remark"><b>Mapping note</b> ${esc(n.remark)}</p>` : ''}
    </div>`;

  // ---- Notes in the step dock ----
  let box = null;
  function currentId() { return decodeURIComponent(location.hash.slice(1)); }
  function renderStep() {
    const anchor = $('step-notes');
    if (!anchor) return;
    if (!box || !box.isConnected) {
      box = document.createElement('div');
      box.id = 'fb-notes';
      anchor.insertAdjacentElement('afterend', box);
    }
    const list = byStep.get(currentId()) || [];
    box.hidden = !list.length;
    box.innerHTML = list.map(noteHtml).join('');
  }

  // ---- Marks on the step ticks ----
  function markTicks() {
    const tk = $('ticks');
    if (!tk) return;
    for (const b of tk.querySelectorAll('[data-i]')) {
      const id = STEPS[+b.dataset.i];
      const has = byStep.has(id);
      b.classList.toggle('fb-has', has);
      if (has && !b.title.includes('Formbot')) b.title += ' · Formbot note';
    }
  }

  // ---- Jump to a step without reloading ----
  function goTo(id) {
    const i = STEPS.indexOf(id);
    if (i < 0) return;
    const jump = () => {
      const sel = $('chapter');
      const opt = new Option('', String(i));
      sel.add(opt);
      sel.value = String(i);
      sel.dispatchEvent(new Event('change', {bubbles: true}));
      opt.remove();
    };
    if (document.body.dataset.mode === 'explore') { $('start-building').click(); setTimeout(jump, 50); }
    else jump();
    closePanel();
  }

  // ---- "Formbot" panel listing every note ----
  let panel = null, btn = null;
  function buildPanel() {
    const tools = document.querySelector('#topbar .tools');
    if (!tools) return;
    btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'tbtn fb-btn';
    btn.setAttribute('aria-expanded', 'false');
    btn.title = 'Formbot notes';
    btn.innerHTML = '<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M4 2h6l3 3v9H4z"/><path d="M6 8h5M6 11h5M6 5h2"/></svg><span class="t">Formbot</span>';
    tools.prepend(btn);

    panel = document.createElement('section');
    panel.className = 'panel';
    panel.id = 'fb-panel';
    panel.hidden = true;
    panel.setAttribute('aria-label', 'Formbot notes');
    const general = byStep.get('_general') || [];
    const rows = STEPS.map((id, i) => byStep.has(id) ? `<li><button type="button" class="fb-go" data-id="${esc(id)}"><span class="fb-n">${i + 1}</span><span>${esc((window.FB_TITLES || {})[id] || id)}</span><span class="fb-c">${byStep.get(id).length}</span></button></li>` : '').join('');
    const unknown = [...byStep.keys()].filter(id => id !== '_general' && !STEPS.includes(id));
    panel.innerHTML = `<h2>Formbot notes</h2>
      <p class="lede">Formbot Trident R2 Ultra kit notes, attached to the steps of this manual. Steps with a note carry an orange dot in the bottom bar.</p>
      ${general.map(noteHtml).join('')}
      <h3 class="fb-h3">Steps with a note</h3>
      <ul class="fb-list">${rows}</ul>
      ${unknown.length ? `<p class="fb-remark"><b>Steps not found</b> ${esc(unknown.join(', '))} (the manual may have changed).</p>` : ''}`;
    document.body.appendChild(panel);

    btn.addEventListener('click', e => { e.stopPropagation(); panel.hidden ? openPanel() : closePanel(); });
    panel.addEventListener('click', e => { const b = e.target.closest('.fb-go'); if (b) goTo(b.dataset.id); });
    document.addEventListener('click', e => { if (panel && !panel.hidden && !panel.contains(e.target) && e.target !== btn) closePanel(); });
    document.addEventListener('keydown', e => { if (e.key === 'Escape') closePanel(); });
  }
  function openPanel() {
    for (const p of document.querySelectorAll('.panel:not(#fb-panel)')) p.hidden = true;
    for (const b of document.querySelectorAll('.tbtn[data-panel]')) b.setAttribute('aria-expanded', 'false');
    panel.hidden = false; btn.setAttribute('aria-expanded', 'true');
  }
  function closePanel() { if (panel) { panel.hidden = true; btn.setAttribute('aria-expanded', 'false'); } }

  function init() {
    buildPanel();
    const title = $('step-title'), ticks = $('ticks');
    if (title) new MutationObserver(renderStep).observe(title, {childList: true, characterData: true, subtree: true});
    if (ticks) new MutationObserver(markTicks).observe(ticks, {childList: true});
    renderStep(); markTicks();
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
})();
FORMBOT_EOF

cat > "$OUT/formbot/overlay.css" <<'FORMBOT_EOF'
/* Formbot notes overlay */
:root { --fb: #d9822b; --fb-soft: rgb(217 130 43 / .10); }
:root[data-theme="dark"] { --fb: #f0a24f; --fb-soft: rgb(240 162 79 / .12); }
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { --fb: #f0a24f; --fb-soft: rgb(240 162 79 / .12); } }

#fb-notes { display: grid; gap: 8px; margin-top: 14px; }
#fb-notes[hidden] { display: none; }
.fb-note { border-left: 3px solid var(--fb); background: var(--fb-soft); border-radius: 0 6px 6px 0; padding: 8px 10px; font-size: 13px; color: var(--ink); }
.fb-note.fb-warn { border-left-color: var(--warn); }
.fb-note p { margin: 4px 0 0; line-height: 1.45; }
.fb-head { display: flex; flex-wrap: wrap; align-items: center; gap: 6px; }
.fb-badge { font: 700 10.5px var(--body); letter-spacing: .06em; text-transform: uppercase; color: var(--panel); background: var(--fb); border-radius: 4px; padding: 1px 6px; }
.fb-kind { font: 700 11px var(--body); letter-spacing: .06em; text-transform: uppercase; color: var(--fb); }
.fb-warn .fb-kind { color: var(--warn); }
.fb-tap { font: 700 10.5px var(--body); color: var(--warn); border: 1px solid var(--warn); border-radius: 4px; padding: 0 5px; cursor: help; }
.fb-src { font-size: 11.5px; color: var(--ink-soft); margin-left: auto; }
.fb-remark { color: var(--ink-soft); }
.fb-remark b { font-weight: 700; color: var(--ink); }
.fb-note details { margin-top: 4px; }
.fb-note summary { cursor: pointer; font-size: 11.5px; color: var(--ink-soft); }
.fb-note details p { font-style: italic; color: var(--ink-soft); }

#ticks .tick.fb-has { position: relative; }
#ticks .tick.fb-has::after { content: ""; position: absolute; top: 2px; right: 2px; width: 6px; height: 6px; border-radius: 50%; background: var(--fb); }

.tbtn.fb-btn { color: var(--fb); }
#fb-panel { width: 380px; }
#fb-panel .fb-note { margin-bottom: 8px; }
.fb-h3 { font: 700 11px var(--body); letter-spacing: .06em; text-transform: uppercase; color: var(--accent); margin: 14px 0 6px; }
.fb-list { list-style: none; margin: 0; padding: 0; display: grid; gap: 2px; }
.fb-go { width: 100%; display: flex; align-items: center; gap: 8px; text-align: left; background: none; border: 0; border-radius: 6px; padding: 6px; font: 500 13px var(--body); color: var(--ink); cursor: pointer; }
.fb-go:hover, .fb-go:focus-visible { background: var(--fb-soft); }
.fb-n { flex: none; min-width: 2.2em; font-weight: 700; color: var(--fb); font-variant-numeric: tabular-nums; }
.fb-go span:nth-child(2) { flex: 1; min-width: 0; }
.fb-c { flex: none; font-size: 11px; color: var(--ink-soft); }
FORMBOT_EOF

# 5. Point CDN URLs to vendor/, make the Stealthburner link local, inject the Formbot notes
python3 - "$OUT" <<'EOF'
import sys, re, json
out = sys.argv[1]

def offline(path, vendor):
    h = open(path, encoding='utf-8').read()
    h = h.replace('https://cdn.jsdelivr.net/npm/three@0.160.0/', vendor + 'three/')
    h = h.replace('https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js', vendor + 'jspdf.umd.min.js')
    h = h.replace('https://cdn.jsdelivr.net/npm/svg2pdf.js@2.2.1/dist/svg2pdf.umd.min.js', vendor + 'svg2pdf.umd.min.js')
    h = re.sub(r'<link rel="preconnect" href="https://fonts\.g[^>]*>\n?', '', h)
    h = h.replace(
        '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Nunito:wght@300..800&display=swap">',
        '<style>@font-face{font-family:"Nunito";font-style:normal;font-weight:300 800;font-display:swap;'
        'src:url("' + vendor + 'fonts/nunito-latin-wght-normal.woff2") format("woff2")}</style>')
    left = re.findall(r'https://(?:cdn\.jsdelivr|cdnjs|fonts\.g)[^"\' ]*', h)
    print(path.replace(out, '...'), '- CDN references left:', left if left else 'none')
    return h

# Stealthburner manual
p_sb = out + '/stealthburner/index.html'
h_sb = offline(p_sb, '../vendor/')
open(p_sb, 'w', encoding='utf-8').write(h_sb)

# Trident manual
p = out + '/index.html'
h = offline(p, './vendor/')
n_links = h.count('https://iconic-fab.com/voron/stealthburner/r2/')
h = h.replace('https://iconic-fab.com/voron/stealthburner/r2/', './stealthburner/')
print('Links to the Stealthburner manual made local:', n_links)

i = h.find('"steps":[')
if i < 0:
    sys.exit('ERROR: step list not found in index.html (the manual format has changed)')
steps, _ = json.JSONDecoder().raw_decode(h[i + 8:])
ids = [s['id'] for s in steps]
titles = {s['id']: s.get('title', '') for s in steps}
open(out + '/formbot/steps.js', 'w', encoding='utf-8').write(
    'window.FB_STEPS = ' + json.dumps(ids) + ';\nwindow.FB_TITLES = ' + json.dumps(titles, ensure_ascii=False) + ';\n')
notes_src = open(out + '/formbot/notes.js', encoding='utf-8').read()
used = set(re.findall(r"steps:\s*\[([^\]]*)\]", notes_src))
used = {x.strip().strip("'\"") for g in used for x in g.split(',') if x.strip()}
missing = sorted(u for u in used if u != '_general' and u not in ids)
print(f'Steps: {len(ids)}; Formbot notes attached to {len(used - {"_general"})} steps')
print('Note steps not found in the manual:', ', '.join(missing) if missing else 'none')

inject = ('<link rel="stylesheet" href="./formbot/overlay.css">\n'
          '<script src="./formbot/steps.js"></script>\n'
          '<script src="./formbot/notes.js"></script>\n'
          '<script src="./formbot/overlay.js" defer></script>\n')
if '</body>' not in h:
    sys.exit('ERROR: </body> not found in index.html')
h = h.replace('</body>', inject + '</body>', 1)
open(p, 'w', encoding='utf-8').write(h)
EOF

# 6. Local server with browser cache disabled (Ctrl+C to stop)
echo "Trident       : http://localhost:$PORT/"
echo "Stealthburner : http://localhost:$PORT/stealthburner/"
echo "(folder: $OUT)"
cd "$OUT"
python3 - "$PORT" <<'EOF'
import http.server, socketserver, sys
class NoCache(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()
socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(('127.0.0.1', int(sys.argv[1])), NoCache) as httpd:
    httpd.serve_forever()
EOF
