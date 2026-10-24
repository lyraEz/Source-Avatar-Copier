// Runs before the page is drawn: marks that scripts work, and hides the page for a moment
// when it is about to switch to Portuguese, so English text doesn't flash first.
(function () {
  var root = document.documentElement;
  root.className = root.className.replace("no-js", "js");
  var lang = null;
  try { lang = localStorage.getItem("lang"); } catch (e) {}
  if (!lang) lang = /^pt/i.test(navigator.language || "") ? "pt" : "en";
  if (lang === "pt") {
    root.classList.add("pending-lang");
    setTimeout(function () { root.classList.remove("pending-lang"); }, 1200);
  }
})();
