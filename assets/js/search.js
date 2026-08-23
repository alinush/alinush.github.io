// Search modal, in the Apollo style but backed by a small JSON index that
// Jekyll generates at /assets/search-index.json (Zola builds an elasticlunr
// index; there is no equivalent here, so this does a straightforward
// substring/term match over titles, tags and excerpts).

(function () {
  "use strict";

  var MAX_RESULTS = 12;
  var index = null;
  var indexPromise = null;
  var activeIndex = -1;
  var currentResults = [];

  function loadIndex(url) {
    if (indexPromise) return indexPromise;
    indexPromise = fetch(url)
      .then(function (r) {
        return r.json();
      })
      .then(function (data) {
        index = data.map(function (entry) {
          entry.haystack = (
            entry.title +
            " " +
            entry.tags +
            " " +
            entry.preview
          ).toLowerCase();
          return entry;
        });
        return index;
      })
      .catch(function () {
        index = [];
        return index;
      });
    return indexPromise;
  }

  function score(entry, terms) {
    var title = entry.title.toLowerCase();
    var total = 0;

    for (var i = 0; i < terms.length; i++) {
      var term = terms[i];
      if (entry.haystack.indexOf(term) === -1) return 0; // every term must hit
      total += 1;
      if (title.indexOf(term) !== -1) total += 4;
      if (title.indexOf(term) === 0) total += 2;
    }

    return total;
  }

  function search(query) {
    if (!index) return [];
    var terms = query.toLowerCase().split(/\s+/).filter(Boolean);
    if (!terms.length) return [];

    return index
      .map(function (entry) {
        return { entry: entry, score: score(entry, terms) };
      })
      .filter(function (hit) {
        return hit.score > 0;
      })
      .sort(function (a, b) {
        return b.score - a.score || (b.entry.date > a.entry.date ? 1 : -1);
      })
      .slice(0, MAX_RESULTS)
      .map(function (hit) {
        return hit.entry;
      });
  }

  document.addEventListener("DOMContentLoaded", function () {
    var button = document.getElementById("search-button");
    var modal = document.getElementById("searchModal");
    if (!button || !modal) return;

    var input = document.getElementById("searchInput");
    var clear = document.getElementById("clear-search");
    var container = document.getElementById("results-container");
    var results = document.getElementById("results");
    var info = {
      zero: document.getElementById("zero_results"),
      one: document.getElementById("one_result"),
      many: document.getElementById("many_results"),
    };
    var indexUrl = modal.dataset.searchIndex;

    function setActive(i) {
      var nodes = results.children;
      if (!nodes.length) return;
      if (activeIndex >= 0 && nodes[activeIndex]) {
        nodes[activeIndex].removeAttribute("aria-selected");
      }
      activeIndex = (i + nodes.length) % nodes.length;
      nodes[activeIndex].setAttribute("aria-selected", "true");
      nodes[activeIndex].scrollIntoView({ block: "nearest" });
    }

    function render(entries) {
      currentResults = entries;
      results.innerHTML = "";
      activeIndex = -1;

      entries.forEach(function (entry, i) {
        var a = document.createElement("a");
        a.href = entry.url;

        var title = document.createElement("span");
        title.className = "result-title";
        title.textContent = entry.title;
        a.appendChild(title);

        var preview = document.createElement("span");
        preview.className = "result-preview";
        preview.textContent =
          entry.preview || (entry.tags ? "#" + entry.tags : entry.kind);
        a.appendChild(preview);

        a.addEventListener("mouseenter", function () {
          setActive(i);
        });
        results.appendChild(a);
      });

      info.zero.style.display = entries.length === 0 ? "inline" : "none";
      info.one.style.display = entries.length === 1 ? "inline" : "none";
      info.many.style.display = entries.length > 1 ? "inline" : "none";
      info.many.textContent = entries.length + " results";

      if (entries.length) setActive(0);
    }

    function runQuery() {
      var query = input.value.trim();
      clear.style.display = query ? "block" : "none";

      if (!query) {
        container.style.display = "none";
        results.innerHTML = "";
        return;
      }

      container.style.display = "block";
      loadIndex(indexUrl).then(function () {
        render(search(query));
      });
    }

    function open() {
      modal.classList.add("is-open");
      loadIndex(indexUrl);
      input.focus();
      input.select();
    }

    function close() {
      modal.classList.remove("is-open");
    }

    button.addEventListener("click", open);
    clear.addEventListener("click", function () {
      input.value = "";
      runQuery();
      input.focus();
    });

    modal.addEventListener("click", function (e) {
      if (e.target === modal) close();
    });

    input.addEventListener("input", runQuery);

    input.addEventListener("keydown", function (e) {
      if (e.key === "ArrowDown") {
        e.preventDefault();
        setActive(activeIndex + 1);
      } else if (e.key === "ArrowUp") {
        e.preventDefault();
        setActive(activeIndex - 1);
      } else if (e.key === "Enter") {
        if (currentResults[activeIndex]) {
          window.location.href = currentResults[activeIndex].url;
        }
      }
    });

    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape" && modal.classList.contains("is-open")) {
        close();
        return;
      }

      // "/" and ctrl/cmd-K open search, as long as the user isn't typing.
      var typing = /^(INPUT|TEXTAREA|SELECT)$/.test(
        (e.target.tagName || "").toUpperCase()
      );
      if (typing) return;

      if (e.key === "/" || ((e.metaKey || e.ctrlKey) && e.key === "k")) {
        e.preventDefault();
        open();
      }
    });
  });
})();
