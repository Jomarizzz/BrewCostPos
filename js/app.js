/* ============================================================
   Brew Haven POS — application logic (vanilla JavaScript)
   Cashier POS · Admin dashboards · costing · stock · receipts
   ============================================================ */
(() => {
  "use strict";

  /* ============================================================
     DATA / STATE
     ============================================================ */
  const CAT_STYLE = {
    "All":        { label:"All",        color:"#e8eef5", text:"#0b1f33" },
    "Coffee":     { label:"Coffee",     color:"#c4a484", text:"#0b1f33" },
    "Non-coffee": { label:"Non-coffee", color:"#a8d8ea", text:"#0b1f33" },
    "Pastries":   { label:"Pastries",   color:"#f7d6a8", text:"#0b1f33" },
    "Meals":      { label:"Meals",      color:"#b8e0a8", text:"#0b1f33" },
  };
  const DEFAULT_CAT = { label:"Other", color:"#8fa3c4", text:"#0b1f33" };
  const SERVICE_RATE = 0.05;
  const SHOP = {
    name: "Brew Haven",
    place: "Mabini, Batangas",
    gcash: "",                  // Enter the real GCash number here before use
  };

  /* COFFEE ONLY — matches the paper & the Brew Haven old system */
  const FALLBACK_MENU = [
    { id:1, cat:"Coffee", name:"Spanish Latte", price:150, description:"Sweet condensed milk espresso", icon:"☕", available:true },
    { id:2, cat:"Coffee", name:"Cappuccino", price:130, description:"Espresso with steamed milk foam", icon:"☕", available:true },
    { id:3, cat:"Coffee", name:"Americano", price:110, description:"Double shot with hot water", icon:"☕", available:true },
    { id:4, cat:"Coffee", name:"Café Latte", price:125, description:"Smooth espresso and silky milk", icon:"☕", available:true },
    { id:5, cat:"Coffee", name:"Caramel Macchiato", price:165, description:"Vanilla, milk, caramel drizzle", icon:"🍮", available:true },
    { id:6, cat:"Coffee", name:"Cold Brew", price:140, description:"18-hour steeped, served iced", icon:"🧊", available:true },
    { id:7, cat:"Coffee", name:"Mocha Latte", price:155, description:"Espresso, chocolate and steamed milk", icon:"🍫", available:true },
    { id:8, cat:"Coffee", name:"White Mocha", price:160, description:"White chocolate and espresso", icon:"🤍", available:true },
    { id:9, cat:"Coffee", name:"Salted Caramel Latte", price:170, description:"Caramel, milk and a pinch of sea salt", icon:"🧂", available:true },
    { id:10, cat:"Coffee", name:"Vanilla Cold Brew", price:150, description:"Cold brew, vanilla, splash of milk", icon:"🍦", available:true },
    { id:11, cat:"Coffee", name:"Espresso", price:95, description:"Double shot, straight up", icon:"⚡", available:true },
    { id:12, cat:"Coffee", name:"Macchiato", price:120, description:"Espresso marked with milk foam", icon:"🥛", available:true },
  ];

  const state = {
    role: null,               // 'cashier' | 'admin'
    adminView: "dash",
    menu: [], orders: [], ingredients: [], recipes: {}, movements: [],
    cat: "Coffee", q: "",
    cart: [], sent: [],
    orderNo: null, localSeq: 0,
    orderType: "Dine in", method: "Cash",
    dbReady: false,
    qFilter: "all", qFilter2: "all", qType: "all",
    chartDays: 7,                            // dashboard chart range
    saleType: "all", salePay: "all",          // dashboard sales-summary filters
    repSaleType: "all", repSalePay: "all",    // reports sales-summary filters
    menuQ: "", menuCat: "all", menuOnly: "all",
    stockQ: "", stockLow: false,
    repMonth: new Date(), repDate: null,
    editingItemId: null, editingIngId: null, recipeProductId: null,
    lastLoad: 0,
  };

  const $ = s => document.querySelector(s);
  const $$ = s => [...document.querySelectorAll(s)];
  const peso = v => "\u20B1" + Number(v || 0).toFixed(2);
  const esc = s => String(s ?? "").replace(/[&<>"']/g, c =>
    ({ "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;" }[c]));
  const todayKey = () => {
    const d = new Date();
    return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,"0")}-${String(d.getDate()).padStart(2,"0")}`;
  };

  const subtotal = () => state.cart.reduce((s,i)=>s+i.price*i.qty, 0);
  const service  = () => Math.round(subtotal()*SERVICE_RATE*100)/100;
  const grand    = () => Math.round((subtotal()+service())*100)/100;
  const count    = () => state.cart.reduce((s,i)=>s+i.qty, 0);

  let toastT;
  function toast(msg) {
    const t = $("#toast");
    t.firstElementChild.textContent = msg;
    t.classList.remove("hidden");
    clearTimeout(toastT);
    toastT = setTimeout(()=>t.classList.add("hidden"), 2600);
  }

  function setDbStatus(ok, msg) {
    state.dbReady = ok;
    const pill = $("#dbPill");
    pill.querySelector("span").className = "w-1.5 h-1.5 rounded-full " + (ok ? "bg-accent" : "bg-red-400");
    $("#dbText").textContent = msg;
    pill.className = ok
      ? "hidden sm:inline-flex items-center gap-1.5 h-7 px-2.5 rounded-full bg-accent/10 border border-accent/40 text-[11px] font-semibold text-accent"
      : "hidden sm:inline-flex items-center gap-1.5 h-7 px-2.5 rounded-full bg-red-400/10 border border-red-400/40 text-[11px] font-semibold text-red-300";
    pill.title = msg;
  }

  /* ============================================================
     API
     ============================================================ */
  async function callApi(action, body = null) {
    const res = await fetch("api.php?action=" + encodeURIComponent(action), {
      method: body == null ? "GET" : "POST",
      headers: body == null ? {} : { "Content-Type": "application/json" },
      body: body == null ? undefined : JSON.stringify(body),
      cache: "no-store",
    });
    let data;
    try { data = await res.json(); }
    catch { throw new Error("Invalid PHP response — start Apache & check api.php"); }
    if (!res.ok) throw new Error(data.error || "Request failed");
    return data;
  }

  const normMenu = rows => rows.map(r => ({
    id: Number(r.id), cat: r.category || "Coffee", name: r.name, price: Number(r.price),
    description: r.description || "", icon: r.icon || "☕",
    available: r.available === undefined ? true : (!!r.available && r.available !== "0"),
  }));

  /* Order number label — shows a dash until the database tells us the next number */
  /* Order type: stored value is "Takeaway" (same as earlier builds), shown as "Take out" */
  function typeLabel(v) { return normType(v) === "Takeaway" ? "Take out" : (v || "Dine in"); }
  function normType(v) {
    const k = String(v || "").toLowerCase().replace(/[\s_-]/g, "");
    return (k === "takeaway" || k === "takeout") ? "Takeaway" : (v || "");
  }

  function orderNoText() { return state.orderNo ? String(state.orderNo) : "\u2014"; }
  function paintOrderNo() {
    const t = orderNoText();
    const a = $("#orderNo"), b = $("#orderNoM");
    if (a) a.textContent = t;
    if (b) b.textContent = t;
  }

  async function loadFromDb(silent = false) {
    const d = await callApi("load");
    state.menu = normMenu(d.menu || []);
    state.orders = d.orders || [];
    state.ingredients = d.ingredients || [];
    state.recipes = d.recipes || {};
    state.movements = d.movements || [];
    if (state.orders.length) {
      const nums = state.orders.map(o=>parseInt(o.number,10)).filter(n=>!isNaN(n));
      if (nums.length) { state.orderNo = Math.max(...nums)+1; state.localSeq = state.orderNo; }
    } else { state.orderNo = null; state.localSeq = 0; }
    paintOrderNo();
    state.lastLoad = Date.now();
    setDbStatus(true, "Database connected");
    state.cart = state.cart.filter(l => state.menu.some(m=>m.id===l.id && m.available));
    renderAll(); renderQueue(); renderAdmin();
    if (!silent) updateLiveLabel();
  }

  function loadFallback(reason) {
    state.menu = FALLBACK_MENU.map(x=>({...x}));
    state.orders = []; state.ingredients = []; state.recipes = {}; state.movements = [];
    setDbStatus(false, "Database disconnected");
    renderAll(); renderQueue(); renderAdmin();
    if (reason) toast(reason);
  }

  async function init() {
    try { await loadFromDb(); }
    catch (e) { loadFallback(e.message || "Could not reach api.php"); }
  }

  /* ============================================================
     AUTH — login (admin user/pass · cashier name/code)
     ============================================================ */
  function enterApp(role, name) {
    state.role = role;
    state.name = name || (role === "admin" ? "Admin" : "Cashier");
    localStorage.setItem("bbRole", role);
    $("#loginScreen").classList.add("hidden");
    $("#app").classList.remove("hidden");
    $("#roleChip").textContent = state.name;
    const repBtn = document.querySelector('#nav [data-nav="reports"]');
    if (repBtn) repBtn.style.display = role === "admin" ? "" : "none";
    if (role === "cashier") {
      showPos();
    } else {
      showAdmin("dash");
    }
    renderAll();
  }

  async function signOut() {
    try { await callApi("logout"); } catch (e) { /* offline ok */ }
    state.role = null; state.cart = []; state.orders = []; state.sent = [];
    $("#adminPass").value = ""; $("#cashCode").value = "";
    $("#app").classList.add("hidden");
    $("#loginScreen").classList.remove("hidden");
    setLoginErr();
    $("#tabAdmin").click();
  }

  function showLoginTab(which) {
    const admin = which === "admin";
    $("#adminForm").classList.toggle("hidden", !admin);
    $("#cashierForm").classList.toggle("hidden", admin);
    $("#tabAdmin").className = "flex-1 h-10 rounded-lg text-sm font-bold " + (admin ? "bg-accent text-ink" : "text-muted");
    $("#tabCashier").className = "flex-1 h-10 rounded-lg text-sm font-bold " + (admin ? "text-muted" : "bg-amber text-ink");
    $("#loginHint").textContent = admin
      ? "First run: admin / admin123 — change the password after import."
      : "First run: cashier code 1234 — change it after import.";
    setLoginErr();
  }
  function setLoginErr(msg = "") {
    const el = $("#loginError");
    el.textContent = msg;
    el.classList.toggle("hidden", !msg);
  }
  $("#tabAdmin").addEventListener("click", () => showLoginTab("admin"));
  $("#tabCashier").addEventListener("click", () => showLoginTab("cashier"));

  $("#adminForm").addEventListener("submit", async e => {
    e.preventDefault();
    setLoginErr();
    const username = $("#adminUser").value.trim(), password = $("#adminPass").value;
    if (!username || !password) return setLoginErr("Enter username and password.");
    try {
      const r = await callApi("login", { mode: "admin", username, password });
      enterApp(r.role || "admin", r.name);
      init();
    } catch (err) {
      if (err instanceof TypeError) { // network — offline demo fallback
        if (username === "admin" && password === "admin123") { enterApp("admin", "Admin"); loadFallback("Offline mode"); }
        else setLoginErr("Cannot reach api.php — start Apache & open the app via http://localhost/pos/ (demo: admin / admin123)");
      } else {
        setLoginErr(err.message);
        toast(err.message);
      }
    }
  });

  $("#cashierForm").addEventListener("submit", async e => {
    e.preventDefault();
    setLoginErr();
    const name = $("#cashName").value.trim(), code = $("#cashCode").value;
    if (!name || !code) return setLoginErr("Enter your name and access code.");
    try {
      const r = await callApi("login", { mode: "cashier", name, code });
      enterApp(r.role || "cashier", r.name || name);
      init();
    } catch (err) {
      if (err instanceof TypeError) { // network — offline demo fallback
        if (code === "1234") { enterApp("cashier", name); loadFallback("Offline mode"); }
        else setLoginErr("Cannot reach api.php — start Apache & open the app via http://localhost/pos/ (demo code: 1234)");
      } else {
        setLoginErr(err.message);
        toast(err.message);
      }
    }
  });

  function showPos() {
    $("#posShell").classList.remove("hidden");
    $("#posShell").classList.add("flex");
    $("#adminShell").classList.add("hidden");
    $("#mobBar").classList.remove("hidden");
  }

  function showAdmin(view) {
    $("#adminShell").classList.remove("hidden");
    $("#posShell").classList.add("hidden");
    $("#posShell").classList.remove("flex");
    $("#mobBar").classList.add("hidden");
    setAdminView(view || state.adminView);
  }

  function setAdminView(view) {
    state.adminView = view;
    if ($("#adminShell").classList.contains("hidden")) showAdmin(view);
    $$(".aview").forEach(b => {
      const on = b.dataset.view === view;
      b.className = "aview w-full flex items-center gap-2.5 px-3 h-10 rounded-lg text-sm font-bold " +
        (on ? "bg-accent text-ink" : "text-muted hover:bg-panel2 hover:text-white");
    });
    $$(".aview-block").forEach(s => s.classList.add("hidden"));
    const sec = $("#view-" + view);
    if (sec) sec.classList.remove("hidden");
    const titles = { dash:"Dashboard", reports:"Reports", orders:"Orders", menu:"Menu", stock:"Ingredients", costing:"Costing" };
    $("#adminMobileTitle").textContent = titles[view] || "Dashboard";
    // close mobile nav (keep base `hidden md:flex` intact for desktop)
    $("#adminSide").classList.remove("fixed","inset-y-0","left-0","z-50","w-60","flex");
    $("#adminSide").classList.add("hidden");
    $("#adminOverlay").classList.add("hidden");
    if (view === "dash" || view === "stock" || view === "costing") renderAdmin();
    if (view === "reports") renderReports();
  }

  $("#switchRoleBtn") && $("#switchRoleBtn").addEventListener("click", signOut);
  $("#posLogout").addEventListener("click", signOut);
  $("#mLogoutBtn").addEventListener("click", signOut);
  $$(".close-modal").forEach(b => b.addEventListener("click", () => {
    const m = b.closest(".modal-backdrop, [id$=Modal]");
    if (m) { m.classList.remove("flex"); m.classList.add("hidden"); }
  }));
  ["payModal","itemModal","ingModal","recipeModal"].forEach(id => {
    const el = document.getElementById(id);
    el.addEventListener("click", e => { if (e.target === el) { el.classList.replace("flex","hidden"); } });
  });

  $("#adminMenuBtn").addEventListener("click", () => {
    $("#adminSide").classList.remove("hidden");
    $("#adminSide").classList.add("flex", "fixed", "inset-y-0", "left-0", "z-50", "w-60");
    $("#adminOverlay").classList.remove("hidden");
  });
  $("#adminOverlay").addEventListener("click", () => {
    $("#adminSide").classList.remove("fixed","inset-y-0","left-0","z-50","w-60","flex");
    $("#adminSide").classList.add("hidden");
    $("#adminOverlay").classList.add("hidden");
  });
  $$(".aview").forEach(b => b.addEventListener("click", () => setAdminView(b.dataset.view)));

  /* ============================================================
     POS — sidebar nav
     ============================================================ */
  const NAV = [
    ['<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/>', "Counter", "counter"],
    ['<rect x="5" y="3" width="14" height="18" rx="2"/><path d="M9 8h6M9 12h6M9 16h4"/>', "Orders", "orders"],
    ['<path d="M4 20V10M10 20V4M16 20v-7M22 20H2"/>', "Reports", "reports"],
  ];
  $("#nav").innerHTML = NAV.map(([d,t,key],i)=>`
    <button class="w-9 h-9 grid place-items-center rounded-full nav-btn ${i===0?"bg-accent text-ink":"text-muted hover:bg-panel2 hover:text-white"}" data-nav="${key}" title="${t}">
      <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${d}</svg>
    </button>`).join("");

  document.addEventListener("click", e => {
    const nav = e.target.closest(".nav-btn");
    if (!nav) return;
    if (nav.dataset.nav === "orders") openQueue();
    else if (nav.dataset.nav === "counter") showPos();
    else if (nav.dataset.nav === "reports") {
      if (state.role === "admin") showAdmin("reports");
      else toast("Reports — Admin only");
    }
  });

  /* ============================================================
     POS — categories & grid
     ============================================================ */
  function activeCategories() {
    const seen = ["All"];
    for (const m of state.menu) if (!seen.includes(m.cat)) seen.push(m.cat);
    const order = Object.keys(CAT_STYLE);
    seen.sort((a,b)=>{
      const ia=order.indexOf(a), ib=order.indexOf(b);
      return (ia===-1?99:ia)-(ib===-1?99:ib);
    });
    if (seen[0] !== "All") seen.unshift("All");
    return seen;
  }
  const styleFor = c => CAT_STYLE[c] || { ...DEFAULT_CAT, label:c };

  function renderCats() {
    const cats = activeCategories();
    if (!cats.includes(state.cat)) state.cat = cats[0];
    $("#cats").innerHTML = cats.map(id => {
      const c = styleFor(id), on = state.cat === id;
      return `<button data-cat="${esc(id)}" class="cat-pill shrink-0 h-9 px-4 rounded-lg text-sm font-semibold transition ${on?"ring-2 ring-white/40":"hover:brightness-110"}"
        style="background:${c.color};color:${c.text}">${esc(c.label)}</button>`;
    }).join("");
    $("#catsM").innerHTML = cats.map(id => {
      const on = state.cat === id;
      return `<button data-cat="${esc(id)}" class="cat-pill shrink-0 h-8 px-3 rounded-full text-xs font-semibold border whitespace-nowrap ${on?"border-accent text-accent bg-accent/10":"border-line text-muted bg-panel2"}">${esc(styleFor(id).label)}</button>`;
    }).join("");
  }

  const qtyOf = id => (state.cart.find(x=>x.id===id)||{}).qty || 0;

  // A product is unavailable when its recipe is missing, any ingredient is
  // at/below reorder level, or there is not enough stock for the order.
  function stockProblem(cart) {
    if (!state.dbReady) return "Database unavailable — stock cannot be checked.";
    const needs = new Map();
    for (const line of cart) {
      const item = state.menu.find(m => m.id === line.id);
      if (!item || !item.available) return (item ? item.name : "Product") + " is unavailable.";
      const recipe = state.recipes[line.id] || [];
      if (!recipe.length) return item.name + " has no recipe. Ask admin to set it up.";
      for (const r of recipe) {
        const g = state.ingredients.find(x => Number(x.id) === Number(r.ingredientId));
        if (!g || !Number.isFinite(Number(r.quantity)) || Number(r.quantity) <= 0)
          return item.name + " has an invalid recipe. Ask admin to check it.";
        if (Number(g.stock) <= Number(g.reorder_level)) return item.name + " unavailable — restock " + g.name + ".";
        const key = Number(g.id), old = needs.get(key) || { g, amount: 0 };
        old.amount += Number(r.quantity) * line.qty;
        needs.set(key, old);
      }
    }
    for (const {g, amount} of needs.values())
      if (amount > Number(g.stock) + 0.000001) return "Not enough " + g.name + " for this order. Please restock or reduce quantity.";
    return "";
  }

  function renderGrid() {
    const q = state.q.trim().toLowerCase();
    const list = q
      ? state.menu.filter(i => i.name.toLowerCase().includes(q) || (i.description||"").toLowerCase().includes(q))
      : state.menu.filter(i => state.cat === "All" || i.cat === state.cat);
    $("#emptyMenu").classList.toggle("hidden", list.length > 0);
    $("#grid").innerHTML = list.map(i => {
      const n = qtyOf(i.id), problem = stockProblem([{id:i.id, qty:1}]), off = !!problem;
      return `
      <button data-add="${i.id}" ${off?"disabled":""}
        class="card-press relative text-left rounded-xl p-3 min-h-[80px] flex flex-col justify-between transition
               ${off?"bg-card/40 text-ink/50 cursor-not-allowed":"bg-card hover:bg-card2 text-ink"}">
        ${n?`<span class="absolute top-1.5 right-1.5 min-w-5 h-5 px-1 rounded-md bg-amber text-ink text-[11px] font-bold grid place-items-center">${n}</span>`:""}
        <span class="text-[13px] font-semibold leading-snug pr-4"><span class="mr-1">${esc(i.icon)}</span>${esc(i.name)}</span>
        ${i.description?`<span class="text-[10px] leading-tight text-ink/55 line-clamp-1 mt-0.5">${esc(i.description)}</span>`:""}
        <span class="text-[13px] font-medium text-ink/70 mt-1 flex items-center justify-between">
          <span>${peso(i.price)}</span>
          ${off?`<span class="text-[10px] font-bold text-red-700/80">${i.available ? "Unavailable · check stock/recipe" : "Unavailable"}</span>`:""}
        </span>
      </button>`;
    }).join("");
  }

  /* ============================================================
     POS — cart
     ============================================================ */
  function groupCart() {
    const order = activeCategories().filter(c=>c!=="All");
    const map = new Map();
    for (const it of state.cart) {
      if (!map.has(it.cat)) map.set(it.cat, []);
      map.get(it.cat).push(it);
    }
    return order.filter(c=>map.has(c)).map(c=>({ cat:c, label:styleFor(c).label, items:map.get(c) }));
  }

  const cartRowHTML = it => `
    <div class="flex items-start gap-2 py-2 border-b border-line/60 pop">
      <div class="flex-1 min-w-0">
        <p class="text-sm font-semibold leading-snug">${it.qty} x ${esc(it.name)}</p>
        ${it.description?`<p class="text-[11px] text-muted mt-0.5 truncate">${esc(it.description)}</p>`:""}
      </div>
      <span class="text-sm text-muted tabular-nums shrink-0">${peso(it.price*it.qty)}</span>
      <div class="flex items-center gap-0.5 shrink-0">
        <button data-dec="${it.id}" class="w-6 h-6 grid place-items-center rounded hover:bg-panel2 text-muted hover:text-white text-xs">−</button>
        <span class="text-xs font-bold w-5 text-center tabular-nums">${it.qty}</span>
        <button data-inc="${it.id}" class="w-6 h-6 grid place-items-center rounded hover:bg-panel2 text-muted hover:text-white text-xs">+</button>
      </div>
    </div>`;

  function orderCardHTML(o) {
    const st = { pending:"bg-amber/15 text-amber border-amber/40", ready:"bg-accent/15 text-accent border-accent/40",
      paid:"bg-green-500/15 text-green-400 border-green-500/40", cancelled:"bg-red-500/15 text-red-400 border-red-500/40" }[o.status] || "";
    return `
    <article class="rounded-xl bg-panel2 border border-line p-3.5">
      <div class="flex items-start justify-between gap-2">
        <div><span class="font-bold">${esc(o.number)}</span>
        <span class="text-xs text-muted ml-2">${esc(typeLabel(o.type))} · ${esc(o.time||"")}${o.payment ? " · " + esc(o.payment) : ""}</span></div>
        <span class="text-[10px] font-bold uppercase px-2 py-0.5 rounded-full border ${st}">${esc(o.status)}</span>
      </div>
      <ul class="mt-2 space-y-0.5 text-sm text-muted">
        ${(o.items||[]).map(i=>`<li>${i.qty} × ${esc(i.name)}</li>`).join("") || "<li>No items</li>"}
      </ul>
      <div class="flex items-center justify-between mt-3 pt-2.5 border-t border-line">
        <strong class="text-accent">${peso(o.total)}</strong>
        <div class="flex gap-2">
          ${o.status==="pending"?`<button data-ready="${o.id}" class="h-8 px-3 rounded-lg bg-panel border border-line text-xs font-bold text-white hover:border-accent/50">Mark ready</button>`:""}
          ${o.status==="ready"?`<button data-paid="${o.id}" class="h-8 px-3 rounded-lg bg-accent text-ink text-xs font-bold">Complete</button>`:""}
          ${o.payment?`<button data-receipt="${o.id}" class="h-8 px-3 rounded-lg bg-panel2 border border-line text-xs font-bold text-muted hover:text-white hover:border-accent/50">Receipt</button>`:""}
          ${o.status==="paid"?`<span class="text-xs text-muted">Order complete</span>`:""}
        </div>
      </div>
    </article>`;
  }

  function bindOrderButtons(root) {
    root.querySelectorAll("[data-receipt]").forEach(b => b.onclick = () => {
      const o = state.orders.find(x => x.id === Number(b.dataset.receipt));
      if (!o) return;
      showReceipt({
        number: o.number, type: o.type, method: o.payment, ref: o.payment_ref || null,
        refLabel: o.payment === "GCash" ? "GCash ref" : "Card ref",
        items: o.items || [], total: o.total, subtotal: o.subtotal, received: o.received,
        cashier: null, at: [o.date || o.day || "", o.time || ""].filter(Boolean).join(" "),
      });
    });
    root.querySelectorAll("[data-ready]").forEach(b => b.onclick = () => setOrderStatus(Number(b.dataset.ready), "ready"));
    root.querySelectorAll("[data-paid]").forEach(b => b.onclick = () => setOrderStatus(Number(b.dataset.paid), "paid"));
  }

  function renderOrder() {
    const groups = groupCart();
    const html = groups.length
      ? groups.map(g=>`
        <div class="mb-3">
          <div class="flex items-center justify-between py-1.5">
            <span class="text-sm font-bold">${esc(g.label)}</span>
            <div class="flex items-center gap-1 text-muted">
              <button data-delcat="${esc(g.cat)}" class="w-7 h-7 grid place-items-center rounded hover:bg-panel2 hover:text-red-400" title="Clear">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 7h16M9 7V4h6v3M7 7l1 14h8l1-14"/></svg></button>
            </div>
          </div>
          ${g.items.map(cartRowHTML).join("")}
        </div>`).join("")
      : `<p class="text-center text-muted text-sm py-10">Your order is empty.<br>Choose an item from the menu.</p>`;

    $("#orderList").innerHTML = html;
    $("#orderListM").innerHTML = html;

    const sub=subtotal(), svc=service(), tot=grand(), n=count();
    $("#subDesk").textContent = peso(sub); $("#svcDesk").textContent = peso(svc); $("#totalDesk").textContent = peso(tot);
    $("#subMob").textContent = peso(sub);  $("#svcMob").textContent = peso(svc);  $("#totalMob").textContent = peso(tot);
    $("#sendFabN").textContent = n;
    $("#typeLabelM").textContent = typeLabel(state.orderType);

    ["#payDesk","#sendDesk","#payMob","#sendMob","#payFab","#sendFab","#sendDirect"].forEach(id => { $(id).disabled = n===0; });
    $("#mCartDot").classList.toggle("hidden", n===0);
    $("#mCartDot").textContent = n;

    $("#sentCount").textContent = state.sent.length;
    $("#sentList").innerHTML = state.sent.length
      ? state.sent.map(s=>`<div class="px-2 py-1 rounded bg-panel2 text-xs">${esc(s)}</div>`).join("")
      : `<div class="px-2 py-1 text-xs text-muted/70">Nothing sent yet</div>`;

    const openN = state.orders.filter(o=>o.status==="pending"||o.status==="ready").length;
    $("#queueDot").classList.toggle("hidden", openN===0);
    $("#queueDot").textContent = openN;
  }

  function renderAll(){ renderCats(); renderGrid(); renderOrder(); }

  function add(id) {
    const item = state.menu.find(i=>i.id===id);
    if (!item) return;
    if (!item.available) return toast(item.name + " is unavailable.");
    const proposed = state.cart.map(x=>({...x}));
    const existing = proposed.find(x=>x.id===id);
    if (existing) existing.qty++; else proposed.push({id, qty:1});
    const problem = stockProblem(proposed); if (problem) return toast(problem);
    const ex = state.cart.find(i=>i.id===id);
    if (ex) ex.qty++;
    else state.cart.push({ id:item.id, name:item.name, price:item.price, qty:1, cat:item.cat, description:item.description, icon:item.icon });
    renderGrid(); renderOrder();
  }
  function bump(id, d) {
    const it = state.cart.find(i=>i.id===id);
    if (!it) return;
    if (d > 0) { const proposed = state.cart.map(x=>({...x, qty:x.id===id ? x.qty+d : x.qty})); const problem = stockProblem(proposed); if (problem) return toast(problem); }
    it.qty += d;
    if (it.qty<=0) state.cart = state.cart.filter(i=>i.id!==id);
    renderGrid(); renderOrder();
  }
  function clearCat(cat){ state.cart = state.cart.filter(i=>i.cat!==cat); renderGrid(); renderOrder(); toast("Category cleared"); }
  /* Real POS flow: nothing goes to the kitchen before payment —
     every Send button proceeds to checkout; the ticket is created after payment succeeds. */
  function sendAll() {
    if (!state.cart.length) return;
    openPay();
  }

  /* ---------- POS events ---------- */
  document.addEventListener("click", e => {
    const cat = e.target.closest(".cat-pill");
    if (cat) { state.cat = cat.dataset.cat; state.q=""; $("#search").value=""; $("#searchM").value=""; renderCats(); renderGrid(); return; }
    const addBtn = e.target.closest("[data-add]");
    if (addBtn && !addBtn.disabled) { add(+addBtn.dataset.add); return; }
    const inc = e.target.closest("[data-inc]"); if (inc) { bump(+inc.dataset.inc, 1); return; }
    const dec = e.target.closest("[data-dec]"); if (dec) { bump(+dec.dataset.dec, -1); return; }
    const delc = e.target.closest("[data-delcat]"); if (delc) { clearCat(delc.dataset.delcat); return; }
  });

  function onSearch(v){ state.q=v; $("#search").value=v; $("#searchM").value=v; renderGrid(); }
  $("#search").addEventListener("input", e=>onSearch(e.target.value));
  $("#searchM").addEventListener("input", e=>onSearch(e.target.value));
  $("#mSearchBtn").addEventListener("click", ()=>{ const w=$("#mSearchWrap"); w.classList.toggle("hidden"); if(!w.classList.contains("hidden")) $("#searchM").focus(); });
  $("#sentToggle").addEventListener("click", ()=>{ $("#sentList").classList.toggle("hidden"); $("#sentChev").classList.toggle("rotate-180"); });
  $("#sendDirect").addEventListener("click", sendAll);
  $("#sendDesk").addEventListener("click", sendAll);
  $("#sendMob").addEventListener("click", sendAll);
  $("#sendFab").addEventListener("click", sendAll);
  $("#clearDesk").addEventListener("click", ()=>{ if(!state.cart.length) return toast("Order is already empty"); state.cart=[]; renderGrid(); renderOrder(); toast("Order cleared"); });
  // Dine in / Take out — works from desktop order panel AND mobile drawer
  document.addEventListener("click", e=>{
    const b = e.target.closest(".type-btn"); if (!b) return;
    state.orderType = b.dataset.type;
    $$(".type-btn").forEach(x => {
      const on = x.dataset.type === state.orderType;
      x.classList.toggle("bg-accent", on);
      x.classList.toggle("text-ink", on);
      x.classList.toggle("text-muted", !on);
    });
    $("#typeLabelM").textContent = typeLabel(state.orderType);
    if (!$("#payModal").classList.contains("hidden")) {
      $("#payInfo").textContent = `Order ${orderNoText()} · ${typeLabel(state.orderType)} · includes 5% service charge`;
    }
  });

  const openMob = ()=>{ $("#orderMob").classList.remove("translate-x-full"); $("#overlay").classList.remove("hidden"); };
  const closeMob = ()=>{ $("#orderMob").classList.add("translate-x-full"); $("#overlay").classList.add("hidden"); };
  $("#mCartBtn").addEventListener("click", openMob);
  $("#basketBtn").addEventListener("click", openMob);
  $("#closeMob").addEventListener("click", closeMob);
  $("#overlay").addEventListener("click", closeMob);

  const openQueue = ()=>{ $("#queuePanel").classList.remove("translate-x-full"); $("#queueOverlay").classList.remove("hidden"); renderQueue(); };
  const closeQueue = ()=>{ $("#queuePanel").classList.add("translate-x-full"); $("#queueOverlay").classList.add("hidden"); };
  $("#ordersBtn").addEventListener("click", openQueue);
  $("#closeQueue").addEventListener("click", closeQueue);
  $("#queueOverlay").addEventListener("click", closeQueue);

  function bindQFilter(sel, cls, key) {
    $(sel).addEventListener("click", e => {
      const b = e.target.closest(cls); if (!b) return;
      state[key] = b.dataset.f;
      $$(sel + " " + cls).forEach(x => {
        const on = x.dataset.f === state[key];
        x.className = cls.slice(1) + " text-xs font-bold border " +
          (on ? "border-accent text-accent bg-accent/10" : "border-line text-muted bg-panel2") +
          (sel==="#qFilters" ? " h-8 px-3.5 rounded-full" : " h-7 px-3 rounded-full");
      });
      renderQueue();
      renderAdminOrders();
    });
  }
  bindQFilter("#qFilters", ".qf", "qFilter");
  bindQFilter("#qFilters2", ".qf2", "qFilter2");

  $("#typeFilters").addEventListener("click", e => {
    const b = e.target.closest(".tf"); if (!b) return;
    state.qType = b.dataset.t;
    $$("#typeFilters .tf").forEach(x => {
      const on = x.dataset.t === state.qType;
      x.className = "tf h-8 px-3.5 rounded-full text-xs font-bold border " +
        (on ? "border-accent text-accent bg-accent/10" : "border-line text-muted bg-panel2");
    });
    renderAdminOrders();
  });

  function renderQueue() {
    const list = state.orders.filter(o => state.qFilter2==="all" || o.status===state.qFilter2);
    $("#queueList").innerHTML = list.length ? list.map(orderCardHTML).join("")
      : `<p class="text-center text-muted text-sm py-10">No orders match this filter.</p>`;
    bindOrderButtons($("#queueList"));
    renderOrder();
  }

  async function setOrderStatus(id, status) {
    try {
      if (state.dbReady) { await callApi("order_status", { id, status }); await loadFromDb(true); }
      else { const o = state.orders.find(x=>x.id===id); if (o) o.status=status; renderQueue(); renderAdmin(); }
      toast(status==="ready" ? "Order marked ready." : "Order completed.");
    } catch (e) { toast(e.message); }
  }

  /* ============================================================
     CHECKOUT
     ============================================================ */
  function openPay() {
    const problem = stockProblem(state.cart); if (problem) { toast(problem); return; }
    if (!state.cart.length) return;
    $("#payAmt").textContent = peso(grand());
    $("#payInfo").textContent = `Order ${orderNoText()} · ${typeLabel(state.orderType)} · includes 5% service charge`;
    $("#amountReceived").value = "";
    $("#scanRef").value = "";
    updatePayPanel();
    $("#changeLine").classList.add("hidden");
    $("#payModal").classList.replace("hidden","flex");
    setTimeout(()=>$("#amountReceived").focus(), 60);
  }
  $("#payDesk").addEventListener("click", openPay);
  $("#payMob").addEventListener("click", openPay);
  $("#payFab").addEventListener("click", openPay);
  $("#payCancel").addEventListener("click", ()=>$("#payModal").classList.replace("flex","hidden"));
  $("#methods").addEventListener("click", e=>{
    const b = e.target.closest(".pm"); if (!b) return;
    $$(".pm").forEach(x=>{ x.className="pm h-11 rounded-lg border border-line bg-panel2 text-muted text-xs font-bold"; });
    b.className="pm h-11 rounded-lg border border-accent bg-accent/10 text-accent text-xs font-bold";
    state.method = b.dataset.m;
    updatePayPanel();
  });

  /* ---------- scan-to-pay panel: GCash or Card ---------- */
  function payPanelCfg() {
    const gcashSub = SHOP.gcash ? `Send to <strong class="text-white tabular-nums">${esc(SHOP.gcash)}</strong>` : "GCash number not configured";
    return {
      GCash: {
        title: "Pay via GCash",
        sub: gcashSub,
        hint: "Customer scans the GCash QR, then the cashier confirms",
        qr: "gcash-qr.png",
        refLabel: "GCash reference no. (optional)",
        ph: "e.g. 1234 5678 9012",
        refShort: "GCash ref",
      },
      Card: {
        title: "Card \u2014 scan to pay",
        sub: "QR Ph \u00b7 bank / card app",
        hint: "Customer scans the QR with their banking app, then the cashier confirms",
        qr: "card-qr.png",
        refLabel: "Approval / scan reference (optional)",
        ph: "e.g. 002341",
        refShort: "Card ref",
      },
    };
  }
  function loadScanQr(src) {
    const img = $("#scanQr"), wrap = $("#scanQrWrap"), hint = $("#scanQrHint");
    if (!img || !wrap) return;
    const show = () => { wrap.classList.remove("hidden"); hint.classList.add("hidden"); hint.classList.remove("grid"); };
    const miss = () => { wrap.classList.add("hidden"); hint.classList.remove("hidden"); hint.classList.add("grid"); };
    img.onload = show;
    img.onerror = miss;
    img.src = src;
    if (img.complete) (img.naturalWidth ? show : miss)();
  }
  function updatePayPanel() {
    const cfg = payPanelCfg()[state.method];
    const cash = state.method === "Cash";
    $("#cashReceivedWrap").classList.toggle("hidden", !cash);
    if (!cash) $("#changeLine").classList.add("hidden");
    const box = $("#scanBox");
    if (!cfg) { box.classList.add("hidden"); return; }
    box.classList.remove("hidden");
    $("#scanTitle").textContent = cfg.title;
    $("#scanSub").innerHTML = cfg.sub;
    $("#scanHint").textContent = cfg.hint;
    $("#scanRefLabel").textContent = cfg.refLabel;
    $("#scanRef").placeholder = cfg.ph;
    loadScanQr(cfg.qr);
  }
  $("#amountReceived").addEventListener("input", e=>{
    const got = Number(e.target.value), line = $("#changeLine");
    if (!e.target.value || isNaN(got) || got < grand()) { line.classList.add("hidden"); return; }
    line.textContent = "Change: " + peso(got - grand());
    line.classList.remove("hidden");
  });
  $("#payOk").addEventListener("click", async ()=>{
    if (!state.cart.length) return;
    const problem = stockProblem(state.cart); if (problem) { toast(problem); return; }
    const rawReceived = $("#amountReceived").value;
    const received = state.method === "Cash" && rawReceived !== "" ? Number(rawReceived) : null;
    if (state.method === "Cash" && (received === null || !Number.isFinite(received) || received < grand())) {
      toast("Enter cash received equal to or greater than the total.");
      $("#amountReceived").focus();
      return;
    }
    const btn = $("#payOk"); btn.disabled = true;
    const items = state.cart.map(l=>({ id:l.id, qty:l.qty }));
    const cartSnap = state.cart.map(x => ({ id:x.id, name:x.name, price:x.price, qty:x.qty }));
    const totalSnap = grand();
    const payRef = state.method === "Cash" ? null : (($("#scanRef").value || "").trim() || null);
    const refShort = (payPanelCfg()[state.method] || {}).refShort || "Ref";
    try {
      let number, receiptItems = cartSnap, receiptTotal = totalSnap, receiptSubtotal = subtotal(), receiptService = service();
      const isDemo = !state.dbReady;
      if (state.dbReady) {
        const res = await callApi("order_create", { type:state.orderType, payment:state.method, received, items, ref:payRef });
        number = res.number;
        receiptItems = Array.isArray(res.items) ? res.items : cartSnap;
        receiptTotal = res.total == null ? totalSnap : Number(res.total);
        receiptSubtotal = res.subtotal == null ? receiptSubtotal : Number(res.subtotal);
        receiptService = res.service == null ? receiptTotal - receiptSubtotal : Number(res.service);
        toast(`Payment recorded · ${res.number} · ${peso(res.total)} ${state.method}`);
      } else {
        state.localSeq += 1;
        number = String(state.localSeq).padStart(2,"0");
        toast(`DEMO ONLY · ${number} · order not saved`);
      }
      // paid → now it goes to the kitchen
      state.cart.forEach(i => state.sent.push(`${i.qty} x ${i.name}`));
      state.orderNo = parseInt(number,10) || (state.orderNo ? state.orderNo+1 : 1);
      state.cart = [];
      $("#payModal").classList.replace("flex","hidden");
      closeMob();
      paintOrderNo();
      renderGrid(); renderOrder();
      showReceipt({
        number, type: state.orderType, method: state.method, ref: payRef, refLabel: refShort,
        items: receiptItems, total: receiptTotal, subtotal: receiptSubtotal, service: receiptService, received, cashier: state.name, demo: isDemo,
        at: new Intl.DateTimeFormat("en-PH", { day:"2-digit", month:"short", year:"numeric",
              hour:"2-digit", minute:"2-digit" }).format(new Date()),
      });
      if (state.dbReady) loadFromDb(true).catch(()=>{});
    } catch (err) { toast(err.message); loadFromDb(true).catch(()=>{ setDbStatus(false, "Database disconnected"); renderAll(); }); }
    finally { btn.disabled = false; }
  });

  /* ============================================================
     RECEIPT — printable (58/72 mm style)
     ============================================================ */
  const peso2 = n => Number(n||0).toFixed(2);

  function receiptHTML(d) {
    const line = '<div class="receipt-rule"></div>';
    const row = (label, value, cls = "") => `<div class="receipt-row ${cls}"><span>${label}</span><span>${value}</span></div>`;
    const rows = (d.items || []).map(i => {
      const qty = Number(i.qty) || 0, price = Number(i.price) || 0;
      return `<div class="receipt-item"><div class="receipt-item-name">${esc(i.name)}</div>${row(`${qty} x ${peso2(price)}`, peso2(price * qty))}</div>`;
    }).join("") || '<div class="receipt-center">No items</div>';
    const total = Number(d.total || 0);
    const sub = d.subtotal != null ? Number(d.subtotal) : Math.round((total / (1 + SERVICE_RATE)) * 100) / 100;
    const svc = d.service != null ? Number(d.service) : Math.round((total - sub) * 100) / 100;
    const orderNo = String(d.number || "—").replace(/^#/, "");
    return `
      <header class="receipt-center">
        <div class="receipt-brand">${esc(SHOP.name.toUpperCase())}</div>
        <div>${esc(SHOP.place)}</div>
        <div class="receipt-caption">CUSTOMER COPY</div>
      </header>
      ${d.demo ? '<div class="receipt-demo">DEMO ONLY — NOT SAVED</div>' : ''}
      ${line}
      ${row('Order no.', `#${esc(orderNo)}`)}
      ${row('Order type', esc(typeLabel(d.type)))}
      ${row('Date', esc(d.at || '—'))}
      ${row('Cashier', esc(d.cashier || 'Not recorded'))}
      ${line}
      <div class="receipt-row receipt-label"><span>ITEM / QTY x PRICE</span><span>AMOUNT</span></div>
      ${rows}
      ${line}
      ${row('Subtotal', peso2(sub))}
      ${row('Service charge 5%', peso2(svc))}
      ${row('TOTAL', `PHP ${peso2(total)}`, 'receipt-total')}
      ${line}
      ${row('Payment method', esc(d.method || '—'))}
      ${d.ref ? row(esc(d.refLabel || 'Reference'), esc(d.ref)) : ''}
      ${d.method === 'Cash' && d.received != null ? row('Cash received', peso2(d.received)) + row('Change', peso2(Number(d.received) - total)) : ''}
      ${line}
      <div class="receipt-center receipt-thanks">Thank you for your visit!<br>Please come again.</div>
      <div class="receipt-center receipt-disclaimer">Customer copy · Not an official receipt or sales invoice</div>`;
  }

  function showReceipt(d) {
    $("#receiptPaper").innerHTML = receiptHTML(d);
    $("#receiptModal").classList.replace("hidden", "flex");
  }
  $("#receiptClose").addEventListener("click", () => $("#receiptModal").classList.replace("flex", "hidden"));
  $("#receiptWidth").addEventListener("change", e => {
    $("#receiptPaper").dataset.width = e.target.value;
  });
  $("#receiptPaper").dataset.width = $("#receiptWidth").value;
  $("#receiptPrint").addEventListener("click", () => window.print());

  /* ============================================================
     ADMIN — costing helpers
     ============================================================ */
  const ingById = id => state.ingredients.find(g=>g.id===id);
  const productCost = pid => (state.recipes[pid]||[]).reduce((s,l)=>{
    const g = ingById(l.ingredientId);
    return s + (g ? g.unit_cost * l.quantity : 0);
  }, 0);
  const orderCost = o => (o.items||[]).reduce((s,l)=>s + productCost(l.id)*l.qty, 0);

  /* ============================================================
     ADMIN — dashboard / orders / menu / stock / costing
     ============================================================ */
  function renderAdmin() {
    renderKPIs(); renderChart(); renderMargins(); renderSales();
    renderAdminOrders(); renderMenuTable(); renderStock(); renderCosting();
    if (!$("#view-reports").classList.contains("hidden")) renderReports();
    updateLiveLabel();
  }

  /* ============================================================
     REPORTS — profit calendar + per-day stats + sales summary
     ============================================================ */
  function renderReports() {
    const pad = n => String(n).padStart(2, "0");
    // revenue = orders where payment was received (paid at checkout, before kitchen handover)
    const paid = state.orders.filter(o => o.payment && o.status !== "cancelled");

    // group paid orders by day key
    const byDay = {};
    paid.forEach(o => {
      const k = o.day || o.date || (o.createdAt ? tsKeySafe(o.createdAt) : null);
      if (!k) return;
      (byDay[k] = byDay[k] || []).push(o);
    });

    const M = state.repMonth, y = M.getFullYear(), m = M.getMonth();
    $("#repMonth").textContent = M.toLocaleDateString("en-PH", { month: "long", year: "numeric" });
    $("#repWeekdays").innerHTML = ["S","M","T","W","T","F","S"]
      .map(d => `<div class="text-center text-[11px] font-bold text-muted py-1">${d}</div>`).join("");

    if (!state.repDate) state.repDate = todayKey();
    const today = todayKey();

    const firstDow = new Date(y, m, 1).getDay();
    const daysIn = new Date(y, m + 1, 0).getDate();
    let cells = "";
    for (let i = 0; i < firstDow; i++) cells += `<div></div>`;
    for (let d = 1; d <= daysIn; d++) {
      const key = `${y}-${pad(m + 1)}-${pad(d)}`;
      const list = byDay[key] || [];
      const rev = list.reduce((s, o) => s + o.total, 0);
      const cost = list.reduce((s, o) => s + orderCost(o), 0);
      const prof = rev - cost;
      const sel = key === state.repDate;
      const isToday = key === today;
      const dot = !list.length ? "" : prof >= 0 ? "text-accent" : "text-red-400";
      cells += `<button data-repday="${key}"
        class="repday relative min-h-[46px] rounded-lg border text-xs flex flex-col items-center justify-center leading-tight transition
        ${sel ? "border-accent bg-accent/15 ring-1 ring-accent" : "border-line/70 bg-panel2 hover:border-accent/50"}
        ${isToday && !sel ? "border-amber/60" : ""}">
        <span class="font-bold ${sel ? "text-white" : "text-white/80"}">${d}</span>
        ${list.length ? `<span class="text-[9px] font-bold ${dot}">${prof >= 0 ? "+" : "-"}${Math.abs(prof).toFixed(0)}</span>` : `<span class="text-[9px] text-muted/50">·</span>`}
      </button>`;
    }
    $("#repCalendar").innerHTML = cells;
    $("#repCalendar").querySelectorAll("[data-repday]").forEach(b => b.onclick = () => {
      state.repDate = b.dataset.repday;
      renderReports();
    });

    // ---- selected day stats ----
    const list = byDay[state.repDate] || [];
    const rev = list.reduce((s, o) => s + o.total, 0);
    const cost = list.reduce((s, o) => s + orderCost(o), 0);
    const profit = rev - cost;
    const margin = rev ? (profit / rev * 100) : 0;
    const pretty = new Date(state.repDate + "T00:00:00").toLocaleDateString("en-PH", { weekday: "short", month: "long", day: "numeric" });
    $("#repDayTitle").textContent = pretty;
    $("#reportSubtitle").textContent = `Viewing saved sales for ${pretty}`;

    const stat = (label, value, cls) => `
      <div class="rounded-xl bg-panel2 border border-line p-3">
        <div class="text-[11px] text-muted">${label}</div>
        <div class="text-lg font-bold tabular-nums ${cls || ""}">${value}</div>
      </div>`;
    $("#repStats").innerHTML =
      stat("Revenue", peso(rev)) +
      stat("Product cost", peso(cost), "text-amber") +
      stat("Profit", peso(profit), profit >= 0 ? "text-accent" : "text-red-400") +
      stat("Margin", margin.toFixed(1) + "%", profit >= 0 ? "text-accent" : "text-red-400");

    // order type breakdown
    const types = [["Dine in", "Dine in"], ["Takeaway", "Take out"]].map(([t, label]) => {
      const tl = list.filter(o => normType(o.type) === t);
      return { t, label, count: tl.length, rev: tl.reduce((s, o) => s + o.total, 0) };
    });
    const maxT = Math.max(1, ...types.map(x => x.rev));
    $("#repTypes").innerHTML = types.map(x => `
      <div class="flex items-center gap-3 text-xs">
        <span class="w-20 text-muted font-semibold">${x.label}</span>
        <div class="flex-1 h-4 rounded-md bg-line overflow-hidden">
          <div class="h-full rounded-md ${x.t === "Dine in" ? "bg-accent" : "bg-amber"}" style="width:${x.rev / maxT * 100}%"></div>
        </div>
        <strong class="w-10 text-right tabular-nums">${x.count}</strong>
        <span class="w-16 text-right tabular-nums text-white/90">${peso(x.rev)}</span>
      </div>`).join("")
      + (list.length ? "" : `<p class="text-[11px] text-muted">No sales on this date.</p>`);

    // ---- sales summary table ----
    const slist = list.filter(o =>
      (state.repSaleType === "all" || normType(o.type) === state.repSaleType) &&
      (state.repSalePay === "all" || (o.payment || "") === state.repSalePay));
    const sTot = slist.reduce((a,o)=>a+o.total,0), sCost = slist.reduce((a,o)=>a+orderCost(o),0);
    $("#repSalesLabel").textContent = `${slist.length} of ${list.length} payment(s) on ${pretty} · ${peso(sTot)} · profit ${peso(sTot-sCost)}`;
    $("#repSalesTable").innerHTML = slist.length ? slist.map(o => {
      const oc = orderCost(o), op = o.total - oc;
      return `<tr>
        <td class="py-2.5 font-bold">${esc(o.number)}</td>
        <td class="text-muted">${esc(o.time || "")}</td>
        <td class="text-muted">${esc(typeLabel(o.type))}</td>
        <td class="text-muted">${esc(o.payment || "—")}</td>
        <td class="text-right font-bold">${peso(o.total)}</td>
        <td class="text-right text-amber">${peso(oc)}</td>
        <td class="text-right font-bold ${op >= 0 ? "text-accent" : "text-red-400"}">${peso(op)}</td>
      </tr>`;
    }).join("") : `<tr><td colspan="7" class="text-center text-muted py-8 text-sm">${list.length ? "No payments match this filter." : "No completed sales on this date."}</td></tr>`;
  }

  function tsKeySafe(t) {
    const d = new Date(t);
    if (isNaN(d)) return null;
    return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,"0")}-${String(d.getDate()).padStart(2,"0")}`;
  }

  $("#repPrev").addEventListener("click", () => {
    state.repMonth = new Date(state.repMonth.getFullYear(), state.repMonth.getMonth() - 1, 1);
    renderReports();
  });
  $("#repNext").addEventListener("click", () => {
    state.repMonth = new Date(state.repMonth.getFullYear(), state.repMonth.getMonth() + 1, 1);
    renderReports();
  });

  function renderKPIs() {
    const today = new Date().toISOString().slice(0,10);
    const paid = state.orders.filter(o => o.payment && o.status !== "cancelled");
    const paidToday = paid.filter(o=>(o.day||o.date)===today);
    const sales = paidToday.reduce((s,o)=>s+o.total,0);
    const cost = paidToday.reduce((s,o)=>s+orderCost(o),0);
    const profit = sales - cost;
    const margin = sales ? (profit/sales*100) : 0;
    const low = state.ingredients.filter(g=>g.low).length;

    const cards = [
      ["Sales today", peso(sales), `${paidToday.length} paid order(s)`, "₱", "reports"],
      ["Gross profit", peso(profit), profit>=0?"Gaining before expenses":"Losing", "↗", "reports"],
      ["Profit margin", margin.toFixed(1)+"%", "on today's sales", "%", "costing"],
      ["Low stock", low+" item(s)", low?"Needs attention":"All good", "⚠", "stock"],
    ];
    $("#kpiGrid").innerHTML = cards.map(([l,v,s,ic,go])=>`
      <button data-goto="${go}" class="text-left rounded-2xl bg-panel border border-line p-4 relative hover:border-accent/50 hover:bg-panel2/40 transition">
        <span class="absolute right-3 top-3 text-lg opacity-60">${ic}</span>
        <div class="text-xs text-muted">${l}</div>
        <div class="text-xl md:text-2xl font-bold mt-1 tabular-nums">${v}</div>
        <div class="text-[11px] font-bold mt-1 ${l==="Low stock"&&low?"text-amber":"text-accent"}">${s}</div>
      </button>`).join("");
    $("#kpiGrid").querySelectorAll("[data-goto]").forEach(b => b.onclick = () => setAdminView(b.dataset.goto));

    $("#dashDate").textContent = new Intl.DateTimeFormat("en-PH", { weekday:"long", month:"long", day:"numeric", year:"numeric" }).format(new Date());
  }

  function renderChart() {
    const N = state.chartDays || 7;
    const paid = state.orders.filter(o => o.payment && o.status !== "cancelled");
    const byDay = {};
    paid.forEach(o=>{
      const d = o.day || o.date || "—";
      if (!byDay[d]) byDay[d] = { revenue:0, cost:0 };
      byDay[d].revenue += o.total;
      byDay[d].cost += orderCost(o);
    });
    // always show the last N calendar days, so the axis never jumps around
    const days = [];
    for (let i=N-1;i>=0;i--) {
      const dt = new Date(); dt.setDate(dt.getDate()-i);
      const key = dt.toISOString().slice(0,10);
      days.push([key, byDay[key] || { revenue:0, cost:0 }]);
    }
    const max = Math.max(1, ...days.flatMap(([,v])=>[v.revenue, v.cost, Math.max(0,v.revenue-v.cost)]));
    const hasData = days.some(([,v]) => v.revenue > 0 || v.cost > 0);
    const dlabel = key => {
      const d = new Date(key + "T00:00:00");
      return new Intl.DateTimeFormat("en-PH", { month:"short", day:"numeric" }).format(d);
    };
    const every = N > 14 ? 3 : (N > 7 ? 2 : 1);   // thin the axis labels on 14/30 days

    $("#revChart").innerHTML = days.map(([d,v],idx)=>{
      const profit = Math.max(0, v.revenue - v.cost);
      const tip = `${dlabel(d)}\nRevenue ${peso(v.revenue)}\nCost ${peso(v.cost)}\nProfit ${peso(v.revenue - v.cost)}`;
      return `<div class="flex-1 h-full flex items-end justify-center gap-1" data-tip="${tip}">
        <div class="w-1/3 rounded-t bg-accent/90 transition-[filter] hover:brightness-125" style="height:${v.revenue/max*100}%"></div>
        <div class="w-1/3 rounded-t bg-amber/90 transition-[filter] hover:brightness-125" style="height:${v.cost/max*100}%"></div>
        <div class="w-1/3 rounded-t bg-[#3b82f6] transition-[filter] hover:brightness-125" style="height:${profit/max*100}%"></div>
      </div>`;
    }).join("");

    $("#revChartLabels").innerHTML = days.map(([d],idx)=>
      `<span class="flex-1 text-center truncate">${idx % every === 0 ? esc(String(d).slice(5)) : ""}</span>`).join("")
      + (hasData ? "" : `<span class="absolute inset-x-0 top-16 text-center text-xs text-muted pointer-events-none">No paid orders in this range yet</span>`);
  }

  /* instant tooltip — replaces the slow native title tooltip */
  (function bindChartTip(){
    const chart = $("#revChart"), tip = $("#chartTip"), wrap = $("#chartWrap");
    if (!chart || !tip || !wrap) return;
    const hide = () => tip.classList.add("hidden");
    chart.addEventListener("mouseover", e => {
      const col = e.target.closest("[data-tip]");
      if (!col) return hide();
      tip.textContent = col.dataset.tip;
      tip.classList.remove("hidden");
      const wr = wrap.getBoundingClientRect(), cr = col.getBoundingClientRect();
      const x = Math.min(Math.max(70, cr.left - wr.left + cr.width/2), wr.width - 70);
      tip.style.left = x + "px";
      tip.style.top = (cr.top - wr.top - 4) + "px";
      tip.style.transform = "translate(-50%,-100%)";
    });
    chart.addEventListener("mousemove", e => {
      if (tip.classList.contains("hidden")) return;
      const col = e.target.closest("[data-tip]");
      if (!col) return hide();
    });
    chart.addEventListener("mouseleave", hide);
  })();

  $$("#chartRange .cr").forEach(b => b.addEventListener("click", () => {
    state.chartDays = Number(b.dataset.days);
    $$("#chartRange .cr").forEach(x => {
      const on = x.dataset.days === b.dataset.days;
      x.className = "cr h-6 px-2 rounded-md text-[11px] font-bold border " +
        (on ? "border-accent text-accent bg-accent/10" : "border-line text-muted bg-panel2");
    });
    renderChart();
  }));

  function renderMargins() {
    const rows = state.menu.map(item=>{
      const cost = productCost(item.id), profit = item.price - cost;
      const margin = item.price ? profit/item.price*100 : 0;
      return { item, cost, margin };
    }).filter(r=>r.cost>0).sort((a,b)=>b.margin-a.margin).slice(0,6);
    $("#marginList").innerHTML = rows.length ? rows.map(r=>`
      <div class="flex items-center gap-2 text-xs">
        <span class="w-24 truncate text-muted" title="${esc(r.item.name)}">${esc(r.item.name)}</span>
        <div class="flex-1 h-2.5 rounded-full bg-line overflow-hidden">
          <div class="h-full rounded-full bg-gradient-to-r from-amber to-accent" style="width:${Math.max(4,Math.min(100,r.margin))}%"></div>
        </div>
        <strong class="w-12 text-right text-accent">${r.margin.toFixed(0)}%</strong>
      </div>`).join("")
      : `<p class="text-sm text-muted">Add recipes in Costing to compare margins.</p>`;
  }

  function renderSales() {
    const all = state.orders.filter(o => o.payment && o.status !== "cancelled");
    const rows = all.filter(o =>
      (state.saleType === "all" || normType(o.type) === state.saleType) &&
      (state.salePay === "all" || (o.payment || "") === state.salePay)).slice(0, 200);
    const sum = rows.reduce((s,o)=>s+o.total,0), csum = rows.reduce((s,o)=>s+orderCost(o),0);
    $("#dashSalesCount").textContent = `${rows.length} of ${all.length} paid · ${peso(sum)} · profit ${peso(sum-csum)}`;
    $("#salesTable").innerHTML = rows.length ? rows.map(o=>{
      const cost = orderCost(o), profit = o.total - cost;
      return `<tr>
        <td class="py-2.5 font-bold">${esc(o.number)}</td>
        <td class="text-muted">${esc(o.time||"")}</td>
        <td class="text-muted">${esc(typeLabel(o.type))}</td>
        <td class="text-muted">${esc(o.payment||"—")}</td>
        <td class="text-right font-bold">${peso(o.total)}</td>
        <td class="text-right text-amber">${peso(cost)}</td>
        <td class="text-right font-bold ${profit>=0?"text-accent":"text-red-400"}">${peso(profit)}</td>
      </tr>`;
    }).join("") : `<tr><td colspan="7" class="text-center text-muted py-8 text-sm">${all.length ? "No paid orders match this filter." : "No completed sales yet — cash out an order from the POS."}</td></tr>`;
  }

  function renderAdminOrders() {
    const list = state.orders.filter(o =>
      (state.qFilter === "all" || o.status === state.qFilter) &&
      (state.qType === "all" || normType(o.type) === state.qType));
    $("#adminOrders").innerHTML = list.length ? list.map(orderCardHTML).join("")
      : `<p class="text-muted text-sm col-span-full text-center py-8">No orders match this filter.</p>`;
    bindOrderButtons($("#adminOrders"));
  }

  function renderMenuTable() {
    const q = (state.menuQ || "").toLowerCase();
    const rows = state.menu.filter(i =>
      (state.menuCat === "all" || i.cat === state.menuCat) &&
      (state.menuOnly !== "available" || i.available) &&
      (!q || i.name.toLowerCase().includes(q) || (i.description || "").toLowerCase().includes(q)));
    $("#menuCount").textContent = `${rows.length} of ${state.menu.length} item(s)`;
    $("#menuTable").innerHTML = rows.map(i=>`
      <tr>
        <td class="px-4 py-3"><strong>${esc(i.icon)} ${esc(i.name)}</strong><br><span class="text-xs text-muted">${esc(i.description)}</span></td>
        <td class="px-4 py-3 text-muted">${esc(i.cat)}</td>
        <td class="px-4 py-3 text-right font-bold tabular-nums">${peso(i.price)}</td>
        <td class="px-4 py-3"><span class="text-xs font-bold ${i.available?"text-accent":"text-red-400"}">${i.available?"Available":"Unavailable"}</span></td>
        <td class="px-4 py-3 text-right whitespace-nowrap">
          <button data-mi-edit="${i.id}" class="h-8 px-3 rounded-lg bg-panel2 border border-line text-xs font-bold hover:border-accent/50">Edit</button>
          <button data-mi-tog="${i.id}" class="h-8 px-3 rounded-lg bg-panel2 border border-line text-xs font-bold hover:border-accent/50">${i.available?"Disable":"Enable"}</button>
          <button data-mi-del="${i.id}" class="h-8 px-3 rounded-lg bg-red-500/10 border border-red-500/40 text-red-300 text-xs font-bold">Delete</button>
        </td>
      </tr>`).join("") || `<tr><td colspan="5" class="text-center text-muted py-8 text-sm">No items match this filter.</td></tr>`;

    $("#menuTable").querySelectorAll("[data-mi-edit]").forEach(b=>b.onclick=()=>openItemModal(Number(b.dataset.miEdit)));
    $("#menuTable").querySelectorAll("[data-mi-tog]").forEach(b=>b.onclick=async ()=>{
      const it = state.menu.find(x=>x.id===Number(b.dataset.miTog)); if (!it) return;
      try { await callApi("menu_save",{...it, category:it.cat, available:!it.available});
        await loadFromDb(true); toast(it.name + (it.available?" disabled.":" enabled.")); }
      catch(e){ toast(e.message); }
    });
    $("#menuTable").querySelectorAll("[data-mi-del]").forEach(b=>b.onclick=async ()=>{
      const it = state.menu.find(x=>x.id===Number(b.dataset.miDel)); if (!it) return;
      if (!confirm("Delete "+it.name+"? Order history is preserved.")) return;
      try { const r = await callApi("menu_delete",{id:it.id});
        await loadFromDb(true); toast(r.disabled ? (r.note||"Marked unavailable.") : it.name+" deleted."); }
      catch(e){ toast(e.message); }
    });
  }

  function renderStock() {
    const q = (state.stockQ || "").toLowerCase();
    const lowCount = state.ingredients.filter(g=>g.low).length;
    const list = state.ingredients.filter(g =>
      (state.stockLow !== true || g.low) && (!q || g.name.toLowerCase().includes(q)));
    $("#stockCount").textContent = `${list.length} of ${state.ingredients.length} ingredient(s)` + (lowCount ? ` · ${lowCount} low` : "");
    $("#stockCards").innerHTML = list.length ? list.map(g=>{
      const pct = g.purchase_qty>0 ? Math.min(100, (g.stock / Math.max(g.purchase_qty, g.reorder_level||1))*100) : 0;
      const lowPct = g.reorder_level>0 ? Math.min(100,(g.reorder_level/Math.max(g.purchase_qty,1))*100) : 0;
      const color = g.low ? "bg-red-400" : (pct < 40 ? "bg-amber" : "bg-accent");
      return `
      <div class="rounded-2xl bg-panel border ${g.low?"border-red-400/50":"border-line"} p-4">
        <div class="flex items-start justify-between gap-2">
          <div>
            <div class="font-bold text-sm">${esc(g.name)}</div>
            <div class="text-xs text-muted mt-0.5">${g.stock} ${esc(g.unit)} on hand</div>
          </div>
          ${g.low?`<span class="text-[10px] font-bold px-2 py-0.5 rounded-full bg-red-400/15 text-red-300 border border-red-400/40">LOW</span>`:`<span class="text-[10px] font-bold px-2 py-0.5 rounded-full bg-accent/15 text-accent border border-accent/40">OK</span>`}
        </div>
        <div class="stockbar mt-3 relative">
          <i class="${color}" style="width:${Math.max(2,pct)}%"></i>
          ${g.reorder_level>0?`<span class="absolute top-[-3px] w-0.5 h-3.5 bg-red-300/80" style="left:${Math.min(99,lowPct)}%"></span>`:""}
        </div>
        <div class="flex items-center justify-between mt-3">
          <span class="text-[11px] text-muted">alert ≤ ${g.reorder_level} ${esc(g.unit)} · ${peso(g.unit_cost)}/${esc(g.unit)}</span>
          <button data-restock="${g.id}" class="h-7 px-2.5 rounded-lg bg-panel2 border border-line text-[11px] font-bold hover:border-accent/50">+ Restock</button>
          <button data-ing-edit="${g.id}" class="h-7 px-2.5 rounded-lg bg-panel2 border border-line text-[11px] font-bold hover:border-accent/50">Edit</button>
        </div>
      </div>`;
    }).join("") : `<p class="text-muted text-sm col-span-full text-center py-8">${state.ingredients.length ? "No ingredients match this filter." : "No ingredients — add your first supplier record."}</p>`;

    $("#stockCards").querySelectorAll("[data-restock]").forEach(b=>b.onclick=()=>{
      const g = ingById(Number(b.dataset.restock)); if (!g) return;
      const qty = prompt(`Restock ${g.name} (${g.unit}):`, "500");
      if (qty===null) return;
      const n = Number(qty);
      if (!n || n<=0) return toast("Enter a quantity.");
      callApi("stock_restock",{ id:g.id, qty:n })
        .then(()=>loadFromDb(true)).then(()=>toast(`Restocked ${g.name} +${n} ${g.unit}`))
        .catch(e=>toast(e.message));
    });
    $("#stockCards").querySelectorAll("[data-ing-edit]").forEach(b=>b.onclick=()=>openIngModal(Number(b.dataset.ingEdit)));

    $("#moveList").innerHTML = state.movements.length ? state.movements.slice(0,30).map(m=>`
      <div class="flex items-center justify-between text-xs py-1.5 border-b border-line/50">
        <span><strong>${esc(m.ingredient)}</strong>
          <span class="text-muted">· ${esc(m.reason)}${m.order_id?" #"+esc(m.order_id):""}</span></span>
        <span class="flex items-center gap-3">
          <span class="${m.change<0?"text-red-300":"text-accent"} font-bold tabular-nums">${m.change>0?"+":""}${m.change}</span>
          <span class="text-muted w-20 text-right">${esc(m.at||"")}</span>
        </span>
      </div>`).join("")
      : `<p class="text-muted text-sm py-4">No movements yet.</p>`;
  }

  function renderCosting() {
    $("#ingTable").innerHTML = state.ingredients.map(g=>`
      <tr>
        <td class="px-4 py-3 font-bold">${esc(g.name)}</td>
        <td class="px-4 py-3 text-right text-muted tabular-nums">${g.purchase_qty} ${esc(g.unit)}</td>
        <td class="px-4 py-3 text-right tabular-nums">${peso(g.purchase_price)}</td>
        <td class="px-4 py-3 text-right font-bold text-amber tabular-nums">${peso(g.unit_cost)} / ${esc(g.unit)}</td>
        <td class="px-4 py-3 text-right tabular-nums ${g.low?"text-red-300 font-bold":""}">${g.stock} ${esc(g.unit)}</td>
        <td class="px-4 py-3 text-right whitespace-nowrap">
          <button data-ing-edit="${g.id}" class="h-8 px-3 rounded-lg bg-panel2 border border-line text-xs font-bold hover:border-accent/50">Edit</button>
          <button data-ing-del="${g.id}" class="h-8 px-3 rounded-lg bg-red-500/10 border border-red-500/40 text-red-300 text-xs font-bold">Delete</button>
        </td>
      </tr>`).join("") || `<tr><td colspan="6" class="text-center text-muted py-6 text-sm">No ingredients recorded.</td></tr>`;

    $("#ingTable").querySelectorAll("[data-ing-edit]").forEach(b=>b.onclick=()=>openIngModal(Number(b.dataset.ingEdit)));
    $("#ingTable").querySelectorAll("[data-ing-del]").forEach(b=>b.onclick=async ()=>{
      const g = ingById(Number(b.dataset.ingDel)); if (!g) return;
      if (!confirm("Delete "+g.name+"? Recipes using it will be updated.")) return;
      try { await callApi("ingredient_delete",{id:g.id}); await loadFromDb(true); toast(g.name+" deleted."); }
      catch(e){ toast(e.message); }
    });

    $("#costTable").innerHTML = state.menu.map(item=>{
      const cost = productCost(item.id), profit = item.price - cost;
      const margin = item.price ? profit/item.price*100 : 0;
      const has = (state.recipes[item.id]||[]).length>0;
      return `<tr>
        <td class="px-4 py-3 font-bold">${esc(item.icon)} ${esc(item.name)}</td>
        <td class="px-4 py-3 text-right tabular-nums">${has?peso(cost):`<span class="text-muted">No recipe</span>`}</td>
        <td class="px-4 py-3 text-right tabular-nums">${peso(item.price)}</td>
        <td class="px-4 py-3 text-right font-bold tabular-nums ${profit>=0?"text-accent":"text-red-400"}">${peso(profit)}</td>
        <td class="px-4 py-3 text-right font-bold tabular-nums ${margin>=0?"text-accent":"text-red-400"}">${has?margin.toFixed(1)+"%":"—"}</td>
        <td class="px-4 py-3 text-right"><button data-recipe="${item.id}" class="h-8 px-3 rounded-lg bg-panel2 border border-line text-xs font-bold hover:border-accent/50">${has?"Edit recipe":"Add recipe"}</button></td>
      </tr>`;
    }).join("");

    $("#costTable").querySelectorAll("[data-recipe]").forEach(b=>b.onclick=()=>openRecipeModal(Number(b.dataset.recipe)));
  }

  /* ============================================================
     ADMIN — table filters (sales summary / menu / ingredients)
     ============================================================ */
  const CHIP_ON  = "border-accent text-accent bg-accent/10";
  const CHIP_OFF = "border-line text-muted bg-panel2";
  function bindChips(groupSel, chipCls, key, rerender) {
    const group = $(groupSel); if (!group) return;
    $$(groupSel + " ." + chipCls).forEach(b => b.addEventListener("click", () => {
      state[key] = b.dataset.v;
      $$(groupSel + " ." + chipCls).forEach(x => {
        const on = x.dataset.v === b.dataset.v;
        x.className = chipCls + " h-7 px-2.5 rounded-full text-[11px] font-bold border " + (on ? CHIP_ON : CHIP_OFF);
      });
      rerender();
    }));
  }
  bindChips("#dashSaleType", "sf",  "saleType",  renderSales);
  bindChips("#dashSalePay",  "pf",  "salePay",   renderSales);
  bindChips("#repSaleType",  "rtsf","repSaleType", renderReports);
  bindChips("#repSalePay",   "rpsf","repSalePay",  renderReports);

  // menu: search + category + available-only
  $("#menuSearch").addEventListener("input", e => { state.menuQ = e.target.value; renderMenuTable(); });
  $("#menuCat").addEventListener("change", e => { state.menuCat = e.target.value; renderMenuTable(); });
  $("#menuAvailBtn").addEventListener("click", () => {
    const on = state.menuOnly !== "available";
    state.menuOnly = on ? "available" : "all";
    const b = $("#menuAvailBtn");
    b.dataset.v = state.menuOnly;
    b.textContent = on ? "Available only" : "All items";
    b.className = "h-9 px-3 rounded-lg text-xs font-bold border " + (on ? CHIP_ON : CHIP_OFF);
    renderMenuTable();
  });

  // ingredients: search + low-stock-only
  $("#stockSearch").addEventListener("input", e => { state.stockQ = e.target.value; renderStock(); });
  $("#stockLowBtn").addEventListener("click", () => {
    state.stockLow = !state.stockLow;
    const b = $("#stockLowBtn");
    b.dataset.v = state.stockLow ? "on" : "off";
    b.className = "h-9 px-3 rounded-lg text-xs font-bold border " + (state.stockLow ? CHIP_ON : CHIP_OFF);
    renderStock();
  });

  /* ---------- admin live polling ---------- */
  function updateLiveLabel() {
    if (!state.lastLoad) return;
    const s = Math.round((Date.now()-state.lastLoad)/1000);
    const txt = s<5 ? "just now" : s<60 ? s+"s ago" : Math.round(s/60)+"m ago";
    $("#liveLabel").textContent = "Live · " + txt;
  }
  setInterval(()=>{ if (state.role) { loadFromDb(true).catch(()=>{ setDbStatus(false, "Database disconnected"); renderAll(); }); } updateLiveLabel(); }, 10000);
  setInterval(updateLiveLabel, 5000);

  /* ============================================================
     ADMIN — modals (item / ingredient / recipe)
     ============================================================ */
  $("#addItemBtn").addEventListener("click", ()=>openItemModal());
  function openItemModal(id=null) {
    const it = id ? state.menu.find(m=>m.id===id) : null;
    state.editingItemId = it ? it.id : null;
    $("#itemModalTitle").textContent = it ? "Edit menu item" : "Add menu item";
    $("#itemName").value = it ? it.name : "";
    $("#itemCategory").value = it ? it.cat : "Coffee";
    $("#itemPrice").value = it ? it.price : "";
    $("#itemDescription").value = it ? it.description : "";
    $("#itemIcon").value = it ? it.icon : "";
    $("#itemModal").classList.replace("hidden","flex");
  }
  $("#saveItemBtn").addEventListener("click", async ()=>{
    const name = $("#itemName").value.trim(), price = Number($("#itemPrice").value);
    if (!name || price<=0) return toast("Enter an item name and a valid price.");
    const editing = state.editingItemId ? state.menu.find(m=>m.id===state.editingItemId) : null;
    try {
      await callApi("menu_save", {
        id: state.editingItemId, name, category: $("#itemCategory").value, price,
        description: $("#itemDescription").value.trim() || "Cafe favourite",
        icon: $("#itemIcon").value.trim() || (editing ? editing.icon : "☕"),
        available: editing ? editing.available : true,
      });
      $("#itemModal").classList.replace("flex","hidden");
      await loadFromDb(true);
      toast(name + (state.editingItemId ? " updated." : " added."));
      state.editingItemId = null;
    } catch(e){ toast(e.message); }
  });

  $("#addIngBtn").addEventListener("click", ()=>openIngModal());
  function openIngModal(id=null) {
    const g = id ? ingById(id) : null;
    state.editingIngId = g ? g.id : null;
    $("#ingModalTitle").textContent = g ? "Edit ingredient" : "Add ingredient";
    $("#ingName").value = g ? g.name : "";
    $("#ingQty").value = g ? g.purchase_qty : "";
    $("#ingUnit").value = g ? g.unit : "g";
    $("#ingPrice").value = g ? g.purchase_price : "";
    $("#ingStock").value = g ? g.stock : "";
    $("#ingReorder").value = g ? g.reorder_level : "";
    $("#ingModal").classList.replace("hidden","flex");
  }
  $("#saveIngBtn").addEventListener("click", async ()=>{
    const name = $("#ingName").value.trim();
    const pq = Number($("#ingQty").value), pp = Number($("#ingPrice").value);
    if (!name || pq<=0 || pp<=0) return toast("Enter name, purchased quantity and price.");
    try {
      await callApi("ingredient_save", {
        id: state.editingIngId, name, purchase_qty: pq, unit: $("#ingUnit").value,
        purchase_price: pp, stock: Number($("#ingStock").value||0), reorder_level: Number($("#ingReorder").value||0),
      });
      $("#ingModal").classList.replace("flex","hidden");
      await loadFromDb(true);
      toast(name + (state.editingIngId ? " updated." : " added."));
      state.editingIngId = null;
    } catch(e){ toast(e.message); }
  });

  function openRecipeModal(productId) {
    state.recipeProductId = productId;
    const item = state.menu.find(m=>m.id===productId);
    const lines = state.recipes[productId] || [];
    $("#recipeTitle").textContent = (item?item.name:"Product") + " recipe";
    $("#recipeFields").innerHTML = state.ingredients.map(g=>{
      const line = lines.find(x=>x.ingredientId===g.id);
      return `<label class="text-xs font-bold text-muted">${esc(g.name)}
        <small class="text-muted/70 font-normal">/ ${esc(g.unit)}</small>
        <input type="number" min="0" step="0.01" data-ri="${g.id}" value="${line?line.quantity:0}"
          class="mt-1 w-full h-9 px-3 rounded-lg bg-ink border border-line text-sm text-white tabular-nums focus:outline-none focus:border-accent/60" />
      </label>`;
    }).join("") || `<p class="col-span-2 text-sm text-muted">Add ingredients first.</p>`;
    $("#recipeModal").classList.replace("hidden","flex");
  }
  $("#saveRecipeBtn").addEventListener("click", async ()=>{
    const lines = [...$("#recipeFields").querySelectorAll("[data-ri]")]
      .map(i=>({ ingredientId:Number(i.dataset.ri), quantity:Number(i.value) }))
      .filter(l=>l.quantity>0);
    if (!lines.length) return toast("Add at least one ingredient.");
    try {
      await callApi("recipe_save", { menuItemId: state.recipeProductId, lines });
      $("#recipeModal").classList.replace("flex","hidden");
      await loadFromDb(true);
      toast("Recipe saved to database.");
    } catch(e){ toast(e.message); }
  });

  /* ============================================================
     BOOT — restore PHP session (if any), else show login screen
     ============================================================ */
  showLoginTab("admin");
  renderAll();
  (async () => {
    try {
      const s = await callApi("session");
      if (s && s.ok && s.role) {
        enterApp(s.role, s.name);
        init();
        return;
      }
    } catch (e) { /* unreachable api.php → login screen stays (offline demo creds work) */ }
    $("#loginScreen").classList.remove("hidden");
  })();
})();
