// Theme Management
function toggleTheme() {
  const body = document.body;
  const themeToggle = document.querySelector(".theme-toggle i");

  if (body.getAttribute("data-theme") === "dark") {
    body.removeAttribute("data-theme");
    themeToggle.className = "fas fa-moon";
    localStorage.setItem("theme", "light");
  } else {
    body.setAttribute("data-theme", "dark");
    themeToggle.className = "fas fa-sun";
    localStorage.setItem("theme", "dark");
  }
}

// Initialize theme on page load
function initializeTheme() {
  const savedTheme = localStorage.getItem("theme");
  const themeToggle = document.querySelector(".theme-toggle i");

  if (savedTheme === "dark") {
    document.body.setAttribute("data-theme", "dark");
    if (themeToggle) themeToggle.className = "fas fa-sun";
  } else {
    if (themeToggle) themeToggle.className = "fas fa-moon";
  }
}

// Navigation Functions
function navigateToSubject(subject) {
  window.location.href = `${subject}.html`;
}

function goBack() {
  window.history.back();
}


// Chapter Data - This represents the actual folder structure
const chapterData = {
  physics: [
    "1.Vectors",
    "2.Unit, Dimension, Measurement, Error",
    "3.Kinematics",
    "4.Newton's Laws of Motion",
    "5.Work, Power & Energy",
    "6.Conservation of Momentum",
    "7.Rotational Motion",
    "8.Gravitation",
    "9.Fluids & Elasticity",
    "10.Heat & Thermodynamics",
    "11.Simple Harmonic Motion",
    "12.Waves & Sound",
    "13.Electrostatics & Current Electricity",
    "14.Magnetics",
    "15.Permanent Magnet",
    "16.Electromagnetic Induction",
    "17.Alternating Current",
    "18.Electromagnetic Waves",
    "19.Optics",
    "20.Modern Physics",
    "21.Communication System",
    "22.Semiconductor",
    "23.EXPERIMENTAL SKILLS IN PHYSICS",
  ],
  chemistry: [
    "1.Some Basic Concepts of Chemistry",
    "2.Structure of Atom",
    "3.Classification of Elements & Periodicity in Properties",
    "4.Chemical Bonding & Molecular Structure",
    "5.Gaseous State",
    "6.Thermodynamics",
    "7.Chemical Kinetics & Nuclear Chemistry",
    "8.Hydrogen",
    "9.Chemical Equilibrium",
    "10.Ionic Equilibrium",
    "11.The s-BLOCK elements",
    "12.The p-BLOCK elements",
    "13.GOC",
    "14.Isomerism",
    "15.Hydrocarbons",
    "16.Environmental Chemistry",
    "17.Electrophilic Aromatic Substitution",
    "18.Alkyl & Aryl Halides",
    "19.Alcohol, Phenol & Ether",
    "20.Aldehydes & Ketones",
    "21.Carboxylic Acids & Derivatives",
    "22.Amines",
    "23.Solid State",
    "24.Solutions",
    "25.Surface Chemistry",
    "26.General Principles and Processes of Isolation of Elements",
    "27.Electrochemistry",
    "28.The d- and f- BLOCK Elements",
    "29.Coordination Compounds",
    "30.QUALITATIVE SALT ANALYSIS",
    "31.Polymers",
    "32.Biomolecules",
    "33.Chemistry in Everyday Life",
    "34.IUPAC Nomenclature",
    "35.PRACTICAL ORGANIC CHEMISTRY",
    "36.Purification and Characteristics of Organic Compounds",
    "37.CONFORMERS",
  ],
  mathematics: [
    "1.Set, Relation & Function",
    "2.Linear Inequalities & Linear Programming",
    "3.Logarithm",
    "4.Trigonometric Ratios & Identities",
    "5.Basic Calculus",
    "6.Quadratic Equations & Expressions",
    "7.Mathematical Reasoning",
    "8.Sequence & Progression",
    "9.Straight Lines",
    "10.Circle",
    "11.Parabola & Conic Section",
    "12.Mathematical Induction",
    "13.Ellipse",
    "14.Hyperbola",
    "15.Complex Number",
    "16.Solution of Triangle",
    "17.Trigonometric Equations",
    "18.Permutation & Combinations",
    "19.Binomial Theorem",
    "20.Probability",
    "21.Statistics",
    "22.Function-II",
    "23.Inverse Trigonometric Functions",
    "24.Limit, Continuity & Differentiability (Differentiation)",
    "25.Application of Derivatives",
    "26.Indefinite Integration",
    "27.Definite Integration",
    "28.Area Under Curve (Quadrature)",
    "29.Differential Equations",
    "30.Matrices & Determinants",
    "31.Vectors & 3D",
  ],
};

