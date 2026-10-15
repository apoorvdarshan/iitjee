// Appearance: System → Light → Dark, matching the iOS app.
const themeModes = ["system", "light", "dark"];

function applyTheme(mode) {
  const validMode = themeModes.includes(mode) ? mode : "system";
  const root = document.documentElement;

  if (validMode === "system") {
    root.removeAttribute("data-theme");
  } else {
    root.setAttribute("data-theme", validMode);
  }

  const iconClasses = {
    system: "fa-solid fa-circle-half-stroke",
    light: "fa-solid fa-sun",
    dark: "fa-solid fa-moon",
  };

  document.querySelectorAll(".theme-toggle").forEach((button) => {
    const icon = button.querySelector("i");
    const label = button.querySelector(".theme-label");
    const title = validMode.charAt(0).toUpperCase() + validMode.slice(1);

    button.dataset.mode = validMode;
    button.setAttribute("aria-label", `Appearance: ${title}. Activate for the next option.`);
    button.title = `Appearance: ${title}`;
    if (icon) icon.className = iconClasses[validMode];
    if (label) label.textContent = title;
  });
}

function toggleTheme() {
  const currentMode = localStorage.getItem("theme") || "system";
  const currentIndex = themeModes.indexOf(currentMode);
  const nextMode = themeModes[(Math.max(currentIndex, 0) + 1) % themeModes.length];
  localStorage.setItem("theme", nextMode);
  applyTheme(nextMode);
}

function initializeTheme() {
  applyTheme(localStorage.getItem("theme") || "system");
}

// Only known subjects and chapters reach URLs and the page: inputs from the query
// string or localStorage are looked up in chapterData, and the stored strings are
// used from then on, never the raw values.
function knownSubject(value) {
  return Object.keys(chapterData).find((name) => name === value);
}

function knownChapter(subject, value) {
  return subject ? chapterData[subject].find((name) => name === value) : undefined;
}

// Navigation Functions
function navigateToSubject(subject) {
  const known = knownSubject(subject);
  window.location.href = known ? `/${known}` : "/";
}

function goBack() {
  const subject = knownSubject(localStorage.getItem("currentSubject"));
  window.location.href = subject ? `/${subject}` : "/";
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
  const searchInput = document.getElementById("chapter-search");

  if (!chapterList || !chapterData[subject]) return;

  const renderChapters = (chapters) => {
    chapterList.innerHTML = "";

    if (chapters.length === 0) {
      chapterList.innerHTML = '<div class="empty-state">No chapter matches that search.</div>';
    }

    chapters.forEach((chapter) => {
      const chapterCard = document.createElement("button");
      const chapterNumber = chapter.split(".")[0];
      const chapterName = chapter.split(".").slice(1).join(".").trim();
      const pageCount = getImageCount(subject, chapter);

      chapterCard.type = "button";
      chapterCard.className = "chapter-card";
      chapterCard.setAttribute(
        "aria-label",
        `Chapter ${chapterNumber}, ${chapterName}, ${pageCount} pages`,
      );
      chapterCard.onclick = () => openChapter(subject, chapter);
      chapterCard.innerHTML = `
        <span class="margin-number" aria-hidden="true">${String(chapterNumber).padStart(2, "0")}</span>
        <span class="row-copy">
          <span class="chapter-title">Chapter ${chapterNumber}</span>
          <span class="chapter-subtitle">${chapterName}</span>
        </span>
        <span class="chapter-pages">${pageCount} pages</span>
        <span class="row-arrow" aria-hidden="true">↗</span>
      `;
      chapterList.appendChild(chapterCard);
    });

    const count = document.getElementById("chapter-count");
    if (count) count.textContent = `${chapters.length} ${chapters.length === 1 ? "chapter" : "chapters"}`;
  };

  renderChapters(chapterData[subject]);

  if (searchInput) {
    searchInput.addEventListener("input", () => {
      const query = searchInput.value.trim().toLocaleLowerCase();
      const filtered = chapterData[subject].filter((chapter) =>
        chapter.toLocaleLowerCase().includes(query),
      );
      renderChapters(filtered);
    });
  }
}

// Open chapter and load images
function openChapter(subject, chapterName) {
  // Store chapter info in localStorage for the gallery page
  localStorage.setItem("currentSubject", subject);
  localStorage.setItem("currentChapter", chapterName);

  const params = new URLSearchParams({ subject, chapter: chapterName });
  window.location.href = `/gallery?${params.toString()}`;
}

