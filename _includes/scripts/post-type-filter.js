(function() {
  var SOURCES = window.TEXT_VARIABLES.sources;
  var STORAGE_KEY = 'postTypeFilter';
  var VALID_TYPES = { all: true, article: true, note: true };

  function loadState() {
    try {
      var raw = window.localStorage.getItem(STORAGE_KEY);
      if (raw && VALID_TYPES[raw]) {
        return raw;
      }
    } catch (e) {
      // localStorage unavailable (private browsing, etc.) - fall through to the default.
    }
    return 'all';
  }

  function saveState(state) {
    try {
      window.localStorage.setItem(STORAGE_KEY, state);
    } catch (e) {
      // Nothing to do if it can't persist - the filter still works this visit.
    }
  }

  window.Lazyload.js(SOURCES.jquery, function() {
    // Single-select, exactly like tags.html's "Show All"/one-tag buttons:
    // one of Show all posts/Articles/Notes is active at a time, not
    // independent on/off toggles.
    var state = loadState();
    var $filter = $('.js-post-type-filter');
    var $buttons = $filter.find('.type-button');
    var $result = $('.js-result');
    var $tagShowAll = $('.js-tags .tag-button--all');
    var $tagButtons = $('.js-tags .tag-button').not($tagShowAll);

    // How many articles vs. notes actually carry each tag, and how many
    // articles/notes there are in total - computed once up front from
    // every .item's own data-tags/data-type (which never change), so
    // switching the type filter can correctly hide a tag button with zero
    // matches for the newly selected type, and show a correct count,
    // without re-deriving this from the DOM on every click. Articles and
    // notes don't share the same set of tags, so without this a tag
    // button stays listed (and clickable) even when it doesn't apply at
    // all to whichever type is currently selected.
    var totalsByType = { article: 0, note: 0 };
    var tagCountsByType = {}; // encoded tag -> { article: n, note: n }
    $result.find('.item').each(function() {
      var $item = $(this);
      var type = $item.data('type');
      totalsByType[type] = (totalsByType[type] || 0) + 1;
      var tags = ($item.data('tags') || '').toString().split(',');
      for (var i = 0; i < tags.length; i++) {
        var tag = tags[i];
        if (!tag) {
          continue;
        }
        tagCountsByType[tag] = tagCountsByType[tag] || { article: 0, note: 0 };
        tagCountsByType[tag][type] = (tagCountsByType[tag][type] || 0) + 1;
      }
    });

    function countForCurrentType(counts) {
      if (state === 'article') {
        return counts.article || 0;
      }
      if (state === 'note') {
        return counts.note || 0;
      }
      return (counts.article || 0) + (counts.note || 0);
    }

    function render() {
      $buttons.each(function() {
        var $btn = $(this);
        var active = $btn.data('type') === state;
        $btn.toggleClass('focus', active);
        $btn.attr('aria-pressed', active ? 'true' : 'false');
      });
    }

    // Hides/shows each .item by post type, fixes up each year .section's
    // own visibility to match (archieve.js only knows about tags, so a
    // section it left visible for a tag match can still end up with every
    // item hidden here by type), and hides/relabels tag buttons that don't
    // apply to the current type.
    function applyFilter() {
      $result.find('.item').each(function() {
        var $item = $(this);
        var visible = (state === 'all') || ($item.data('type') === state);
        $item.toggleClass('type-hidden', !visible);
      });
      $result.find('section').each(function() {
        var anyVisible = $(this).find('.item').toArray().some(function(el) {
          var $el = $(el);
          return !$el.hasClass('d-none') && !$el.hasClass('type-hidden');
        });
        $(this).toggleClass('d-none', !anyVisible);
      });

      $tagShowAll.find('.tag-button__count').text(countForCurrentType(totalsByType));
      $tagButtons.each(function() {
        var $btn = $(this);
        var counts = tagCountsByType[$btn.data('encode')] || { article: 0, note: 0 };
        var count = countForCurrentType(counts);
        $btn.toggleClass('type-hidden', count === 0);
        $btn.find('.tag-button__count').text(count);
      });
    }

    render();
    applyFilter();

    $filter.on('click', '.type-button', function() {
      state = $(this).data('type');
      saveState(state);
      render();
      applyFilter();
    });

    // Re-run the type filter (and the tag-button visibility/counts it
    // updates) after every tag click too. This binds after archieve.js's
    // own click handler on the same buttons (this script is included
    // after it in the layout, and jQuery fires same-event handlers in
    // binding order), so it always runs second and layers back on top of
    // whatever archieve.js just did purely by tag.
    $('.js-tags').on('click', 'button', function() {
      applyFilter();
    });
  });
})();