// Load chapters for subject pages
function loadChapters(subject) {
  const chapterList = document.getElementById("chapter-list");
  const subjectTitle = document.getElementById("subject-title");

  if (!chapterList || !chapterData[subject]) return;

  subjectTitle.textContent = subject.charAt(0).toUpperCase() + subject.slice(1);
  chapterList.innerHTML = '<div class="loading">Loading chapters...</div>';

  setTimeout(() => {
    const chapters = chapterData[subject];
    chapterList.innerHTML = "";

    chapters.forEach((chapter, index) => {
      const chapterCard = document.createElement("div");
      chapterCard.className = "chapter-card";
      chapterCard.onclick = () => openChapter(subject, chapter);

      const chapterNumber = chapter.split(".")[0];
      const chapterName = chapter.split(".").slice(1).join(".").trim();

      chapterCard.innerHTML = `
                <div class="chapter-title">Chapter ${chapterNumber}</div>
                <div class="chapter-subtitle">${chapterName}</div>
            `;

      chapterList.appendChild(chapterCard);
    });
  }, 500);
}

// Open chapter and load images
function openChapter(subject, chapterName) {
  // Store chapter info in localStorage for the gallery page
  localStorage.setItem("currentSubject", subject);
  localStorage.setItem("currentChapter", chapterName);

  // Navigate to gallery page
  window.location.href = "gallery.html";
}

// Gallery Functions
function loadGallery() {
  const subject = localStorage.getItem("currentSubject");
  const chapter = localStorage.getItem("currentChapter");

  if (!subject || !chapter) {
    window.location.href = "index.html";
    return;
  }

  const galleryTitle = document.getElementById("gallery-title");
  const imageGallery = document.getElementById("image-gallery");

  if (!galleryTitle || !imageGallery) return;

  const chapterNumber = chapter.split(".")[0];
  const chapterName = chapter.split(".").slice(1).join(".").trim();

  galleryTitle.textContent = `${
    subject.charAt(0).toUpperCase() + subject.slice(1)
  } - Chapter ${chapterNumber}: ${chapterName}`;

  // Show loading state
  imageGallery.innerHTML = '<div class="loading">Loading images...</div>';

  // Simulate loading images (in a real app, you'd scan the directory)
  setTimeout(() => {
    loadImages(subject, chapter);
  }, 1000);
}

function loadImages(subject, chapter) {
  const imageGallery = document.getElementById("image-gallery");
  if (!imageGallery) return;

  // Clear loading state
  imageGallery.innerHTML = "";

  // Generate image paths based on the expected structure
  // This simulates finding images in the chapter folder
  const imageCount = getImageCount(subject, chapter);

  if (imageCount === 0) {
    imageGallery.innerHTML =
      '<div class="loading">No images found in this chapter.</div>';
    return;
  }

  for (let i = 1; i <= imageCount; i++) {
    const imageNumber = String(i).padStart(4, "0");
    const imagePath = `${subject}/${chapter}/${imageNumber}.jpg`;

    const img = document.createElement("img");
    img.src = imagePath;
    img.alt = `${subject} Chapter Notes - Page ${i} | IIT JEE Handwritten Notes`;
    img.loading = "lazy";
    img.className = "gallery-image";
    img.title = `${subject} notes page ${i}`;

    // Handle image load errors
    img.onerror = function () {
      this.style.display = "none";
    };

    imageGallery.appendChild(img);
  }
}

