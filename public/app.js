// KJV Bible Reader — Interactive iOS SwiftUI Reader Preview
const KJV_CHAPTERS = [
  {
    id: 'john-1',
    book: 'John',
    chapter: 1,
    subtitle: 'The Gospel According to Saint John',
    verses: [
      'In the beginning was the Word, and the Word was with God, and the Word was God.',
      'The same was in the beginning with God.',
      'All things were made by him; and without him was not any thing made that was made.',
      'In him was life; and the life was the light of men.',
      'And the light shineth in darkness; and the darkness comprehended it not.',
      'There was a man sent from God, whose name was John.',
      'The same came for a witness, to bear witness of the Light, that all men through him might believe.',
      'He was not that Light, but was sent to bear witness of that Light.',
      'That was the true Light, which lighteth every man that cometh into the world.',
      'And the Word was made flesh, and dwelt among us, (and we beheld his glory, the glory as of the only begotten of the Father,) full of grace and truth.',
    ],
  },
  {
    id: 'psalm-23',
    book: 'Psalms',
    chapter: 23,
    subtitle: 'A Psalm of David',
    verses: [
      'The LORD is my shepherd; I shall not want.',
      'He maketh me to lie down in green pastures: he leadeth me beside the still waters.',
      'He restoreth my soul: he leadeth me in the paths of righteousness for his name’s sake.',
      'Yea, though I walk through the valley of the shadow of death, I will fear no evil: for thou art with me; thy rod and thy staff they comfort me.',
      'Thou preparest a table before me in the presence of mine enemies: thou anointest my head with oil; my cup runneth over.',
      'Surely goodness and mercy shall follow me all the days of my life: and I will dwell in the house of the LORD for ever.',
    ],
  },
  {
    id: 'genesis-1',
    book: 'Genesis',
    chapter: 1,
    subtitle: 'The First Book of Moses, Called Genesis',
    verses: [
      'In the beginning God created the heaven and the earth.',
      'And the earth was without form, and void; and darkness was upon the face of the deep. And the Spirit of God moved upon the face of the waters.',
      'And God said, Let there be light: and there was light.',
      'And God saw the light, that it was good: and God divided the light from the darkness.',
      'And God called the light Day, and the darkness he called Night. And the evening and the morning were the first day.',
    ],
  },
  {
    id: 'proverbs-3',
    book: 'Proverbs',
    chapter: 3,
    subtitle: 'The Proverbs',
    verses: [
      'My son, forget not my law; but let thine heart keep my commandments:',
      'For length of days, and long life, and peace, shall they add to thee.',
      'Let not mercy and truth forsake thee: bind them about thy neck; write them upon the table of thine heart:',
      'So shalt thou find favour and good understanding in the sight of God and man.',
      'Trust in the LORD with all thine heart; and lean not unto thine own understanding.',
      'In all thy ways acknowledge him, and he shall direct thy paths.',
    ],
  },
  {
    id: '1cor-13',
    book: '1 Corinthians',
    chapter: 13,
    subtitle: 'The First Epistle of Paul the Apostle to the Corinthians',
    verses: [
      'Though I speak with the tongues of men and of angels, and have not charity, I am become as sounding brass, or a tinkling cymbal.',
      'And though I have the gift of prophecy, and understand all mysteries, and all knowledge; and though I have all faith, so that I could remove mountains, and have not charity, I am nothing.',
      'Charity suffereth long, and is kind; charity envieth not; charity vaunteth not itself, is not puffed up,',
      'Beareth all things, believeth all things, hopeth all things, endureth all things.',
      'And now abideth faith, hope, charity, these three; but the greatest of these is charity.',
    ],
  },
];

const state = {
  chapterIndex: 0,
  tab: 'read', // 'read' | 'saved'
  darkMode: false,
  fontSizeRem: 1.08,
  selectedVerses: new Set(),
  highlights: {
    'john-1:1': 'yellow',
    'john-1:5': 'blue',
    'psalm-23:1': 'green',
  },
  bookmarks: new Set(['john-1:1', 'psalm-23:1']),
};

function verseKey(chapterId, verseNum) {
  return `${chapterId}:${verseNum}`;
}

function currentChapter() {
  return KJV_CHAPTERS[state.chapterIndex];
}