// Gallery Functions
function loadGallery() {
  const params = new URLSearchParams(window.location.search);
  const subject = knownSubject(params.get("subject") || localStorage.getItem("currentSubject"));
  const chapter = knownChapter(subject, params.get("chapter") || localStorage.getItem("currentChapter"));

  if (!subject || !chapter) {
    window.location.href = "/";
    return;
  }

  localStorage.setItem("currentSubject", subject);
  localStorage.setItem("currentChapter", chapter);
  document.body.dataset.subject = subject;

  const galleryTitle = document.getElementById("gallery-title");
  const imageGallery = document.getElementById("image-gallery");

  if (!galleryTitle || !imageGallery) return;

  const chapterNumber = chapter.split(".")[0];
  const chapterName = chapter.split(".").slice(1).join(".").trim();

  const subjectName = subject.charAt(0).toUpperCase() + subject.slice(1);
  const pageCount = getImageCount(subject, chapter);
  galleryTitle.textContent = `${subjectName} · ${chapterName}`;
  document.title = `${chapterName} — PCM Notes`;

  const backLink = document.getElementById("reader-back");
  if (backLink) backLink.href = `/${subject}`;

  const countLabel = document.getElementById("reader-page-count");
  if (countLabel) countLabel.textContent = `Chapter ${chapterNumber} · ${pageCount} handwritten pages`;

  loadImages(subject, chapter);
  initializeReaderProgress();
}

function loadImages(subject, chapter) {
  const imageGallery = document.getElementById("image-gallery");
  if (!imageGallery) return;

  imageGallery.innerHTML = "";
  const imageCount = getImageCount(subject, chapter);

  if (imageCount === 0) {
    imageGallery.innerHTML = '<div class="empty-state">No handwritten pages were found for this chapter.</div>';
    return;
  }

  for (let i = 1; i <= imageCount; i++) {
    const imageNumber = String(i).padStart(4, "0");
    const imagePath = `${subject}/${chapter}/${imageNumber}.jpg`;

    const figure = document.createElement("figure");
    const img = document.createElement("img");
    const caption = document.createElement("figcaption");

    figure.className = "note-page";
    img.src = imagePath;
    img.alt = `${subject} handwritten chapter notes, page ${i} of ${imageCount}`;
    img.loading = i === 1 ? "eager" : "lazy";
    img.decoding = "async";
    img.className = "gallery-image";
    if (i === 1) img.fetchPriority = "high";
    caption.className = "page-caption";
    caption.textContent = `${i} / ${imageCount}`;

    img.onerror = function () {
      figure.remove();
    };

    figure.append(img, caption);
    imageGallery.appendChild(figure);
  }
}

function initializeReaderProgress() {
  const update = () => {
    const scrollable = document.documentElement.scrollHeight - window.innerHeight;
    const progress = scrollable > 0 ? Math.min((window.scrollY / scrollable) * 100, 100) : 0;
    document.documentElement.style.setProperty("--reader-progress", `${progress}%`);
  };

  update();
  window.addEventListener("scroll", update, { passive: true });
  window.addEventListener("resize", update);
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
      "1.Some Basic Concepts of Chemistry": 81,
      "2.Structure of Atom": 54,
      "3.Classification of Elements & Periodicity in Properties": 39,
      "4.Chemical Bonding & Molecular Structure": 86,
      "5.Gaseous State": 42,
      "6.Thermodynamics": 54,
      "7.Chemical Kinetics & Nuclear Chemistry": 24,
      "8.Hydrogen": 9,
      "9.Chemical Equilibrium": 20,
      "10.Ionic Equilibrium": 46,
      "11.The s-BLOCK elements": 24,
      "12.The p-BLOCK elements": 54,
      "13.GOC": 26,
      "14.Isomerism": 26,
      "15.Hydrocarbons": 41,
      "16.Environmental Chemistry": 17,
      "17.Electrophilic Aromatic Substitution": 3,
      "18.Alkyl & Aryl Halides": 14,
      "19.Alcohol, Phenol & Ether": 27,
      "20.Aldehydes & Ketones": 27,
      "21.Carboxylic Acids & Derivatives": 13,
      "22.Amines": 16,
      "23.Solid State": 44,
      "24.Solutions": 17,
      "25.Surface Chemistry": 19,
      "26.General Principles and Processes of Isolation of Elements": 14,
      "27.Electrochemistry": 21,
      "28.The d- and f- BLOCK Elements": 21,
      "29.Coordination Compounds": 19,
      "30.QUALITATIVE SALT ANALYSIS": 24,
      "31.Polymers": 10,
      "32.Biomolecules": 25,
      "33.Chemistry in Everyday Life": 7,
      "34.IUPAC Nomenclature": 17,
      "35.PRACTICAL ORGANIC CHEMISTRY": 4,
      "36.Purification and Characteristics of Organic Compounds": 7,
      "37.CONFORMERS": 1,
    },
    mathematics: {
      "1.Set, Relation & Function": 58,
      "2.Linear Inequalities & Linear Programming": 1,
      "3.Logarithm": 8,
      "4.Trigonometric Ratios & Identities": 11,
      "5.Basic Calculus": 38,
      "6.Quadratic Equations & Expressions": 15,
      "7.Mathematical Reasoning": 3,
      "8.Sequence & Progression": 28,
      "9.Straight Lines": 24,
      "10.Circle": 20,
      "11.Parabola & Conic Section": 16,
      "12.Mathematical Induction": 2,
      "13.Ellipse": 15,
      "14.Hyperbola": 9,
      "15.Complex Number": 16,
      "16.Solution of Triangle": 13,
      "17.Trigonometric Equations": 12,
      "18.Permutation & Combinations": 18,
      "19.Binomial Theorem": 14,
      "20.Probability": 12,
      "21.Statistics": 7,
      "22.Function-II": 50,
      "23.Inverse Trigonometric Functions": 22,
      "24.Limit, Continuity & Differentiability (Differentiation)": 65,
      "25.Application of Derivatives": 49,
      "26.Indefinite Integration": 19,
      "27.Definite Integration": 16,
      "28.Area Under Curve (Quadrature)": 6,
      "29.Differential Equations": 15,
      "30.Matrices & Determinants": 29,
      "31.Vectors & 3D": 30,
    },
  };

  return chapterImageCounts[subject]?.[chapter] || 0;
}

