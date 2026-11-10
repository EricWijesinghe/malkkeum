// Hero scene: a soft "clay" house on a floating island, soap bubbles drifting up and sparkles
// orbiting it. Follows the pointer (or phone tilt); pauses when off screen; static frame when
// the visitor prefers reduced motion; falls back to the CSS illustration without WebGL.
import * as THREE from '../vendor/three.module.min.js';

const canvas = document.getElementById('hero-3d');
const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

function webglOk() {
  try {
    const c = document.createElement('canvas');
    return !!(c.getContext('webgl2') || c.getContext('webgl'));
  } catch {
    return false;
  }
}

if (canvas && webglOk()) start();

function clay(color, rough = 0.62) {
  return new THREE.MeshStandardMaterial({ color, roughness: rough, metalness: 0.02 });
}

function roundedBox(w, h, d, r, mat) {
  const shape = new THREE.Shape();
  const x = -w / 2, y = -h / 2;
  shape.moveTo(x + r, y);
  shape.lineTo(x + w - r, y);
  shape.quadraticCurveTo(x + w, y, x + w, y + r);
  shape.lineTo(x + w, y + h - r);
  shape.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  shape.lineTo(x + r, y + h);
  shape.quadraticCurveTo(x, y + h, x, y + h - r);
  shape.lineTo(x, y + r);
  shape.quadraticCurveTo(x, y, x + r, y);
  const geo = new THREE.ExtrudeGeometry(shape, { depth: d - r * 2, bevelEnabled: true, bevelSize: r, bevelThickness: r, bevelSegments: 6, curveSegments: 10 });
  geo.translate(0, 0, -(d - r * 2) / 2);
  const m = new THREE.Mesh(geo, mat);
  m.castShadow = m.receiveShadow = true;
  return m;
}

function buildHouse(theme) {
  const g = new THREE.Group();
  const wallMat = clay(theme.wall);
  wallMat.emissive = new THREE.Color(theme.wall);
  wallMat.emissiveIntensity = theme.wallGlow;
  const walls = roundedBox(2.4, 1.7, 2.0, 0.18, wallMat);
  walls.position.y = 0.85;
  g.add(walls);

  const roofGeo = new THREE.ConeGeometry(2.05, 1.25, 4, 1);
  roofGeo.rotateY(Math.PI / 4);
  const roof = new THREE.Mesh(roofGeo, clay(theme.roof, 0.5));
  roof.scale.set(1, 1, 0.86);
  roof.position.y = 2.32;
  roof.castShadow = true;
  g.add(roof);

  const chimney = roundedBox(0.34, 0.7, 0.34, 0.07, clay(theme.roof, 0.5));
  chimney.position.set(0.62, 2.55, -0.25);
  g.add(chimney);

  const door = roundedBox(0.56, 0.92, 0.12, 0.08, clay(theme.door, 0.45));
  door.position.set(0, 0.5, 1.02);
  g.add(door);
  const knob = new THREE.Mesh(new THREE.SphereGeometry(0.045, 16, 16), clay('#FFD166', 0.3));
  knob.position.set(0.17, 0.5, 1.1);
  g.add(knob);

  const glow = new THREE.MeshStandardMaterial({ color: '#FFF4C2', emissive: '#FFD166', emissiveIntensity: 1.1, roughness: 0.3 });
  for (const x of [-0.75, 0.75]) {
    const w = roundedBox(0.5, 0.46, 0.1, 0.06, glow);
    w.position.set(x, 1.1, 1.02);
    g.add(w);
  }
  const side = roundedBox(0.1, 0.46, 0.6, 0.05, glow);
  side.position.set(1.22, 1.1, 0.1);
  g.add(side);

  const island = new THREE.Mesh(new THREE.CylinderGeometry(2.6, 2.2, 0.5, 48), clay(theme.lawn, 0.8));
  island.position.y = -0.25;
  island.receiveShadow = true;
  g.add(island);
  const soil = new THREE.Mesh(new THREE.ConeGeometry(2.2, 1.3, 48), clay(theme.soil, 0.9));
  soil.rotation.x = Math.PI;
  soil.position.y = -1.15;
  g.add(soil);

  for (const [x, z, s] of [[-1.7, 0.6, 1], [1.75, -0.8, 0.8], [-1.4, -1.3, 0.7]]) {
    const bush = new THREE.Mesh(new THREE.IcosahedronGeometry(0.34 * s, 2), clay(theme.bush, 0.75));
    bush.position.set(x, 0.22 * s, z);
    bush.castShadow = true;
    g.add(bush);
  }
  return g;
}

function bubbles(count) {
  const mat = new THREE.MeshPhysicalMaterial({
    color: '#ffffff', roughness: 0.05, metalness: 0, transmission: 0.92, thickness: 0.2,
    iridescence: 1, iridescenceIOR: 1.3, clearcoat: 1, transparent: true, opacity: 0.85,
  });
  const geo = new THREE.SphereGeometry(1, 32, 32);
  const list = [];
  for (let i = 0; i < count; i++) {
    const m = new THREE.Mesh(geo, mat);
    const s = 0.08 + Math.random() * 0.22;
    m.scale.setScalar(s);
    m.userData = { speed: 0.25 + Math.random() * 0.45, phase: Math.random() * Math.PI * 2, r: 1.6 + Math.random() * 1.8, a: Math.random() * Math.PI * 2 };
    m.position.y = Math.random() * 4;
    list.push(m);
  }
  return list;
}

