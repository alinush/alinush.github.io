// Copy button + language label on code blocks, adapted from the Apollo Zola
// theme. Zola tags `<code data-lang=...>`; Rouge instead wraps the block in
// `<div class="language-xxx highlighter-rouge">`, so the language is read from
// there.

(function () {
  "use strict";

  var successIcon =
    '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16"><path d="M13.485 1.85a.5.5 0 0 1 1.065.02.75.75 0 0 1-.02 1.065L5.82 12.78a.75.75 0 0 1-1.106.02L1.476 9.346a.75.75 0 1 1 1.05-1.07l2.74 2.742L12.44 2.92a.75.75 0 0 1 1.045-.07z"/></svg>';
  var errorIcon =
    '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16"><path d="M2.293 2.293a1 1 0 0 1 1.414 0L8 6.586l4.293-4.293a1 1 0 0 1 1.414 1.414L9.414 8l4.293 4.293a1 1 0 0 1-1.414 1.414L8 9.414l-4.293 4.293a1 1 0 0 1-1.414-1.414L6.586 8 2.293 3.707a1 1 0 0 1 0-1.414z"/></svg>';
  var copyIcon =
    '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16"><path d="M10 1.5a.5.5 0 0 1 .5-.5h2a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-9a2 2 0 0 1-2-2V3a2 2 0 0 1 2-2h2a.5.5 0 0 1 .5.5V3h3V1.5zM6.5 3V2h3v1h-3zm4 0v1h2a1 1 0 0 0-1-1h-2V3zm-5 0H3a1 1 0 0 0-1 1v11a1 1 0 0 0 1 1h9a1 1 0 0 0 1-1V4a1 1 0 0 0-1-1H5.5V3z"/></svg>';

  function changeIcon(button, isSuccess) {
    button.innerHTML = isSuccess ? successIcon : errorIcon;
    setTimeout(function () {
      button.innerHTML = copyIcon;
    }, 2000);
  }

  function languageOf(pre) {
    var wrapper = pre.closest("[class*='language-']");
    if (!wrapper) return "default";
    var match = /(?:^|\s)language-([\w+#-]+)/.exec(wrapper.className);
    return match ? match[1] : "default";
  }

  document.addEventListener("DOMContentLoaded", function () {
    document.querySelectorAll("pre > code").forEach(function (codeBlock) {
      // Mermaid and Chart.js blocks are rendered into diagrams, not read as
      // source, so they get neither a copy button nor a language label.
      if (
        codeBlock.classList.contains("language-mermaid") ||
        codeBlock.classList.contains("language-chart")
      ) {
        return;
      }

      var pre = codeBlock.parentNode;
      pre.style.position = "relative";

      var copyBtn = document.createElement("button");
      copyBtn.className = "clipboard-button";
      copyBtn.innerHTML = copyIcon;
      copyBtn.setAttribute("aria-label", "Copy code to clipboard");
      pre.appendChild(copyBtn);

      copyBtn.addEventListener("click", function () {
        var text = codeBlock.textContent.replace(/\s+$/, "");
        if (!navigator.clipboard) {
          changeIcon(copyBtn, false);
          return;
        }
        navigator.clipboard.writeText(text).then(
          function () {
            changeIcon(copyBtn, true);
          },
          function () {
            changeIcon(copyBtn, false);
          }
        );
      });

      var lang = languageOf(pre);
      var label = document.createElement("span");
      label.className = "code-label label-" + lang;
      label.textContent = lang.toUpperCase();
      pre.appendChild(label);

      // Keep the button and label pinned to the visible right edge while a
      // wide block is scrolled horizontally.
      var ticking = false;
      pre.addEventListener("scroll", function () {
        if (ticking) return;
        ticking = true;
        window.requestAnimationFrame(function () {
          copyBtn.style.right = -pre.scrollLeft + 5 + "px";
          label.style.right = -pre.scrollLeft + "px";
          ticking = false;
        });
      });
    });
  });
})();