function renderReader() {
  const ch = currentChapter();
  const selectEl = document.getElementById('chapter-select');
  if (selectEl) selectEl.value = String(state.chapterIndex);

  const prevBtn = document.getElementById('btn-prev-chapter');
  const nextBtn = document.getElementById('btn-next-chapter');
  if (prevBtn) prevBtn.disabled = state.chapterIndex === 0;
  if (nextBtn) nextBtn.disabled = state.chapterIndex === KJV_CHAPTERS.length - 1;

  const readPane = document.getElementById('pane-read');
  const savedPane = document.getElementById('pane-saved');
  const tabRead = document.getElementById('tab-btn-read');
  const tabSaved = document.getElementById('tab-btn-saved');

  if (tabRead) tabRead.classList.toggle('is-active', state.tab === 'read');
  if (tabSaved) {
    tabSaved.classList.toggle('is-active', state.tab === 'saved');
    const savedCount =
      Object.keys(state.highlights).length + state.bookmarks.size;
    tabSaved.textContent = `Saved (${savedCount})`;
  }

  if (state.tab === 'saved') {
    readPane.hidden = true;
    savedPane.hidden = false;
    renderSavedPane();
    document.getElementById('selection-bar').hidden = true;
    return;
  }

  readPane.hidden = false;
  savedPane.hidden = true;

  document.getElementById('chapter-title').textContent = `${ch.book} ${ch.chapter}`;
  document.getElementById('chapter-subtitle').textContent = ch.subtitle;

  const listEl = document.getElementById('verse-list');
  listEl.style.setProperty('--reader-font-size', `${state.fontSizeRem}rem`);
  listEl.innerHTML = '';

  ch.verses.forEach((text, idx) => {
    const vNum = idx + 1;
    const key = verseKey(ch.id, vNum);
    const row = document.createElement('div');
    row.className = 'verse-row';
    if (state.selectedVerses.has(vNum)) row.classList.add('is-selected');
    if (state.highlights[key]) {
      row.setAttribute('data-hl', state.highlights[key]);
    }

    const numSpan = document.createElement('span');
    numSpan.className = 'verse-num';
    numSpan.textContent = String(vNum);

    const textSpan = document.createElement('span');
    textSpan.className = 'verse-text';
    textSpan.textContent = text;

    row.append(numSpan, textSpan);

    if (state.bookmarks.has(key)) {
      const bm = document.createElement('span');
      bm.className = 'verse-bookmark-badge';
      bm.title = 'Bookmarked';
      bm.textContent = '🔖';
      row.appendChild(bm);
    }

    row.addEventListener('click', () => {
      if (state.selectedVerses.has(vNum)) {
        state.selectedVerses.delete(vNum);
      } else {
        state.selectedVerses.add(vNum);
      }
      renderReader();
    });

    listEl.appendChild(row);
  });

  const selBar = document.getElementById('selection-bar');
  selBar.hidden = state.selectedVerses.size === 0;
}

function renderSavedPane() {
  const container = document.getElementById('saved-list');
  container.innerHTML = '';

  const allKeys = new Set([
    ...Object.keys(state.highlights),
    ...state.bookmarks,
  ]);

  if (allKeys.size === 0) {
    container.innerHTML =
      '<p style="color:var(--text-muted);font-size:0.9rem;">No bookmarks or highlights yet. Tap any verse in the Read tab to annotate it.</p>';
    return;
  }

  Array.from(allKeys).forEach((key) => {
    const [chId, vStr] = key.split(':');
    const vNum = Number(vStr);
    const chIdx = KJV_CHAPTERS.findIndex((c) => c.id === chId);
    if (chIdx === -1) return;
    const ch = KJV_CHAPTERS[chIdx];
    const verseText = ch.verses[vNum - 1];
    const hlColor = state.highlights[key];
    const isBm = state.bookmarks.has(key);

    const card = document.createElement('div');
    card.className = 'saved-card';

    const meta = document.createElement('div');
    meta.className = 'saved-card__meta';
    const badges = [];
    if (isBm) badges.push('🔖 Bookmark');
    if (hlColor) badges.push(`● ${hlColor.toUpperCase()}`);
    meta.innerHTML = `<span>${ch.book} ${ch.chapter}:${vNum} (KJV)</span><span>${badges.join(' · ')}</span>`;

    const body = document.createElement('div');
    body.className = 'saved-card__text';
    body.textContent = verseText;

    card.append(meta, body);
    card.addEventListener('click', () => {
      state.chapterIndex = chIdx;
      state.tab = 'read';
      state.selectedVerses.clear();
      renderReader();
    });

    container.appendChild(card);
  });
}

