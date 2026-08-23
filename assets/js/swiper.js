// Minimal image carousel for the `.swiper` markup a few posts use (see /moto).
// Replaces the previous theme's jQuery plugin; no dependencies.

(function () {
  "use strict";

  function initSwiper(root) {
    var wrapper = root.querySelector(".swiper__wrapper");
    var slides = [].slice.call(root.querySelectorAll(".swiper__slide"));
    var prev = root.querySelector(".swiper__button--prev");
    var next = root.querySelector(".swiper__button--next");

    if (!wrapper || slides.length === 0) return;

    var index = 0;

    function render(animate) {
      wrapper.classList.toggle("swiper__wrapper--animation", !!animate);
      wrapper.style.transform = "translateX(" + -index * 100 + "%)";

      slides.forEach(function (slide, i) {
        slide.classList.toggle("active", i === index);
      });

      if (prev) prev.classList.toggle("disabled", index === 0);
      if (next) next.classList.toggle("disabled", index === slides.length - 1);
    }

    function go(delta) {
      var target = index + delta;
      if (target < 0 || target >= slides.length) return;
      index = target;
      render(true);
    }

    if (slides.length < 2) {
      if (prev) prev.classList.add("d-none");
      if (next) next.classList.add("d-none");
    }

    // The arrows are marked up with Font Awesome classes; draw a plain glyph
    // when that stylesheet isn't there to supply one.
    [[prev, "\u2039"], [next, "\u203A"]].forEach(function (pair) {
      var button = pair[0];
      if (!button || button.childNodes.length) return;
      var before = window.getComputedStyle(button, "::before").content;
      if (!before || before === "none" || before === '""') {
        button.textContent = pair[1];
      }
    });

    if (prev) prev.addEventListener("click", function () { go(-1); });
    if (next) next.addEventListener("click", function () { go(1); });

    root.addEventListener("keydown", function (e) {
      if (e.key === "ArrowLeft") go(-1);
      if (e.key === "ArrowRight") go(1);
    });

    // Basic touch support.
    var startX = null;
    root.addEventListener("touchstart", function (e) {
      startX = e.touches[0].clientX;
    }, { passive: true });
    root.addEventListener("touchend", function (e) {
      if (startX === null) return;
      var dx = e.changedTouches[0].clientX - startX;
      if (Math.abs(dx) > 40) go(dx < 0 ? 1 : -1);
      startX = null;
    });

    root.setAttribute("tabindex", "0");
    render(false);
  }

  document.addEventListener("DOMContentLoaded", function () {
    document.querySelectorAll(".swiper").forEach(initSwiper);
  });
})();
