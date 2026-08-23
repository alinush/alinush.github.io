// Light/dark toggle, adapted from the Apollo Zola theme.
//
// Unlike upstream, both palettes live in a single stylesheet (as `:root.light`
// and `:root.dark` rules), so switching is just a class swap on <html> — no
// second stylesheet to enable/disable.

var themeToggleMode = window.themeToggleMode || "toggle-auto";

function setTheme(mode) {
  try {
    localStorage.setItem("theme-storage", mode);
  } catch (e) {
    /* private mode, or storage disabled */
  }
}

function getSystemPrefersDark() {
  return (
    window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches
  );
}

function getSavedTheme() {
  var currentTheme = null;
  try {
    currentTheme = localStorage.getItem("theme-storage");
  } catch (e) {
    /* ignore */
  }

  if (!currentTheme) {
    currentTheme = "auto";
  }

  // In 2-state toggle mode, "auto" is not valid — resolve to system preference.
  if (themeToggleMode === "toggle" && currentTheme === "auto") {
    currentTheme = getSystemPrefersDark() ? "dark" : "light";
    setTheme(currentTheme);
  }

  return currentTheme;
}

function updateItemToggleTheme() {
  var mode = getSavedTheme();
  var useDark = mode === "dark" || (mode === "auto" && getSystemPrefersDark());

  var htmlElement = document.documentElement;
  htmlElement.classList.remove(useDark ? "light" : "dark");
  htmlElement.classList.add(useDark ? "dark" : "light");

  var sunIcon = document.getElementById("sun-icon");
  var moonIcon = document.getElementById("moon-icon");
  var autoIcon = document.getElementById("auto-icon");

  if (sunIcon && moonIcon) {
    sunIcon.style.display = mode === "light" ? "block" : "none";
    moonIcon.style.display = mode === "dark" ? "block" : "none";

    if (autoIcon) {
      autoIcon.style.display = mode === "auto" ? "block" : "none";
      autoIcon.style.filter =
        mode === "auto" && getSystemPrefersDark() ? "invert(1)" : "none";
    }
  }
}

function toggleTheme() {
  var currentTheme = getSavedTheme();

  if (themeToggleMode === "toggle-auto") {
    // 3-state: light -> dark -> auto -> light
    if (currentTheme === "light") {
      setTheme("dark");
    } else if (currentTheme === "dark") {
      setTheme("auto");
    } else {
      setTheme("light");
    }
  } else {
    setTheme(currentTheme === "light" ? "dark" : "light");
  }

  updateItemToggleTheme();
}

// Run immediately (the script is loaded in <head>) so the page never paints in
// the wrong palette first.
updateItemToggleTheme();

if (window.matchMedia) {
  window
    .matchMedia("(prefers-color-scheme: dark)")
    .addEventListener("change", function () {
      if (getSavedTheme() === "auto") {
        updateItemToggleTheme();
      }
    });
}

document.addEventListener("DOMContentLoaded", updateItemToggleTheme);
