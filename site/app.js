// Avatar Copier site: language switch, menu, expandable cards, copy button, fade-in and parallax.
(function () {
  "use strict";

  var root = document.documentElement;
  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
  var finePointer = window.matchMedia("(hover: hover) and (pointer: fine)");
  var wide = window.matchMedia("(min-width: 961px)");

  // Portuguese text. English lives in the HTML itself, so the page reads fine without scripts.
  var PT = {
    "skip": "Pular para o conteúdo",
    "nav.features": "Recursos",
    "nav.how": "Como funciona",
    "nav.get": "Pegar o script",
    "nav.faq": "Dúvidas",
    "menu.open": "Abrir menu",
    "menu.close": "Fechar menu",
    "top": "Voltar ao topo",
    "hero.pill": "Grátis · Código aberto · Sem key",
    "hero.title": "Use <span class=\"shine\">qualquer avatar do Roblox</span> com um toque",
    "hero.lead": "Digite um nome, veja o avatar em 3D e coloque no seu personagem. Salve seus visuais favoritos, experimente itens do catálogo e troque de avatar enquanto joga.",
    "hero.cta": "Pegar o script",
    "hero.secondary": "Ver como funciona",
    "hero.note": "Roda no seu aparelho. Só você vê o novo avatar.",
    "float.applied": "Avatar aplicado",
    "float.applied.sub": "Toque em Undo para voltar",
    "float.saved": "Skin salva",
    "facts.tabs": "abas em uma janela",
    "facts.skins": "skins salvas",
    "facts.cycle": "avatares no ciclo",
    "facts.rigs": "PC e celular",
    "features.eyebrow": "Tudo em uma janela",
    "features.title": "Oito abas, zero confusão",
    "features.lead": "Cada aba faz uma coisa. Toque em um card para ver como usar.",
    "f1.title": "Copy Avatar",
    "f1.short": "Procure qualquer pessoa e use o avatar dela.",
    "f1.a": "Digite um nome, <code>@nome</code> ou ID de usuário.",
    "f1.b": "Arraste a prévia 3D para ver de todos os lados.",
    "f1.c": "Toque em <strong>Apply avatar</strong>. <strong>Undo</strong> e <strong>Restore</strong> fazem você voltar.",
    "f2.title": "Server",
    "f2.short": "Todo mundo do seu servidor, a um toque.",
    "f2.a": "Filtre a lista por nome ou ID.",
    "f2.b": "<strong>Wear</strong> coloca o avatar da pessoa em você na hora.",
    "f2.c": "<strong>Preview</strong> mostra em 3D antes. A estrela salva nos Favoritos.",
    "f3.title": "Favorites & Recent",
    "f3.short": "Seus perfis favoritos e os mais recentes.",
    "f3.a": "Até 200 favoritos e suas últimas 30 buscas.",
    "f3.b": "As duas listas ficam salvas no seu aparelho.",
    "f3.c": "Usar um favorito sempre carrega o avatar que a pessoa tem hoje.",
    "f4.title": "Saved Skins",
    "f4.short": "Guarde um visual para sempre e compartilhe.",
    "f4.a": "Monte o visual, digite um nome e toque em <strong>Save</strong>.",
    "f4.b": "Use de novo em qualquer jogo, exatamente igual.",
    "f4.c": "<strong>Share</strong> transforma a skin em um código para um amigo importar.",
    "f5.title": "Roblox Shop",
    "f5.short": "Experimente itens do catálogo no seu avatar.",
    "f5.a": "Busque por nome, ID do item ou link do catálogo.",
    "f5.b": "Filtre cabelos, cabeças, roupas, emotes e mais.",
    "f5.c": "<strong>Add</strong> ou <strong>Remove</strong> itens. Nada é comprado.",
    "f6.title": "Auto & Cycle",
    "f6.short": "Um avatar novo a cada morte ou tempo.",
    "f6.a": "Coloque um avatar assim que o script iniciar.",
    "f6.b": "Adicione até 50 avatares na lista do ciclo.",
    "f6.c": "Troque ao morrer, ao renascer ou a cada poucos minutos.",
    "f7.title": "Settings",
    "f7.short": "Padrões bons; mude só o que quiser.",
    "f7.a": "Deixe a janela maior ou menor.",
    "f7.b": "Mantenha o avatar depois de renascer e em novas rodadas.",
    "f7.c": "Escolha como reabrir a janela quando ela estiver escondida.",
    "f8.title": "Creator",
    "f8.short": "Quem fez e onde pedir ajuda.",
    "f8.a": "Entre no Discord para novidades e ajuda.",
    "f8.b": "Veja o perfil do lyraEz no GitHub.",
    "f8.c": "Toque em um link para copiar.",
    "chip.respawn": "Mantém o avatar ao renascer",
    "chip.rounds": "Devolve itens que o jogo remove",
    "chip.visual": "Modo só visual para jogos difíceis",
    "chip.hotkeys": "Câmera livre e atalhos",
    "chip.undo": "Desfaça qualquer coisa",
    "how.eyebrow": "Como funciona",
    "how.title": "Três passos. Só isso.",
    "how.1.title": "Copie o script",
    "how.1.text": "Toque em <strong>Copiar</strong> na caixa abaixo. É uma linha só.",
    "how.2.title": "Rode no seu executor",
    "how.2.text": "Cole e execute. A janela <strong>Avatar Studio</strong> abre.",
    "how.3.title": "Digite um nome e aplique",
    "how.3.text": "Procure qualquer pessoa em <strong>Copy Avatar</strong> e toque em <strong>Apply avatar</strong>.",
    "how.tip": "Mudou de ideia? <strong>Undo</strong> volta um passo e <strong>Restore</strong> traz seu avatar de volta.",
    "get.eyebrow": "Pegar o script",
    "get.title": "Copie, cole, jogue",
    "get.copy": "Copiar",
    "get.copied": "Copiado!",
    "get.selected": "Texto selecionado. Copie manualmente.",
    "get.source": "Ver o código",
    "get.guide": "Guia passo a passo",
    "get.fine": "Você precisa de um executor de Roblox que rode scripts no cliente. Executores de terceiros vão contra os Termos de Uso do Roblox, então use por sua conta e risco.",
    "open.eyebrow": "Grátis e aberto",
    "open.title": "Nada escondido",
    "open.1.title": "Grátis, sempre",
    "open.1.text": "Sem key, sem encurtador de link, sem pagamento.",
    "open.2.title": "Código aberto",
    "open.2.text": "Todo o código é público, sob a licença GPL-3.0. Leia, aprenda e melhore.",
    "open.3.title": "Seus dados ficam com você",
    "open.3.text": "Sem rastreamento. Favoritos, skins e configurações ficam só no seu aparelho.",
    "open.4.title": "Confere o que lê",
    "open.4.text": "Códigos compartilhados são verificados antes de qualquer coisa ser montada.",
    "faq.eyebrow": "Dúvidas",
    "faq.title": "Bom saber",
    "q1": "Os outros jogadores veem meu novo avatar?",
    "a1": "Não. A mudança acontece no seu aparelho, então os outros continuam vendo seu avatar normal. A exceção são as animações: o Roblox mostra para todos as animações que seu personagem faz.",
    "q2": "Como pego meu avatar de volta?",
    "a2": "Toque em <strong>Restore</strong> embaixo da prévia. <strong>Undo</strong> volta um passo, e as fotos da linha do tempo voltam para qualquer visual da sessão.",
    "q3": "Fechei a janela. Como abro de novo?",
    "a3": "Toque no botão flutuante <strong>AC</strong>, aperte <kbd>Ctrl direito</kbd>, digite <code>/e copier</code> no chat ou abra e feche o menu do Roblox 3 vezes seguidas.",
    "q4": "O jogo bugou depois de aplicar um avatar. E agora?",
    "a4": "Renasça, abra <strong>Settings</strong>, toque em <strong>Show advanced options</strong> e ligue <strong>Visual-only avatar</strong>. Ele desenha o avatar por cima do seu personagem sem mudar nada nele.",
    "q5": "Funciona no celular?",
    "a5": "Sim. A janela se adapta a telas pequenas e tudo nela funciona por toque. Só os atalhos de teclado precisam de teclado.",
    "q6": "É grátis mesmo?",
    "a6": "Sim, e sempre foi. Não tem key nem nada para comprar, e todo o código é público.",
    "footer.by": "Feito por lyraEz",
    "footer.docs": "Documentação",
    "footer.license": "Licença",
    "footer.note": "Não é afiliado nem endossado pela Roblox Corporation.",
    "doc.title": "Avatar Copier: use qualquer avatar do Roblox",
    "doc.description": "Script de Roblox grátis e de código aberto. Digite um nome, veja o avatar em 3D e coloque no seu personagem com um toque."
  };

  var original = {};
  var originalAttrs = [];
  var lang = "en";

  function saveOriginals() {
    document.querySelectorAll("[data-i18n]").forEach(function (el) {
      var key = el.getAttribute("data-i18n");
      if (!(key in original)) original[key] = el.innerHTML;
    });
    document.querySelectorAll("[data-i18n-attr]").forEach(function (el) {
      el.getAttribute("data-i18n-attr").split(";").forEach(function (pair) {
        var parts = pair.split(":");
        originalAttrs.push({ el: el, attr: parts[0], key: parts[1], value: el.getAttribute(parts[0]) });
      });
    });
    original["doc.title"] = document.title;
    var description = document.querySelector('meta[name="description"]');
    original["doc.description"] = description ? description.getAttribute("content") : "";
  }

  function text(key) {
    if (lang === "pt" && PT[key] != null) return PT[key];
    return original[key];
  }

  function applyLanguage(next) {
    lang = next === "pt" ? "pt" : "en";
    root.lang = lang === "pt" ? "pt-BR" : "en";
    document.querySelectorAll("[data-i18n]").forEach(function (el) {
      var value = text(el.getAttribute("data-i18n"));
      if (value != null && el.innerHTML !== value) el.innerHTML = value;
    });
    originalAttrs.forEach(function (row) {
      var value = lang === "pt" && PT[row.key] != null ? PT[row.key] : row.value;
      if (value != null) row.el.setAttribute(row.attr, value);
    });
    document.title = text("doc.title");
    var description = document.querySelector('meta[name="description"]');
    if (description) description.setAttribute("content", text("doc.description"));
    document.querySelectorAll(".lang button").forEach(function (button) {
      button.setAttribute("aria-pressed", String(button.getAttribute("data-lang") === lang));
    });
    updateMenuLabel();
    root.classList.remove("pending-lang");
  }

  function storedLanguage() {
    var saved = null;
    try { saved = localStorage.getItem("lang"); } catch (e) {}
    if (saved === "pt" || saved === "en") return saved;
    return /^pt/i.test(navigator.language || "") ? "pt" : "en";
  }

  // Header and menu
  var topbar = document.querySelector(".topbar");
  var nav = document.getElementById("nav");
  var menuButton = document.querySelector(".menu-button");
  var menuGlyph = menuButton.querySelector(".glyph");

  function updateMenuLabel() {
    var open = nav.classList.contains("is-open");
    var key = open ? "menu.close" : "menu.open";
    var label = lang === "pt" ? PT[key] : (open ? "Close menu" : "Open menu");
    menuButton.setAttribute("aria-label", label);
  }

  function setMenu(open) {
    nav.classList.toggle("is-open", open);
    menuButton.setAttribute("aria-expanded", String(open));
    menuGlyph.classList.toggle("g-menu", !open);
    menuGlyph.classList.toggle("g-x", open);
    updateMenuLabel();
  }

  menuButton.addEventListener("click", function () { setMenu(!nav.classList.contains("is-open")); });
  nav.addEventListener("click", function (event) { if (event.target.closest("a")) setMenu(false); });
  document.addEventListener("keydown", function (event) {
    if (event.key === "Escape" && nav.classList.contains("is-open")) { setMenu(false); menuButton.focus(); }
  });
  document.addEventListener("click", function (event) {
    if (nav.classList.contains("is-open") && !nav.contains(event.target) && !menuButton.contains(event.target)) setMenu(false);
  });
  window.matchMedia("(min-width: 861px)").addEventListener("change", function (query) { if (query.matches) setMenu(false); });

  document.querySelectorAll(".lang button").forEach(function (button) {
    button.addEventListener("click", function () {
      var next = button.getAttribute("data-lang");
      try { localStorage.setItem("lang", next); } catch (e) {}
      applyLanguage(next);
    });
  });

  // Expandable cards and questions
  function bindToggle(button, holder) {
    button.addEventListener("click", function () {
      var open = button.getAttribute("aria-expanded") !== "true";
      button.setAttribute("aria-expanded", String(open));
      holder.classList.toggle("is-open", open);
    });
  }
  document.querySelectorAll(".card").forEach(function (card) { bindToggle(card.querySelector(".card-toggle"), card); });
  document.querySelectorAll(".faq-item").forEach(function (item) { bindToggle(item.querySelector("button"), item); });

  // Copy the script line
  var status = document.getElementById("copy-status");
  document.querySelectorAll("[data-copy]").forEach(function (button) {
    var label = button.querySelector("span");
    var icon = button.querySelector(".glyph");
    var timer = null;
    button.addEventListener("click", function () {
      var source = document.querySelector(button.getAttribute("data-copy"));
      var value = source.textContent.trim();
      function done() {
        button.classList.add("is-done");
        icon.classList.replace("g-copy", "g-check");
        label.textContent = lang === "pt" ? PT["get.copied"] : "Copied!";
        status.textContent = label.textContent;
        clearTimeout(timer);
        timer = setTimeout(function () {
          button.classList.remove("is-done");
          icon.classList.replace("g-check", "g-copy");
          label.textContent = text("get.copy");
        }, 2200);
      }
      function fallback() {
        var area = document.createElement("textarea");
        area.value = value;
        area.setAttribute("readonly", "");
        area.className = "sr-only";
        document.body.appendChild(area);
        area.select();
        var ok = false;
        try { ok = document.execCommand("copy"); } catch (e) {}
        document.body.removeChild(area);
        if (ok) { done(); return; }
        var range = document.createRange();
        range.selectNodeContents(source);
        var selection = window.getSelection();
        selection.removeAllRanges();
        selection.addRange(range);
        status.textContent = lang === "pt" ? PT["get.selected"] : "Text selected. Copy it manually.";
      }
      if (navigator.clipboard && window.isSecureContext) {
        navigator.clipboard.writeText(value).then(done, fallback);
      } else {
        fallback();
      }
    });
  });

  // Fade in on scroll. Once visible, the reveal classes go away so hover transitions work normally.
  var reveals = Array.prototype.slice.call(document.querySelectorAll(".reveal"));
  function settle(el) {
    var delay = parseFloat(el.style.getPropertyValue("--delay")) || 0;
    setTimeout(function () { el.classList.remove("reveal", "is-visible"); el.style.removeProperty("--delay"); }, 850 + delay * 1000);
  }
  if ("IntersectionObserver" in window && !reduceMotion.matches) {
    var groups = new Map();
    reveals.forEach(function (el) {
      var parent = el.parentElement;
      var index = groups.get(parent) || 0;
      groups.set(parent, index + 1);
      el.style.setProperty("--delay", Math.min(index, 6) * 0.07 + "s");
    });
    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
        settle(entry.target);
      });
    }, { rootMargin: "0px 0px -8% 0px", threshold: 0.08 });
    reveals.forEach(function (el) { observer.observe(el); });
  } else {
    reveals.forEach(function (el) { el.classList.remove("reveal"); });
  }

  // Parallax: background fields drift with the scroll; the hero layers follow scroll and pointer.
  var layers = Array.prototype.slice.call(document.querySelectorAll("[data-parallax]"));
  var stage = document.querySelector(".stage");
  var depthLayers = stage ? Array.prototype.slice.call(stage.querySelectorAll("[data-depth]")) : [];
  var toTop = document.querySelector(".to-top");
  var pointer = { x: 0, y: 0 };
  var ticking = false;

  function frame() {
    ticking = false;
    var y = window.scrollY || window.pageYOffset;
    topbar.classList.toggle("is-scrolled", y > 8);
    toTop.classList.toggle("is-shown", y > 700);
    if (reduceMotion.matches) return;
    layers.forEach(function (layer) {
      var speed = parseFloat(layer.getAttribute("data-parallax")) || 0;
      layer.style.transform = "translate3d(0," + (y * speed).toFixed(1) + "px,0)";
    });
    // Only on wide screens: on phones the floating cards would drift over the text above them.
    if (stage && wide.matches && y < window.innerHeight * 1.5) {
      var tilt = finePointer.matches;
      depthLayers.forEach(function (layer) {
        var depth = parseFloat(layer.getAttribute("data-depth")) || 0;
        var dx = tilt ? pointer.x * depth * 10 : 0;
        var dy = Math.max(-36, Math.min(36, -y * depth * 0.05)) + (tilt ? pointer.y * depth * 8 : 0);
        var rotate = tilt && layer.classList.contains("stage-window")
          ? " rotateX(" + (-pointer.y * 4).toFixed(2) + "deg) rotateY(" + (pointer.x * 5).toFixed(2) + "deg)"
          : "";
        layer.style.transform = "translate3d(" + dx.toFixed(1) + "px," + dy.toFixed(1) + "px,0)" + rotate;
      });
    }
  }
  function request() {
    if (!ticking) { ticking = true; window.requestAnimationFrame(frame); }
  }
  window.addEventListener("scroll", request, { passive: true });
  window.addEventListener("resize", request);
  if (stage) {
    window.addEventListener("pointermove", function (event) {
      if (!finePointer.matches || reduceMotion.matches) return;
      pointer.x = (event.clientX / window.innerWidth - 0.5) * 2;
      pointer.y = (event.clientY / window.innerHeight - 0.5) * 2;
      request();
    }, { passive: true });
  }
  wide.addEventListener("change", function () {
    depthLayers.forEach(function (layer) { layer.style.removeProperty("transform"); });
    request();
  });
  reduceMotion.addEventListener("change", function () {
    layers.concat(depthLayers).forEach(function (layer) { layer.style.removeProperty("transform"); });
    request();
  });

  saveOriginals();
  applyLanguage(storedLanguage());
  frame();
})();