// Get estimated image count based on the folder structure
function getImageCount(subject, chapter) {
  // This is a simplified version - in reality, you'd scan the directory
  // Based on the project structure, most chapters have various numbers of images
  const chapterImageCounts = {
    physics: {
      "1.Vectors": 9,
      "2.Unit, Dimension, Measurement, Error": 14,
      "3.Kinematics": 19,
      "4.Newton's Laws of Motion": 15,
      "5.Work, Power & Energy": 19,
      "6.Conservation of Momentum": 25,
      "7.Rotational Motion": 36,
      "8.Gravitation": 16,
      "9.Fluids & Elasticity": 32,
      "10.Heat & Thermodynamics": 45,
      "11.Simple Harmonic Motion": 14,
      "12.Waves & Sound": 18,
      "13.Electrostatics & Current Electricity": 92,
      "14.Magnetics": 30,
      "15.Permanent Magnet": 9,
      "16.Electromagnetic Induction": 13,
      "17.Alternating Current": 14,
      "18.Electromagnetic Waves": 6,
      "19.Optics": 45,
      "20.Modern Physics": 27,
      "21.Communication System": 9,
      "22.Semiconductor": 13,
      "23.EXPERIMENTAL SKILLS IN PHYSICS": 19,
    },
    chemistry: {
      "1.Some Basic Concepts of Chemistry": 78,
      "2.Structure of Atom": 51,
      "3.Classification of Elements & Periodicity in Properties": 36,
      "4.Chemical Bonding & Molecular Structure": 83,
      "5.Gaseous State": 39,
      "6.Thermodynamics": 51,
      "7.Chemical Kinetics & Nuclear Chemistry": 21,
      "8.Hydrogen": 6,
      "9.Chemical Equilibrium": 17,
      "10.Ionic Equilibrium": 43,
      "11.The s-BLOCK elements": 21,
      "12.The p-BLOCK elements": 51,
      "13.GOC": 23,
      "14.Isomerism": 23,
      "15.Hydrocarbons": 38,
      "16.Environmental Chemistry": 14,
      "17.Electrophilic Aromatic Substitution": 3,
      "18.Alkyl & Aryl Halides": 11,
      "19.Alcohol, Phenol & Ether": 24,
      "20.Aldehydes & Ketones": 24,
      "21.Carboxylic Acids & Derivatives": 10,
      "22.Amines": 13,
      "23.Solid State": 41,
      "24.Solutions": 14,
      "25.Surface Chemistry": 16,
      "26.General Principles and Processes of Isolation of Elements": 11,
      "27.Electrochemistry": 18,
      "28.The d- and f- BLOCK Elements": 18,
      "29.Coordination Compounds": 16,
      "30.QUALITATIVE SALT ANALYSIS": 21,
      "31.Polymers": 7,
      "32.Biomolecules": 22,
      "33.Chemistry in Everyday Life": 4,
      "34.IUPAC Nomenclature": 14,
      "35.PRACTICAL ORGANIC CHEMISTRY": 1,
      "36.Purification and Characteristics of Organic Compounds": 4,
      "37.CONFORMERS": 1,
    },
    mathematics: {
      "1.Set, Relation & Function": 55,
      "2.Linear Inequalities & Linear Programming": 1,
      "3.Logarithm": 5,
      "4.Trigonometric Ratios & Identities": 8,
      "5.Basic Calculus": 35,
      "6.Quadratic Equations & Expressions": 13,
      "7.Mathematical Reasoning": 3,
      "8.Sequence & Progression": 28,
      "9.Straight Lines": 24,
      "10.Circle": 17,
      "11.Parabola & Conic Section": 13,
      "12.Mathematical Induction": 2,
      "13.Ellipse": 12,
      "14.Hyperbola": 6,
      "15.Complex Number": 13,
      "16.Solution of Triangle": 10,
      "17.Trigonometric Equations": 9,
      "18.Permutation & Combinations": 15,
      "19.Binomial Theorem": 11,
      "20.Probability": 9,
      "21.Statistics": 4,
      "22.Function-II": 47,
      "23.Inverse Trigonometric Functions": 19,
      "24.Limit, Continuity & Differentiability (Differentiation)": 62,
      "25.Application of Derivatives": 46,
      "26.Indefinite Integration": 16,
      "27.Definite Integration": 13,
      "28.Area Under Curve (Quadrature)": 3,
      "29.Differential Equations": 12,
      "30.Matrices & Determinants": 26,
      "31.Vectors & 3D": 27,
    },
  };

  return chapterImageCounts[subject]?.[chapter] || 0;
}

