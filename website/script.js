// Reveal sections as they scroll into view.
const io = new IntersectionObserver(
  (entries) => {
    for (const e of entries) {
      if (e.isIntersecting) {
        e.target.classList.add('in');
        io.unobserve(e.target);
      }
    }
  },
  { threshold: 0.12, rootMargin: '0px 0px -40px 0px' },
);
document.querySelectorAll('.reveal').forEach((el) => io.observe(el));

// Point the main button at the visitor's platform.
const ua = navigator.userAgent;
const os = /Android/i.test(ua)
  ? 'android'
  : /Mac/i.test(ua)
    ? 'mac'
    : /Win/i.test(ua)
      ? 'windows'
      : null;
if (os) {
  document.querySelector(`.platform[data-os="${os}"]`)?.classList.add('mine');
  const hero = document.getElementById('hero-download');
  const note = document.getElementById('hero-note');
  if (os === 'android') {
    hero.textContent = 'Download for Android';
    hero.href = 'https://github.com/Asta39/grab/releases/latest';
  } else if (os === 'mac') {
    hero.textContent = 'Download for Mac';
    hero.href = 'https://github.com/Asta39/grab/releases/latest/download/grab-macos.dmg';
  } else {
    hero.textContent = 'Download for Windows';
    hero.href = 'https://github.com/Asta39/grab/releases/latest/download/grab-windows-x64.zip';
  }
}