function sparkles(count) {
  const pos = new Float32Array(count * 3);
  for (let i = 0; i < count; i++) {
    const r = 2.4 + Math.random() * 2.2, a = Math.random() * Math.PI * 2;
    pos.set([Math.cos(a) * r, Math.random() * 4 - 0.5, Math.sin(a) * r], i * 3);
  }
  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  return new THREE.Points(geo, new THREE.PointsMaterial({ color: '#BFD3FF', size: 0.06, transparent: true, opacity: 0.9, depthWrite: false }));
}

function themeColors() {
  const dark = document.documentElement.dataset.theme !== 'light';
  const brand = getComputedStyle(document.documentElement).getPropertyValue('--brand').trim() || '#3B5BFD';
  return dark
    ? { wall: '#F4F1FF', roof: brand, door: '#FF7A59', lawn: '#34D399', soil: '#3B2F5C', bush: '#10B981', key: 1.6, amb: 0.7, wallGlow: 0.18 }
    : { wall: '#FFFFFF', roof: brand, door: '#FF7A59', lawn: '#4ADE80', soil: '#C7B8F5', bush: '#22C55E', key: 1.9, amb: 0.9, wallGlow: 0.04 };
}

function start() {
  const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true, powerPreference: 'low-power' });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(35, 1, 0.1, 100);
  camera.position.set(0, 3.2, 10.5);
  camera.lookAt(0, 1, 0);

  const hemi = new THREE.HemisphereLight('#E6ECFF', '#2A1F4A', 0.8);
  scene.add(hemi);
  const key = new THREE.DirectionalLight('#ffffff', 1.6);
  key.position.set(4, 7, 5);
  key.castShadow = true;
  key.shadow.mapSize.set(1024, 1024);
  key.shadow.radius = 6;
  scene.add(key);
  const rim = new THREE.PointLight('#7C9BFF', 18, 20);
  rim.position.set(-4, 3, -3);
  scene.add(rim);

  const world = new THREE.Group();
  scene.add(world);
  let house = buildHouse(themeColors());
  world.add(house);
  const bubbleList = bubbles(reduced ? 6 : 16);
  bubbleList.forEach((b) => world.add(b));
  const dust = sparkles(140);
  world.add(dust);

  // Theme switch: rebuild the house in the new palette.
  new MutationObserver(() => {
    const t = themeColors();
    world.remove(house);
    house = buildHouse(t);
    world.add(house);
    key.intensity = t.key;
    hemi.intensity = t.amb;
  }).observe(document.documentElement, { attributes: true, attributeFilter: ['data-theme', 'style'] });

  const target = { x: 0, y: 0 };
  window.addEventListener('pointermove', (e) => {
    target.x = (e.clientX / window.innerWidth - 0.5) * 2;
    target.y = (e.clientY / window.innerHeight - 0.5) * 2;
  }, { passive: true });
  window.addEventListener('deviceorientation', (e) => {
    if (e.gamma == null) return;
    target.x = Math.max(-1, Math.min(1, e.gamma / 30));
    target.y = Math.max(-1, Math.min(1, (e.beta - 45) / 30));
  }, { passive: true });

  function resize() {
    const r = canvas.getBoundingClientRect();
    renderer.setSize(r.width, r.height, false);
    camera.aspect = r.width / Math.max(1, r.height);
    camera.position.z = camera.aspect < 0.9 ? 13 : 10.5;
    camera.updateProjectionMatrix();
  }
  new ResizeObserver(resize).observe(canvas);
  resize();

  let visible = true;
  new IntersectionObserver(([e]) => { visible = e.isIntersecting; }).observe(canvas);

  const clock = new THREE.Clock();
  function frame() {
    const t = clock.getElapsedTime();
    world.rotation.y += ((target.x * 0.5 + t * 0.12) - world.rotation.y) * 0.04;
    world.rotation.x += (target.y * 0.12 - world.rotation.x) * 0.05;
    world.position.y = Math.sin(t * 1.1) * 0.08;
    for (const b of bubbleList) {
      const u = b.userData;
      b.position.y += u.speed * 0.012;
      if (b.position.y > 4.5) b.position.y = -0.3;
      b.position.x = Math.cos(u.a + t * 0.2) * u.r + Math.sin(t + u.phase) * 0.15;
      b.position.z = Math.sin(u.a + t * 0.2) * u.r;
    }
    dust.rotation.y = -t * 0.05;
    renderer.render(scene, camera);
  }

  canvas.closest('.hero')?.classList.add('has-3d');
  if (reduced) {
    frame();
    return;
  }
  renderer.setAnimationLoop(() => { if (visible && !document.hidden) frame(); });
}
