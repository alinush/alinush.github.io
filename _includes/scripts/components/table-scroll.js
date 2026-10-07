// Tags each Markdown table as .table--fits or .table--scrolls, depending on
// whether it overflows the article column, so its header can be sticky.
// See "Sticky table headers" in _sass/custom.scss for why this is needed.
(function () {
  var tables = document.querySelectorAll('.article__content table');
  if (tables.length === 0) { return; }

  function update(table) {
    // Measure with the theme's default `overflow: auto` in effect.
    table.classList.remove('table--fits', 'table--scrolls');
    var scrolls = table.scrollWidth > table.clientWidth + 1;
    table.classList.add(scrolls ? 'table--scrolls' : 'table--fits');
  }

  Array.prototype.forEach.call(tables, update);

  // Re-check when widths change: window resizes, and MathJax typesetting
  // cells after this runs.
  if (window.ResizeObserver) {
    var observer = new ResizeObserver(function (entries) {
      entries.forEach(function (entry) {
        var table = entry.target.closest('table');
        if (table) { update(table); }
      });
    });
    Array.prototype.forEach.call(tables, function (table) {
      observer.observe(table);
      // The table's own box can stay the same size while its content grows,
      // so also watch the content.
      Array.prototype.forEach.call(table.rows, function (row) { observer.observe(row); });
    });
  } else {
    window.addEventListener('resize', function () {
      Array.prototype.forEach.call(tables, update);
    });
  }
})();
