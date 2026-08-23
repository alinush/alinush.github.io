// Tag filtering for the /posts and /notes listings.
//
// Each entry carries its tags in `data-tags`; the selected tag is mirrored into
// the query string so that links like /posts.html?tag=zk keep working.

(function () {
  "use strict";

  function currentTag() {
    var match = /[?&]tag=([^&]*)/.exec(window.location.search);
    return match ? match[1] : "";
  }

  function setUrlTag(encodedTag) {
    var base = window.location.href.split("?")[0];
    window.history.replaceState(
      null,
      "",
      encodedTag ? base + "?tag=" + encodedTag : base
    );
  }

  document.addEventListener("DOMContentLoaded", function () {
    var filter = document.querySelector(".js-tag-filter");
    var result = document.querySelector(".js-post-list");
    if (!result) return;

    var items = [].slice.call(result.querySelectorAll(".list-item"));
    var groups = [].slice.call(result.querySelectorAll(".year-group"));
    var buttons = filter
      ? [].slice.call(filter.querySelectorAll(".tag-button"))
      : [];

    function select(encodedTag) {
      var tag = "";
      try {
        tag = decodeURIComponent(encodedTag || "");
      } catch (e) {
        tag = encodedTag || "";
      }

      items.forEach(function (item) {
        var tags = (item.dataset.tags || "").split(",");
        var show = !tag || tags.indexOf(tag) !== -1;
        item.classList.toggle("d-none", !show);
      });

      groups.forEach(function (group) {
        var anyVisible = [].slice
          .call(group.querySelectorAll(".list-item"))
          .some(function (item) {
            return !item.classList.contains("d-none");
          });
        group.classList.toggle("d-none", !anyVisible);
      });

      var matched = false;
      buttons.forEach(function (button) {
        var isMatch = (button.dataset.encode || "") === (encodedTag || "");
        button.classList.toggle("focus", isMatch);
        if (isMatch) matched = true;
      });

      // An unknown ?tag= should not leave every button unhighlighted.
      if (!matched && buttons.length) buttons[0].classList.add("focus");

      result.classList.remove("d-none");
    }

    buttons.forEach(function (button) {
      button.addEventListener("click", function () {
        var encoded = button.dataset.encode || "";
        select(encoded);
        setUrlTag(encoded);
      });
    });

    select(currentTag());
  });
})();