// Navigation helper
function navigateToSubjectPage(subject) {
  navigateToSubject(subject);
}

// PDF Download Function
async function downloadChapterPDF() {
  const subject = knownSubject(localStorage.getItem("currentSubject"));
  const chapter = knownChapter(subject, localStorage.getItem("currentChapter"));

  if (!subject || !chapter) {
    alert("Error: Chapter information not found");
    return;
  }

  const imageCount = getImageCount(subject, chapter);
  if (imageCount === 0) {
    alert("No images found in this chapter");
    return;
  }

  const downloadBtn = document.getElementById("download-pdf");
  const originalText = downloadBtn.innerHTML;
  downloadBtn.disabled = true;
  downloadBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Generating...';

  try {
    const { jsPDF } = window.jspdf;

    // Create PDF in portrait mode for handwritten notes
    const pdf = new jsPDF({
      orientation: "portrait",
      unit: "mm",
      format: "a4",
    });

    const pageWidth = pdf.internal.pageSize.getWidth();
    const pageHeight = pdf.internal.pageSize.getHeight();
    const margin = 5;
    const maxWidth = pageWidth - margin * 2;
    const maxHeight = pageHeight - margin * 2;

    let addedPages = 0;

    for (let i = 1; i <= imageCount; i++) {
      const imageNumber = String(i).padStart(4, "0");
      const imagePath = `${subject}/${chapter}/${imageNumber}.jpg`;

      // Update button with progress
      downloadBtn.innerHTML = `<i class="fas fa-spinner fa-spin"></i> ${i}/${imageCount}`;

      try {
        // Load image and convert to base64
        const result = await loadImageForPDF(imagePath);

        if (result && result.dataUrl) {
          // Calculate dimensions to fit on page while maintaining aspect ratio
          const widthRatio = maxWidth / result.width;
          const heightRatio = maxHeight / result.height;
          const ratio = Math.min(widthRatio, heightRatio);

          const imgWidth = result.width * ratio;
          const imgHeight = result.height * ratio;

          // Center image on page
          const x = (pageWidth - imgWidth) / 2;
          const y = (pageHeight - imgHeight) / 2;

          if (addedPages > 0) {
            pdf.addPage();
          }

          pdf.addImage(result.dataUrl, "JPEG", x, y, imgWidth, imgHeight);
          addedPages++;
        }
      } catch (imgError) {
        console.error(`Error loading image ${i}:`, imgError);
      }
    }

    if (addedPages === 0) {
      alert("Could not load any images. Please try again.");
      return;
    }

    // Generate filename from chapter name
    const chapterName = chapter.replace(/[^a-zA-Z0-9\s.-]/g, "").trim();
    pdf.save(`${chapterName}.pdf`);
  } catch (error) {
    console.error("PDF generation error:", error);
    alert("Error generating PDF: " + error.message);
  } finally {
    downloadBtn.disabled = false;
    downloadBtn.innerHTML = originalText;
  }
}

// Helper function to load image for PDF
function loadImageForPDF(src) {
  return new Promise((resolve, reject) => {
    const img = new Image();

    img.onload = function () {
      try {
        const canvas = document.createElement("canvas");
        canvas.width = img.naturalWidth;
        canvas.height = img.naturalHeight;
        const ctx = canvas.getContext("2d");
        ctx.fillStyle = "#FFFFFF";
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        ctx.drawImage(img, 0, 0);
        const dataUrl = canvas.toDataURL("image/jpeg", 0.85);
        resolve({
          dataUrl: dataUrl,
          width: img.naturalWidth,
          height: img.naturalHeight
        });
      } catch (e) {
        reject(e);
      }
    };

    img.onerror = function() {
      reject(new Error("Failed to load image: " + src));
    };

    // Add cache-busting and load
    img.src = src + "?t=" + Date.now();
  });
}

// Initialize page based on current location
function initializePage() {
  initializeTheme();

  document.querySelectorAll("[data-current-year]").forEach((element) => {
    element.textContent = String(new Date().getFullYear());
  });

  const path = window.location.pathname.replace(/\/+$/, "");
  const page = path.substring(path.lastIndexOf("/") + 1).replace(/\.html$/i, "");

  if (page === "physics") {
    loadChapters("physics");
  } else if (page === "chemistry") {
    loadChapters("chemistry");
  } else if (page === "mathematics") {
    loadChapters("mathematics");
  } else if (page === "gallery") {
    loadGallery();
  }
}

// Wait for DOM to be loaded
document.addEventListener("DOMContentLoaded", function () {
  initializePage();
});