function applyHighlight(color) {
  const ch = currentChapter();
  state.selectedVerses.forEach((vNum) => {
    const key = verseKey(ch.id, vNum);
    if (!color) {
      delete state.highlights[key];
    } else {
      state.highlights[key] = color;
    }
  });
  state.selectedVerses.clear();
  renderReader();
}

function toggleBookmarkSelection() {
  const ch = currentChapter();
  const keys = Array.from(state.selectedVerses).map((v) => verseKey(ch.id, v));
  const allBookmarked = keys.every((k) => state.bookmarks.has(k));
  keys.forEach((k) => {
    if (allBookmarked) {
      state.bookmarks.delete(k);
    } else {
      state.bookmarks.add(k);
    }
  });
  state.selectedVerses.clear();
  renderReader();
}

function copySelectedVerses() {
  const ch = currentChapter();
  const nums = Array.from(state.selectedVerses).sort((a, b) => a - b);
  if (nums.length === 0) return;

  const lines = nums.map((n) => `${n} ${ch.verses[n - 1]}`).join('\n');
  const ref = `${ch.book} ${ch.chapter}:${nums.join(',')} (KJV)`;
  const payload = `${lines}\n— ${ref}`;

  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(payload).catch(() => {});
  }

  const toast = document.getElementById('copy-toast');
  if (toast) {
    toast.textContent = `Copied ${ref}`;
    setTimeout(() => {
      toast.textContent = '';
    }, 2200);
  }
  state.selectedVerses.clear();
  renderReader();
}

document.addEventListener('DOMContentLoaded', () => {
  const selectEl = document.getElementById('chapter-select');
  if (selectEl) {
    KJV_CHAPTERS.forEach((ch, idx) => {
      const opt = document.createElement('option');
      opt.value = String(idx);
      opt.textContent = `${ch.book} ${ch.chapter}`;
      selectEl.appendChild(opt);
    });
    selectEl.addEventListener('change', (e) => {
      state.chapterIndex = Number(e.target.value);
      state.selectedVerses.clear();
      renderReader();
    });
  }

  document.getElementById('btn-prev-chapter')?.addEventListener('click', () => {
    if (state.chapterIndex > 0) {
      state.chapterIndex--;
      state.selectedVerses.clear();
      renderReader();
    }
  });

  document.getElementById('btn-next-chapter')?.addEventListener('click', () => {
    if (state.chapterIndex < KJV_CHAPTERS.length - 1) {
      state.chapterIndex++;
      state.selectedVerses.clear();
      renderReader();
    }
  });

  document.getElementById('btn-font-dec')?.addEventListener('click', () => {
    state.fontSizeRem = Math.max(0.92, +(state.fontSizeRem - 0.08).toFixed(2));
    renderReader();
  });

  document.getElementById('btn-font-inc')?.addEventListener('click', () => {
    state.fontSizeRem = Math.min(1.36, +(state.fontSizeRem + 0.08).toFixed(2));
    renderReader();
  });

  document.getElementById('btn-theme-toggle')?.addEventListener('click', (e) => {
    state.darkMode = !state.darkMode;
    const frame = document.getElementById('device-frame');
    if (frame) {
      frame.setAttribute('data-theme', state.darkMode ? 'dark' : 'light');
    }
    e.currentTarget.textContent = state.darkMode ? '☀ Light' : '☾ Dark';
  });

  document.querySelectorAll('[data-swatch]').forEach((btn) => {
    btn.addEventListener('click', () => {
      applyHighlight(btn.getAttribute('data-swatch'));
    });
  });

  document.getElementById('btn-clear-hl')?.addEventListener('click', () => {
    applyHighlight(null);
  });

  document.getElementById('btn-bookmark-sel')?.addEventListener('click', toggleBookmarkSelection);
  document.getElementById('btn-copy-sel')?.addEventListener('click', copySelectedVerses);

  document.getElementById('tab-btn-read')?.addEventListener('click', () => {
    state.tab = 'read';
    renderReader();
  });

  document.getElementById('tab-btn-saved')?.addEventListener('click', () => {
    state.tab = 'saved';
    renderReader();
  });

  renderReader();
});
