// Builds the right-hand table of contents from the rendered article and keeps
// the current section highlighted while scrolling.
//
// Apollo gets `page.toc` from Zola; Jekyll has no equivalent, so the tree is
// assembled client-side from the heading ids kramdown already emits.

(function () {
  "use strict";

  function buildToc() {
    var root = document.querySelector(".js-toc");
    if (!root) return null;

    var scope = document.querySelector(root.dataset.tocSource || ".body");
    if (!scope) {
      root.remove();
      return null;
    }

    var selector = root.dataset.tocSelectors || "h1,h2,h3";
    var headings = [].slice
      .call(scope.querySelectorAll(selector))
      .filter(function (h) {
        return h.id && !h.closest(".footnotes");
      });

    if (headings.length < 2) {
      root.remove();
      return null;
    }

    var list = document.createElement("ul");
    list.className = "toc-list";

    var minLevel = Math.min.apply(
      null,
      headings.map(function (h) {
        return parseInt(h.tagName.substring(1), 10);
      })
    );

    // One stack entry per currently-open nesting depth.
    var stack = [{ level: minLevel, ul: list }];

    headings.forEach(function (heading) {
      var level = parseInt(heading.tagName.substring(1), 10);

      while (stack.length > 1 && level < stack[stack.length - 1].level) {
        stack.pop();
      }

      if (level > stack[stack.length - 1].level) {
        var host = stack[stack.length - 1].ul.lastElementChild;
        if (!host) {
          // A deeper heading with no shallower one before it: give the nested
          // list something to hang off.
          host = document.createElement("li");
          stack[stack.length - 1].ul.appendChild(host);
        }
        var nested = document.createElement("ul");
        host.appendChild(nested);
        stack.push({ level: level, ul: nested });
      }

      var li = document.createElement("li");
      if (level === minLevel) li.className = "parent";

      var a = document.createElement("a");
      a.href = "#" + heading.id;
      a.textContent = (heading.textContent || "").trim();
      li.appendChild(a);
      stack[stack.length - 1].ul.appendChild(li);
    });

    root.appendChild(list);
    return { headings: headings, root: root };
  }

  function scrollSpy(built) {
    if (!built || !window.IntersectionObserver) return;

    var links = {};
    [].slice.call(built.root.querySelectorAll("a")).forEach(function (a) {
      links[decodeURIComponent(a.hash.substring(1))] = a;
    });

    var visible = Object.create(null);

    function repaint() {
      // Highlight the topmost heading currently on screen; failing that, the
      // last one already scrolled past.
      var current = null;
      var lastPassed = null;

      built.headings.forEach(function (h) {
        if (visible[h.id]) {
          if (!current) current = h.id;
        } else if (h.getBoundingClientRect().top < 0) {
          lastPassed = h.id;
        }
      });

      if (!current) current = lastPassed;

      [].slice.call(built.root.querySelectorAll("li")).forEach(function (li) {
        li.classList.remove("selected");
      });

      if (!current || !links[current]) return;

      var li = links[current].closest("li");
      while (li) {
        li.classList.add("selected");
        li = li.parentElement ? li.parentElement.closest("li") : null;
      }
    }

    var observer = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          visible[entry.target.id] = entry.isIntersecting;
        });
        repaint();
      },
      { rootMargin: "0px 0px -70% 0px" }
    );

    built.headings.forEach(function (h) {
      observer.observe(h);
    });
  }

  document.addEventListener("DOMContentLoaded", function () {
    scrollSpy(buildToc());
  });
})();