// Navigation helper
function navigateToSubjectPage(subject) {
  window.location.href = `${subject}.html`;
}

// Initialize page based on current location
function initializePage() {
  initializeTheme();

  const path = window.location.pathname;
  const page = path.substring(path.lastIndexOf("/") + 1);

  if (page === "physics.html") {
    loadChapters("physics");
  } else if (page === "chemistry.html") {
    loadChapters("chemistry");
  } else if (page === "mathematics.html") {
    loadChapters("mathematics");
  } else if (page === "gallery.html") {
    loadGallery();
  }
}

// Content Protection - Disable right-click and keyboard shortcuts
function disableContentProtection() {
  // Disable right-click context menu
  document.addEventListener("contextmenu", function (e) {
    e.preventDefault();
    return false;
  });

  // Disable keyboard shortcuts (except developer tools)
  document.addEventListener("keydown", function (e) {
    // Allow F12 (Developer Tools) - removed restriction
    // Allow Ctrl+Shift+I (Developer Tools) - removed restriction
    // Allow Ctrl+Shift+J (Console) - removed restriction
    // Allow Ctrl+Shift+C (Inspect Element) - removed restriction

    // Disable Ctrl+U (View Source)
    if (e.ctrlKey && e.keyCode === 85) {
      e.preventDefault();
      return false;
    }

    // Disable Ctrl+S (Save)
    if (e.ctrlKey && e.keyCode === 83) {
      e.preventDefault();
      return false;
    }

    // Disable Ctrl+P (Print)
    if (e.ctrlKey && e.keyCode === 80) {
      e.preventDefault();
      return false;
    }

    // Disable Ctrl+A (Select All)
    if (e.ctrlKey && e.keyCode === 65) {
      e.preventDefault();
      return false;
    }

    // Disable Ctrl+C (Copy)
    if (e.ctrlKey && e.keyCode === 67) {
      e.preventDefault();
      return false;
    }

    // Disable Ctrl+V (Paste)
    if (e.ctrlKey && e.keyCode === 86) {
      e.preventDefault();
      return false;
    }

    // Disable Ctrl+X (Cut)
    if (e.ctrlKey && e.keyCode === 88) {
      e.preventDefault();
      return false;
    }
  });

  // Disable text selection
  document.addEventListener("selectstart", function (e) {
    e.preventDefault();
    return false;
  });

  // Disable drag and drop
  document.addEventListener("dragstart", function (e) {
    e.preventDefault();
    return false;
  });

  // Disable printing through window.print()
  window.print = function () {
    return false;
  };

  // Developer tools are now allowed via keyboard shortcuts
  // Removed developer tools detection and warnings
}

// Wait for DOM to be loaded
document.addEventListener("DOMContentLoaded", function () {
  initializePage();
  disableContentProtection();
});
