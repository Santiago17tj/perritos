import { useState, useEffect } from "react";
import "./App.css";

// Adaptador sencillo para usar localStorage como el storage asíncrono
const storage = {
  async get(key) {
    try {
      const value = window.localStorage.getItem(key);
      return value != null ? { value } : null;
    } catch {
      return null;
    }
  },
  async set(key, value) {
    try {
      window.localStorage.setItem(key, value);
    } catch {
      // ignorar errores de cuota
    }
  },
};

const DEFAULT_PRODUCTS = [
  { id: "sencillo", name: "Sencillo", emoji: "🌭", price: 6000, salchichas: 1, panes: 1, bebidas: 1 },
  { id: "doble", name: "Doble", emoji: "🌭🌭", price: 8000, salchichas: 2, panes: 1, bebidas: 1 },
  { id: "americano", name: "Americano", emoji: "🔥", price: 10000, salchichas: 1, panes: 1, bebidas: 1 },
];

const DEFAULT_INGREDIENT_FIELDS = [
  { key: "salchichas", label: "Salchichas" },
  { key: "panes", label: "Panes" },
  { key: "bebidas", label: "Bebidas" },
  { key: "queso_tocineta", label: "Queso / Tocineta" },
  { key: "salsas", label: "Salsas (frascos)" },
];

const DEFAULT_EXPENSE_TEMPLATES = ["Gas", "Arriendo del puesto", "Transporte", "Otro"];

function formatCOP(n) {
  return "$" + Number(n).toLocaleString("es-CO");
}

function getTodayKey() {
  return new Date().toISOString().slice(0, 10);
}

const defaultInventory = { salchichas: 0, panes: 0, bebidas: 0, queso_tocineta: 0, salsas: 0 };

function App() {
  const [tab, setTab] = useState("ventas");
  const [sales, setSales] = useState([]);
  const [inventory, setInventory] = useState(defaultInventory);
  const [expenses, setExpenses] = useState([]);
  const [restockLog, setRestockLog] = useState([]);
  const [loaded, setLoaded] = useState(false);

  // Productos configurables
  const [products, setProducts] = useState(DEFAULT_PRODUCTS);
  const [showProdConfig, setShowProdConfig] = useState(false);
  const [prodDraft, setProdDraft] = useState(DEFAULT_PRODUCTS);

  // Historial / reportes
  const [daysIndex, setDaysIndex] = useState([]);
  const [reportDays, setReportDays] = useState([]);
  const [reportLoading, setReportLoading] = useState(false);

  // Restock modal
  const [showRestock, setShowRestock] = useState(false);
  const [restockValues, setRestockValues] = useState({ salchichas: "", panes: "", bebidas: "", queso_tocineta: "", salsas: "" });

  // Expense modal
  const [showExpense, setShowExpense] = useState(false);
  const [expName, setExpName] = useState("");
  const [expAmount, setExpAmount] = useState("");
  const [expType, setExpType] = useState("variable");

  // Inventory edit modal
  const [showInvEdit, setShowInvEdit] = useState(false);
  const [invEditValues, setInvEditValues] = useState({ ...defaultInventory });

  // Configuración de logo / nombre
  const [logoUrl, setLogoUrl] = useState("");
  const [showLogoConfig, setShowLogoConfig] = useState(false);
  const [logoInput, setLogoInput] = useState("");

  // Configuración dinámica de inventario
  const [ingredientFields, setIngredientFields] = useState(DEFAULT_INGREDIENT_FIELDS);
  const [showInvConfig, setShowInvConfig] = useState(false);
  const [invFieldsText, setInvFieldsText] = useState("");

  // Configuración dinámica de plantillas de gastos
  const [expenseTemplates, setExpenseTemplates] = useState(DEFAULT_EXPENSE_TEMPLATES);
  const [showExpenseConfig, setShowExpenseConfig] = useState(false);
  const [expenseTemplatesText, setExpenseTemplatesText] = useState("");

  // Load from storage
  useEffect(() => {
    async function load() {
      try {
        const today = getTodayKey();
        const s = await storage.get("sales_" + today);
        if (s) setSales(JSON.parse(s.value));
        const inv = await storage.get("inventory");
        if (inv) setInventory(JSON.parse(inv.value));
        const exp = await storage.get("expenses_" + today);
        if (exp) setExpenses(JSON.parse(exp.value));
        const rst = await storage.get("restock_" + today);
        if (rst) setRestockLog(JSON.parse(rst.value));
        const idx = await storage.get("days_index");
        let arr = idx ? JSON.parse(idx.value) : [];
        if (!arr.includes(today)) {
          arr.push(today);
          await storage.set("days_index", JSON.stringify(arr));
        }
        arr.sort(); // ascending
        setDaysIndex(arr);
        const logo = await storage.get("logo_url");
        if (logo) {
          setLogoUrl(logo.value);
          setLogoInput(logo.value);
        }
        const prodCfg = await storage.get("products_config");
        if (prodCfg) {
          try {
            const parsed = JSON.parse(prodCfg.value);
            if (Array.isArray(parsed) && parsed.length > 0) {
              setProducts(parsed);
              setProdDraft(parsed);
            }
          } catch {}
        } else {
          setProdDraft(DEFAULT_PRODUCTS);
        }
        const ingCfg = await storage.get("ingredient_fields");
        if (ingCfg) {
          try {
            const parsed = JSON.parse(ingCfg.value);
            if (Array.isArray(parsed) && parsed.length > 0) setIngredientFields(parsed);
          } catch {}
        }
        const expCfg = await storage.get("expense_templates");
        if (expCfg) {
          try {
            const parsed = JSON.parse(expCfg.value);
            if (Array.isArray(parsed) && parsed.length > 0) setExpenseTemplates(parsed);
          } catch {}
        }
      } catch (e) {}
      setLoaded(true);
    }
    load();
  }, []);

  // Cargar resumen histórico cuando se abre la pestaña de reportes
  useEffect(() => {
    async function loadReports() {
      if (tab !== "reportes" || daysIndex.length === 0) return;
      setReportLoading(true);
      try {
        const sorted = [...daysIndex].sort(); // asc
        const lastSeven = sorted.slice(-7); // últimos 7 días disponibles
        const list = [];
        for (const day of lastSeven) {
          const s = await storage.get("sales_" + day);
          const e = await storage.get("expenses_" + day);
          const salesArr = s ? JSON.parse(s.value) : [];
          const expArr = e ? JSON.parse(e.value) : [];
          const totalVentasDay = salesArr.reduce((a, s2) => a + (s2.price || 0), 0);
          const totalGastosDay = expArr.reduce((a, ex) => a + (ex.amount || 0), 0);
          list.push({
            day,
            totalVentas: totalVentasDay,
            totalGastos: totalGastosDay,
            ganancia: totalVentasDay - totalGastosDay,
          });
        }
        // más reciente primero
        list.sort((a, b) => (a.day < b.day ? 1 : -1));
        setReportDays(list);
      } catch (e) {
        setReportDays([]);
      } finally {
        setReportLoading(false);
      }
    }
    loadReports();
  }, [tab, daysIndex]);

  async function saveSales(data) {
    setSales(data);
    await storage.set("sales_" + getTodayKey(), JSON.stringify(data));
  }

  async function saveInventory(data) {
    setInventory(data);
    await storage.set("inventory", JSON.stringify(data));
  }

  async function saveExpenses(data) {
    setExpenses(data);
    await storage.set("expenses_" + getTodayKey(), JSON.stringify(data));
  }

  async function saveRestockLog(data) {
    setRestockLog(data);
    await storage.set("restock_" + getTodayKey(), JSON.stringify(data));
  }

  function addSale(product) {
    const current = {
      salchichas: inventory.salchichas || 0,
      panes: inventory.panes || 0,
      bebidas: inventory.bebidas || 0,
    };
    if (
      current.salchichas < product.salchichas ||
      current.panes < product.panes ||
      current.bebidas < product.bebidas
    ) {
      alert("No tienes suficiente inventario para este perro. Surtir o ajustar inventario primero.");
      return;
    }
    const newSale = {
      ...product,
      time: new Date().toLocaleTimeString("es-CO", { hour: "2-digit", minute: "2-digit" }),
    };
    const updated = [newSale, ...sales];
    saveSales(updated);
    const newInv = { ...inventory };
    newInv.salchichas = current.salchichas - product.salchichas;
    newInv.panes = current.panes - product.panes;
    newInv.bebidas = current.bebidas - product.bebidas;
    saveInventory(newInv);
  }

  function undoLastSale() {
    if (sales.length === 0) return;
    const last = sales[0];
    const updated = sales.slice(1);
    saveSales(updated);
    // Restore inventory
    const newInv = { ...inventory };
    newInv.salchichas = (newInv.salchichas || 0) + last.salchichas;
    newInv.panes = (newInv.panes || 0) + last.panes;
    newInv.bebidas = (newInv.bebidas || 0) + last.bebidas;
    saveInventory(newInv);
  }

  function applyRestock() {
    const newInv = { ...inventory };
    const entry = {};
    Object.keys(restockValues).forEach(k => {
      const val = parseInt(restockValues[k]) || 0;
      if (val > 0) {
        newInv[k] = (newInv[k] || 0) + val;
        entry[k] = val;
      }
    });
    saveInventory(newInv);
    const newLog = [{ time: new Date().toLocaleTimeString("es-CO", { hour: "2-digit", minute: "2-digit" }), items: entry }, ...restockLog];
    saveRestockLog(newLog);
    const reset = {};
    ingredientFields.forEach(f => { reset[f.key] = ""; });
    setRestockValues(reset);
    setShowRestock(false);
  }

  function applyInvEdit() {
    saveInventory({ ...invEditValues });
    setShowInvEdit(false);
  }

  function addExpense() {
    if (!expName || !expAmount) return;
    const newExp = { name: expName, amount: parseInt(expAmount), type: expType, time: new Date().toLocaleTimeString("es-CO", { hour: "2-digit", minute: "2-digit" }) };
    const updated = [newExp, ...expenses];
    saveExpenses(updated);
    setExpName(""); setExpAmount(""); setExpType("variable");
    setShowExpense(false);
  }

  const totalVentas = sales.reduce((a, s) => a + s.price, 0);
  const totalGastos = expenses.reduce((a, e) => a + e.amount, 0);
  const ganancia = totalVentas - totalGastos;

  const salesByProduct = products.map(p => ({
    ...p,
    count: sales.filter(s => s.id === p.id).length,
    total: sales.filter(s => s.id === p.id).reduce((a, s2) => a + s2.price, 0),
  }));

  // Helpers para configuración
  function parseIngredientFields(text) {
    const lines = text.split("\n").map(l => l.trim()).filter(Boolean);
    if (lines.length === 0) return DEFAULT_INGREDIENT_FIELDS;
    const result = [];
    const usedKeys = new Set();
    lines.forEach((labelRaw, index) => {
      const label = labelRaw;
      let key = label
        .toLowerCase()
        .normalize("NFD").replace(/[\u0300-\u036f]/g, "")
        .replace(/[^a-z0-9]+/g, "_")
        .replace(/^_+|_+$/g, "") || `campo_${index + 1}`;
      let finalKey = key;
      let i = 2;
      while (usedKeys.has(finalKey)) {
        finalKey = `${key}_${i++}`;
      }
      usedKeys.add(finalKey);
      result.push({ key: finalKey, label });
    });
    return result;
  }

  function handleSaveInvFields() {
    const parsed = parseIngredientFields(invFieldsText);
    setIngredientFields(parsed);
    storage.set("ingredient_fields", JSON.stringify(parsed));
    // asegurar que los estados de inventario tengan todas las claves nuevas
    const baseInv = { ...inventory };
    const baseEdit = { ...invEditValues };
    const baseRestock = { ...restockValues };
    parsed.forEach(f => {
      if (baseInv[f.key] == null) baseInv[f.key] = 0;
      if (baseEdit[f.key] == null) baseEdit[f.key] = 0;
      if (baseRestock[f.key] == null) baseRestock[f.key] = "";
    });
    setInventory(baseInv);
    setInvEditValues(baseEdit);
    setRestockValues(baseRestock);
    setShowInvConfig(false);
  }

  function handleSaveExpenseTemplates() {
    const lines = expenseTemplatesText.split("\n").map(l => l.trim()).filter(Boolean);
    const list = lines.length > 0 ? lines : DEFAULT_EXPENSE_TEMPLATES;
    setExpenseTemplates(list);
    storage.set("expense_templates", JSON.stringify(list));
    setShowExpenseConfig(false);
  }

  function handleAddProductRow() {
    setProdDraft(d => [
      ...d,
      {
        id: `prod_${Date.now()}`,
        name: "",
        emoji: "🌭",
        price: 0,
        salchichas: 1,
        panes: 1,
        bebidas: 1,
      },
    ]);
  }

  function handleSaveProducts() {
    const cleaned = prodDraft
      .map((p, index) => {
        const name = (p.name || "").trim();
        if (!name) return null;
        const id = p.id || `prod_${index}`;
        return {
          id,
          name,
          emoji: p.emoji || "🌭",
          price: Number(p.price) || 0,
          salchichas: Number(p.salchichas) || 0,
          panes: Number(p.panes) || 0,
          bebidas: Number(p.bebidas) || 0,
        };
      })
      .filter(Boolean);
    if (cleaned.length === 0) {
      alert("Debes dejar al menos un producto.");
      return;
    }
    setProducts(cleaned);
    setProdDraft(cleaned);
    storage.set("products_config", JSON.stringify(cleaned));
    setShowProdConfig(false);
  }

  if (!loaded) return (
    <div style={{ display: "flex", alignItems: "center", justifyContent: "center", height: "100vh", background: "#1a0a00", color: "#f5c842", fontFamily: "Georgia, serif", fontSize: 24 }}>
      🌭 Cargando...
    </div>
  );

  return (
    <div style={{ fontFamily: "'Georgia', serif", background: "#1a0a00", minHeight: "100vh", maxWidth: 480, margin: "0 auto", position: "relative", paddingBottom: 80 }}>
      {/* Header */}
      <div style={{ background: "linear-gradient(135deg, #c0392b 0%, #922b21 100%)", padding: "20px 20px 14px", display: "flex", alignItems: "center", gap: 12, boxShadow: "0 4px 20px #0008" }}>
        {logoUrl ? (
          <img src={logoUrl} alt="Logo Perrito Perrón" style={{ width: 40, height: 40, borderRadius: 8, objectFit: "cover", border: "2px solid #f5c842", background: "#1a0a00" }} />
        ) : (
          <span style={{ fontSize: 36 }}>🌭</span>
        )}
        <div>
          <div style={{ color: "#f5c842", fontWeight: "bold", fontSize: 20, letterSpacing: 1 }}>Perrito Perrón</div>
          <div style={{ color: "#fde9a0", fontSize: 12 }}>{new Date().toLocaleDateString("es-CO", { weekday: "long", day: "numeric", month: "long" })}</div>
        </div>
        <div style={{ marginLeft: "auto", textAlign: "right" }}>
          <div style={{ color: "#fde9a0", fontSize: 11 }}>Ganancia del día</div>
          <div style={{ color: ganancia >= 0 ? "#2ecc71" : "#e74c3c", fontWeight: "bold", fontSize: 18 }}>{formatCOP(ganancia)}</div>
        </div>
      </div>

      {/* Content */}
      <div style={{ padding: "16px 16px 0" }}>
        {/* VENTAS TAB */}
        {tab === "ventas" && (
          <div>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 4 }}>
              <div style={{ color: "#f5c842", fontWeight: "bold", fontSize: 16 }}>⚡ Registrar venta</div>
              <button
                onClick={() => { setProdDraft(products); setShowProdConfig(true); }}
                style={{ background: "#2c1a0a", border: "1px dashed #5a3a1a", borderRadius: 8, padding: "4px 10px", color: "#fde9a0", fontSize: 11, cursor: "pointer" }}
              >
                ⚙️ Productos
              </button>
            </div>
            <div style={{ color: "#7a5a3a", fontSize: 11, marginBottom: 12 }}>
              Toca el perro vendido. Se descuenta del inventario automáticamente.
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 12, marginBottom: 20 }}>
              {products.map(p => {
                const piezasPosibles = Math.min(
                  Math.floor((inventory.salchichas || 0) / p.salchichas),
                  Math.floor((inventory.panes || 0) / p.panes),
                  Math.floor((inventory.bebidas || 0) / p.bebidas),
                );
                const disabled = piezasPosibles <= 0;
                return (
                  <button
                    key={p.id}
                    onClick={() => !disabled && addSale(p)}
                    disabled={disabled}
                    style={{
                      background: disabled ? "#3a1a1a" : "linear-gradient(135deg, #922b21, #c0392b)",
                      border: "2px solid #f5c842",
                      borderRadius: 16,
                      padding: "16px 20px",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "space-between",
                      cursor: disabled ? "not-allowed" : "pointer",
                      opacity: disabled ? 0.4 : 1,
                      boxShadow: "0 4px 15px #0005",
                      transition: "transform 0.1s, opacity 0.1s",
                    }}
                    onPointerDown={e => {
                      if (!disabled) e.currentTarget.style.transform = "scale(0.96)";
                    }}
                    onPointerUp={e => {
                      if (!disabled) e.currentTarget.style.transform = "scale(1)";
                    }}
                  >
                    <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                      <span style={{ fontSize: 28 }}>{p.emoji}</span>
                      <div style={{ textAlign: "left" }}>
                        <div style={{ color: "#fff", fontWeight: "bold", fontSize: 17 }}>{p.name}</div>
                        <div style={{ color: "#fde9a0", fontSize: 12 }}>
                          {p.salchichas} salchicha{p.salchichas > 1 ? "s" : ""} + bebida
                        </div>
                        <div style={{ color: "#7a5a3a", fontSize: 11, marginTop: 2 }}>
                          {disabled ? "Sin inventario para este perro" : `Puedes hacer ~${piezasPosibles} hoy`}
                        </div>
                      </div>
                    </div>
                    <div style={{ textAlign: "right" }}>
                      <div style={{ color: "#f5c842", fontWeight: "bold", fontSize: 20 }}>{formatCOP(p.price)}</div>
                    </div>
                  </button>
                );
              })}
            </div>

            {/* Undo */}
            {sales.length > 0 && (
              <button onClick={undoLastSale} style={{ width: "100%", background: "#2c1a0a", border: "1px solid #5a3a1a", borderRadius: 10, padding: "10px", color: "#e07b39", fontSize: 13, cursor: "pointer", marginBottom: 16 }}>
                ↩ Deshacer última venta ({sales[0]?.name} — {formatCOP(sales[0]?.price)})
              </button>
            )}

            {/* Today summary bar */}
            <div style={{ background: "#2c1a0a", borderRadius: 14, padding: "14px 16px", border: "1px solid #5a3a1a", marginBottom: 16 }}>
              <div style={{ color: "#f5c842", fontWeight: "bold", fontSize: 14, marginBottom: 10 }}>📊 Resumen del día</div>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 6 }}>
                {salesByProduct.map(p => (
                  <div key={p.id} style={{ textAlign: "center" }}>
                    <div style={{ fontSize: 20 }}>{p.emoji}</div>
                    <div style={{ color: "#fde9a0", fontSize: 12 }}>{p.name}</div>
                    <div style={{ color: "#f5c842", fontWeight: "bold", fontSize: 18 }}>{p.count}</div>
                    <div style={{ color: "#e07b39", fontSize: 11 }}>{formatCOP(p.total)}</div>
                  </div>
                ))}
              </div>
              <div style={{ borderTop: "1px solid #5a3a1a", paddingTop: 10, display: "flex", justifyContent: "space-between" }}>
                <div style={{ color: "#fde9a0", fontSize: 13 }}>Total ventas: <span style={{ color: "#2ecc71", fontWeight: "bold" }}>{formatCOP(totalVentas)}</span></div>
                <div style={{ color: "#fde9a0", fontSize: 13 }}>Perros: <span style={{ color: "#f5c842", fontWeight: "bold" }}>{sales.length}</span></div>
              </div>
            </div>

            {/* Sales log */}
            {sales.length > 0 && (
              <div style={{ background: "#2c1a0a", borderRadius: 14, padding: "14px 16px", border: "1px solid #5a3a1a" }}>
                <div style={{ color: "#f5c842", fontWeight: "bold", fontSize: 13, marginBottom: 8 }}>🕐 Últimas ventas</div>
                {sales.slice(0, 8).map((s, i) => (
                  <div key={i} style={{ display: "flex", justifyContent: "space-between", padding: "6px 0", borderBottom: i < Math.min(sales.length, 8) - 1 ? "1px solid #3d2510" : "none" }}>
                    <span style={{ color: "#fde9a0", fontSize: 13 }}>{s.emoji} {s.name}</span>
                    <div style={{ display: "flex", gap: 12 }}>
                      <span style={{ color: "#2ecc71", fontSize: 13 }}>{formatCOP(s.price)}</span>
                      <span style={{ color: "#7a5a3a", fontSize: 12 }}>{s.time}</span>
                    </div>
                  </div>
                ))}
                {sales.length > 8 && <div style={{ color: "#7a5a3a", fontSize: 12, textAlign: "center", marginTop: 6 }}>+{sales.length - 8} más...</div>}
              </div>
            )}
          </div>
        )}

        {/* INVENTARIO TAB */}
        {tab === "inventario" && (
          <div>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
              <div style={{ color: "#f5c842", fontWeight: "bold", fontSize: 16 }}>📦 Inventario actual</div>
              <div style={{ display: "flex", gap: 8 }}>
                <button onClick={() => { setInvEditValues({ ...inventory }); setShowInvEdit(true); }} style={{ background: "#2c1a0a", border: "1px solid #5a3a1a", borderRadius: 8, padding: "6px 12px", color: "#e07b39", fontSize: 12, cursor: "pointer" }}>✏️ Editar</button>
                <button onClick={() => setShowRestock(true)} style={{ background: "#c0392b", border: "none", borderRadius: 8, padding: "6px 12px", color: "#fff", fontSize: 12, cursor: "pointer", fontWeight: "bold" }}>+ Surtir</button>
                <button onClick={() => { setInvFieldsText(ingredientFields.map(f => f.label).join("\n")); setShowInvConfig(true); }} style={{ background: "#2c1a0a", border: "1px dashed #5a3a1a", borderRadius: 8, padding: "6px 10px", color: "#fde9a0", fontSize: 11, cursor: "pointer" }}>⚙️ Campos</button>
              </div>
            </div>

            <div style={{ background: "#2c1a0a", borderRadius: 14, padding: 16, border: "1px solid #5a3a1a", marginBottom: 16 }}>
              {ingredientFields.map(f => {
                const key = f.key;
                const label = f.label;
                const val = inventory[key] || 0;
                const low = val <= 5;
                return (
                  <div key={key} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "12px 0", borderBottom: "1px solid #3d2510" }}>
                    <div>
                      <div style={{ color: "#fde9a0", fontSize: 14 }}>{label}</div>
                      {low && val > 0 && <div style={{ color: "#e74c3c", fontSize: 11 }}>⚠️ Stock bajo</div>}
                      {val === 0 && <div style={{ color: "#e74c3c", fontSize: 11 }}>❌ Sin stock</div>}
                    </div>
                    <div style={{ background: low ? "#4a1a1a" : "#1a3a1a", borderRadius: 20, padding: "4px 16px", color: low ? "#e74c3c" : "#2ecc71", fontWeight: "bold", fontSize: 18 }}>
                      {val}
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Restock log */}
            {restockLog.length > 0 && (
              <div style={{ background: "#2c1a0a", borderRadius: 14, padding: 16, border: "1px solid #5a3a1a" }}>
                <div style={{ color: "#f5c842", fontWeight: "bold", fontSize: 13, marginBottom: 8 }}>📋 Surtidos de hoy</div>
                {restockLog.map((r, i) => (
                  <div key={i} style={{ padding: "8px 0", borderBottom: i < restockLog.length - 1 ? "1px solid #3d2510" : "none" }}>
                    <div style={{ color: "#7a5a3a", fontSize: 11, marginBottom: 4 }}>{r.time}</div>
                    {Object.entries(r.items).map(([k, v]) => {
                      const found = ingredientFields.find(f => f.key === k);
                      return (
                        <div key={k} style={{ color: "#fde9a0", fontSize: 13 }}>+{v} {found ? found.label : k}</div>
                      );
                    })}
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* GASTOS TAB */}
        {tab === "gastos" && (
          <div>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
              <div style={{ color: "#f5c842", fontWeight: "bold", fontSize: 16 }}>💸 Gastos del día</div>
              <div style={{ display: "flex", gap: 8 }}>
                <button onClick={() => setShowExpense(true)} style={{ background: "#c0392b", border: "none", borderRadius: 8, padding: "8px 16px", color: "#fff", fontSize: 13, cursor: "pointer", fontWeight: "bold" }}>+ Agregar</button>
                <button onClick={() => { setExpenseTemplatesText(expenseTemplates.join("\n")); setShowExpenseConfig(true); }} style={{ background: "#2c1a0a", border: "1px dashed #5a3a1a", borderRadius: 8, padding: "6px 10px", color: "#fde9a0", fontSize: 11, cursor: "pointer" }}>⚙️ Plantillas</button>
              </div>
            </div>

            <div style={{ background: "#2c1a0a", borderRadius: 14, padding: 16, border: "1px solid #5a3a1a", marginBottom: 16 }}>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
                <span style={{ color: "#fde9a0" }}>Total gastos</span>
                <span style={{ color: "#e74c3c", fontWeight: "bold", fontSize: 18 }}>{formatCOP(totalGastos)}</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between" }}>
                <span style={{ color: "#fde9a0" }}>Total ventas</span>
                <span style={{ color: "#2ecc71", fontWeight: "bold", fontSize: 18 }}>{formatCOP(totalVentas)}</span>
              </div>
              <div style={{ borderTop: "1px solid #5a3a1a", marginTop: 12, paddingTop: 12, display: "flex", justifyContent: "space-between" }}>
                <span style={{ color: "#f5c842", fontWeight: "bold" }}>🏆 Ganancia neta</span>
                <span style={{ color: ganancia >= 0 ? "#2ecc71" : "#e74c3c", fontWeight: "bold", fontSize: 20 }}>{formatCOP(ganancia)}</span>
              </div>
            </div>

            {expenses.length === 0 && (
              <div style={{ textAlign: "center", color: "#5a3a1a", padding: 40, fontSize: 14 }}>Sin gastos registrados hoy</div>
            )}

            {expenses.map((e, i) => (
              <div key={i} style={{ background: "#2c1a0a", borderRadius: 12, padding: "12px 16px", border: "1px solid #5a3a1a", marginBottom: 8, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <div>
                  <div style={{ color: "#fde9a0", fontWeight: "bold", fontSize: 14 }}>{e.name}</div>
                  <div style={{ display: "flex", gap: 8, marginTop: 2 }}>
                    <span style={{ background: e.type === "fijo" ? "#1a2a4a" : "#2a1a0a", color: e.type === "fijo" ? "#7aaef5" : "#e07b39", fontSize: 10, padding: "2px 8px", borderRadius: 20 }}>{e.type === "fijo" ? "Fijo" : "Variable"}</span>
                    <span style={{ color: "#7a5a3a", fontSize: 11 }}>{e.time}</span>
                  </div>
                </div>
                <span style={{ color: "#e74c3c", fontWeight: "bold", fontSize: 16 }}>{formatCOP(e.amount)}</span>
              </div>
            ))}
          </div>
        )}

        {/* REPORTES TAB */}
        {tab === "reportes" && (
          <div>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
              <div style={{ color: "#f5c842", fontWeight: "bold", fontSize: 16 }}>📈 Historial de días</div>
              <button
                onClick={() => window.print()}
                style={{ background: "#2c1a0a", border: "1px solid #5a3a1a", borderRadius: 8, padding: "6px 12px", color: "#fde9a0", fontSize: 12, cursor: "pointer" }}
              >
                🧾 Imprimir / PDF
              </button>
            </div>

            <div style={{ background: "#2c1a0a", borderRadius: 14, padding: 16, border: "1px solid #5a3a1a", marginBottom: 16 }}>
              <div style={{ color: "#fde9a0", fontSize: 13, marginBottom: 4 }}>
                Se muestran hasta los últimos 7 días con datos guardados en este dispositivo.
              </div>
              {reportLoading && (
                <div style={{ color: "#f5c842", fontSize: 14, paddingTop: 10 }}>Cargando reportes...</div>
              )}
              {!reportLoading && reportDays.length === 0 && (
                <div style={{ color: "#5a3a1a", fontSize: 14, paddingTop: 10 }}>Aún no hay días históricos registrados.</div>
              )}
              {!reportLoading && reportDays.length > 0 && (
                <div>
                  {reportDays.map((d, i) => (
                    <div
                      key={d.day}
                      style={{
                        padding: "10px 0",
                        borderBottom: i < reportDays.length - 1 ? "1px solid #3d2510" : "none",
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "center",
                      }}
                    >
                      <div>
                        <div style={{ color: "#f5c842", fontWeight: "bold", fontSize: 14 }}>
                          {new Date(d.day + "T00:00:00").toLocaleDateString("es-CO", {
                            weekday: "short",
                            day: "2-digit",
                            month: "short",
                          })}
                        </div>
                        <div style={{ color: "#7a5a3a", fontSize: 11 }}>Ganancia neta del día</div>
                      </div>
                      <div style={{ textAlign: "right" }}>
                        <div style={{ color: "#2ecc71", fontWeight: "bold", fontSize: 15 }}>
                          Ventas: {formatCOP(d.totalVentas)}
                        </div>
                        <div style={{ color: "#e74c3c", fontWeight: "bold", fontSize: 13 }}>
                          Gastos: {formatCOP(d.totalGastos)}
                        </div>
                        <div
                          style={{
                            marginTop: 4,
                            color: d.ganancia >= 0 ? "#2ecc71" : "#e74c3c",
                            fontWeight: "bold",
                            fontSize: 16,
                          }}
                        >
                          {formatCOP(d.ganancia)}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}
      </div>

      {/* Bottom Nav */}
      <div style={{ position: "fixed", bottom: 0, left: "50%", transform: "translateX(-50%)", width: "100%", maxWidth: 480, background: "#0f0500", borderTop: "2px solid #922b21", display: "flex" }}>
        {[
          { id: "ventas", label: "Ventas", icon: "🌭" },
          { id: "inventario", label: "Inventario", icon: "📦" },
          { id: "gastos", label: "Gastos", icon: "💸" },
          { id: "reportes", label: "Reportes", icon: "📈" },
        ].map(t => (
          <button key={t.id} onClick={() => setTab(t.id)} style={{ flex: 1, background: "none", border: "none", padding: "12px 0", cursor: "pointer", display: "flex", flexDirection: "column", alignItems: "center", gap: 2 }}>
            <span style={{ fontSize: 22 }}>{t.icon}</span>
            <span style={{ color: tab === t.id ? "#f5c842" : "#5a3a1a", fontSize: 11, fontWeight: tab === t.id ? "bold" : "normal" }}>{t.label}</span>
            {tab === t.id && <div style={{ width: 20, height: 2, background: "#f5c842", borderRadius: 2 }} />}
          </button>
        ))}
      </div>

      {/* MODAL: Surtir */}
      {showRestock && (
        <div style={{ position: "fixed", inset: 0, background: "#000a", zIndex: 100, display: "flex", alignItems: "flex-end", justifyContent: "center" }}>
          <div style={{ background: "#1a0a00", border: "2px solid #922b21", borderRadius: "20px 20px 0 0", padding: 24, width: "100%", maxWidth: 480 }}>
            <div style={{ color: "#f5c842", fontWeight: "bold", fontSize: 17, marginBottom: 16 }}>📦 Registrar surtido</div>
            {ingredientFields.map(f => (
              <div key={f.key} style={{ marginBottom: 12 }}>
                <div style={{ color: "#fde9a0", fontSize: 13, marginBottom: 4 }}>{f.label} (tienes: {inventory[f.key] || 0})</div>
                <input type="number" placeholder="Cantidad a agregar" value={restockValues[f.key] || ""} onChange={e => setRestockValues(v => ({ ...v, [f.key]: e.target.value }))}
                  style={{ width: "100%", background: "#2c1a0a", border: "1px solid #5a3a1a", borderRadius: 8, padding: "10px 12px", color: "#fff", fontSize: 15, boxSizing: "border-box" }} />
              </div>
            ))}
            <div style={{ display: "flex", gap: 10, marginTop: 16 }}>
              <button onClick={() => setShowRestock(false)} style={{ flex: 1, background: "#2c1a0a", border: "1px solid #5a3a1a", borderRadius: 10, padding: 12, color: "#fde9a0", cursor: "pointer", fontSize: 14 }}>Cancelar</button>
              <button onClick={applyRestock} style={{ flex: 2, background: "#c0392b", border: "none", borderRadius: 10, padding: 12, color: "#fff", fontWeight: "bold", cursor: "pointer", fontSize: 15 }}>✅ Confirmar surtido</button>
            </div>
          </div>
        </div>
      )}

      {/* MODAL: Editar inventario */}
      {showInvEdit && (
        <div style={{ position: "fixed", inset: 0, background: "#000a", zIndex: 100, display: "flex", alignItems: "flex-end", justifyContent: "center" }}>
          <div style={{ background: "#1a0a00", border: "2px solid #922b21", borderRadius: "20px 20px 0 0", padding: 24, width: "100%", maxWidth: 480 }}>
            <div style={{ color: "#f5c842", fontWeight: "bold", fontSize: 17, marginBottom: 4 }}>✏️ Editar inventario</div>
            <div style={{ color: "#7a5a3a", fontSize: 12, marginBottom: 16 }}>Ajusta el conteo al cierre del día</div>
            {ingredientFields.map(f => (
              <div key={f.key} style={{ marginBottom: 12 }}>
                <div style={{ color: "#fde9a0", fontSize: 13, marginBottom: 4 }}>{f.label}</div>
                <input type="number" value={invEditValues[f.key] || 0} onChange={e => setInvEditValues(v => ({ ...v, [f.key]: parseInt(e.target.value) || 0 }))}
                  style={{ width: "100%", background: "#2c1a0a", border: "1px solid #5a3a1a", borderRadius: 8, padding: "10px 12px", color: "#fff", fontSize: 15, boxSizing: "border-box" }} />
              </div>
            ))}
            <div style={{ display: "flex", gap: 10, marginTop: 16 }}>
              <button onClick={() => setShowInvEdit(false)} style={{ flex: 1, background: "#2c1a0a", border: "1px solid #5a3a1a", borderRadius: 10, padding: 12, color: "#fde9a0", cursor: "pointer", fontSize: 14 }}>Cancelar</button>
              <button onClick={applyInvEdit} style={{ flex: 2, background: "#c0392b", border: "none", borderRadius: 10, padding: 12, color: "#fff", fontWeight: "bold", cursor: "pointer", fontSize: 15 }}>✅ Guardar</button>
            </div>
          </div>
        </div>
      )}

      {/* MODAL: Config productos */}
      {showProdConfig && (
        <div style={{ position: "fixed", inset: 0, background: "#000a", zIndex: 115, display: "flex", alignItems: "flex-end", justifyContent: "center" }}>
          <div style={{ background: "#1a0a00", border: "2px solid #922b21", borderRadius: "20px 20px 0 0", padding: 24, width: "100%", maxWidth: 480, maxHeight: "90vh", overflowY: "auto" }}>
            <div style={{ color: "#f5c842", fontWeight: "bold", fontSize: 17, marginBottom: 4 }}>⚙️ Productos</div>
            <div style={{ color: "#7a5a3a", fontSize: 12, marginBottom: 12 }}>
              Aquí puedes agregar, quitar o editar tus perros. Los campos de cantidades usan salchichas, panes y bebidas del inventario.
            </div>
            {prodDraft.map((p, index) => (
              <div key={p.id || index} style={{ border: "1px solid #5a3a1a", borderRadius: 10, padding: 10, marginBottom: 10, background: "#2c1a0a" }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 6 }}>
                  <input
                    value={p.name}
                    onChange={e => {
                      const value = e.target.value;
                      setProdDraft(list => list.map((it, i) => i === index ? { ...it, name: value } : it));
                    }}
                    placeholder="Nombre (ej: Sencillo)"
                    style={{ flex: 1, background: "#1a0a00", border: "1px solid #5a3a1a", borderRadius: 6, padding: "6px 8px", color: "#fff", fontSize: 13, marginRight: 6 }}
                  />
                  <input
                    value={p.emoji}
                    onChange={e => {
                      const value = e.target.value;
                      setProdDraft(list => list.map((it, i) => i === index ? { ...it, emoji: value } : it));
                    }}
                    maxLength={4}
                    style={{ width: 40, textAlign: "center", background: "#1a0a00", border: "1px solid #5a3a1a", borderRadius: 6, padding: "6px 4px", color: "#fff", fontSize: 18, marginRight: 6 }}
                  />
                  <button
                    onClick={() => setProdDraft(list => list.filter((_, i) => i !== index))}
                    style={{ background: "none", border: "none", color: "#e74c3c", fontSize: 16, cursor: "pointer" }}
                  >
                    ✕
                  </button>
                </div>
                <div style={{ display: "flex", gap: 6, marginBottom: 6 }}>
                  <div style={{ flex: 1 }}>
                    <div style={{ color: "#fde9a0", fontSize: 11, marginBottom: 2 }}>Precio</div>
                    <input
                      type="number"
                      value={p.price}
                      onChange={e => {
                        const value = e.target.value;
                        setProdDraft(list => list.map((it, i) => i === index ? { ...it, price: Number(value) } : it));
                      }}
                      style={{ width: "100%", background: "#1a0a00", border: "1px solid #5a3a1a", borderRadius: 6, padding: "6px 8px", color: "#fff", fontSize: 13 }}
                    />
                  </div>
                  <div style={{ flex: 1 }}>
                    <div style={{ color: "#fde9a0", fontSize: 11, marginBottom: 2 }}>Salchichas</div>
                    <input
                      type="number"
                      value={p.salchichas}
                      onChange={e => {
                        const value = e.target.value;
                        setProdDraft(list => list.map((it, i) => i === index ? { ...it, salchichas: Number(value) } : it));
                      }}
                      style={{ width: "100%", background: "#1a0a00", border: "1px solid #5a3a1a", borderRadius: 6, padding: "6px 8px", color: "#fff", fontSize: 13 }}
                    />
                  </div>
                  <div style={{ flex: 1 }}>
                    <div style={{ color: "#fde9a0", fontSize: 11, marginBottom: 2 }}>Panes</div>
                    <input
                      type="number"
                      value={p.panes}
                      onChange={e => {
                        const value = e.target.value;
                        setProdDraft(list => list.map((it, i) => i === index ? { ...it, panes: Number(value) } : it));
                      }}
                      style={{ width: "100%", background: "#1a0a00", border: "1px solid #5a3a1a", borderRadius: 6, padding: "6px 8px", color: "#fff", fontSize: 13 }}
                    />
                  </div>
                  <div style={{ flex: 1 }}>
                    <div style={{ color: "#fde9a0", fontSize: 11, marginBottom: 2 }}>Bebidas</div>
                    <input
                      type="number"
                      value={p.bebidas}
                      onChange={e => {
                        const value = e.target.value;
                        setProdDraft(list => list.map((it, i) => i === index ? { ...it, bebidas: Number(value) } : it));
                      }}
                      style={{ width: "100%", background: "#1a0a00", border: "1px solid #5a3a1a", borderRadius: 6, padding: "6px 8px", color: "#fff", fontSize: 13 }}
                    />
                  </div>
                </div>
              </div>
            ))}
            <button
              onClick={handleAddProductRow}
              style={{ width: "100%", marginTop: 4, background: "#2c1a0a", border: "1px dashed #5a3a1a", borderRadius: 10, padding: 10, color: "#fde9a0", cursor: "pointer", fontSize: 13 }}
            >
              + Agregar producto
            </button>
            <div style={{ display: "flex", gap: 10, marginTop: 16 }}>
              <button onClick={() => setShowProdConfig(false)} style={{ flex: 1, background: "#2c1a0a", border: "1px solid #5a3a1a", borderRadius: 10, padding: 12, color: "#fde9a0", cursor: "pointer", fontSize: 14 }}>Cancelar</button>
              <button onClick={handleSaveProducts} style={{ flex: 2, background: "#c0392b", border: "none", borderRadius: 10, padding: 12, color: "#fff", fontWeight: "bold", cursor: "pointer", fontSize: 15 }}>✅ Guardar productos</button>
            </div>
          </div>
        </div>
      )}

      {/* MODAL: Config inventario */}
      {showInvConfig && (
        <div style={{ position: "fixed", inset: 0, background: "#000a", zIndex: 120, display: "flex", alignItems: "flex-end", justifyContent: "center" }}>
          <div style={{ background: "#1a0a00", border: "2px solid #922b21", borderRadius: "20px 20px 0 0", padding: 24, width: "100%", maxWidth: 480 }}>
            <div style={{ color: "#f5c842", fontWeight: "bold", fontSize: 17, marginBottom: 4 }}>⚙️ Campos de inventario</div>
            <div style={{ color: "#7a5a3a", fontSize: 12, marginBottom: 12 }}>
              Escribe un campo por línea (ej: Salchichas, Panes, Bebidas...). Puedes quitar o agregar los que quieras.
            </div>
            <textarea
              value={invFieldsText}
              onChange={e => setInvFieldsText(e.target.value)}
              rows={6}
              style={{ width: "100%", background: "#2c1a0a", border: "1px solid #5a3a1a", borderRadius: 10, padding: "10px 12px", color: "#fff", fontSize: 14, resize: "vertical", boxSizing: "border-box" }}
            />
            <div style={{ display: "flex", gap: 10, marginTop: 16 }}>
              <button onClick={() => setShowInvConfig(false)} style={{ flex: 1, background: "#2c1a0a", border: "1px solid #5a3a1a", borderRadius: 10, padding: 12, color: "#fde9a0", cursor: "pointer", fontSize: 14 }}>Cancelar</button>
              <button onClick={handleSaveInvFields} style={{ flex: 2, background: "#c0392b", border: "none", borderRadius: 10, padding: 12, color: "#fff", fontWeight: "bold", cursor: "pointer", fontSize: 15 }}>✅ Guardar campos</button>
            </div>
          </div>
        </div>
      )}

      {/* MODAL: Config gastos */}
      {showExpenseConfig && (
        <div style={{ position: "fixed", inset: 0, background: "#000a", zIndex: 120, display: "flex", alignItems: "flex-end", justifyContent: "center" }}>
          <div style={{ background: "#1a0a00", border: "2px solid #922b21", borderRadius: "20px 20px 0 0", padding: 24, width: "100%", maxWidth: 480 }}>
            <div style={{ color: "#f5c842", fontWeight: "bold", fontSize: 17, marginBottom: 4 }}>⚙️ Plantillas de gastos</div>
            <div style={{ color: "#7a5a3a", fontSize: 12, marginBottom: 12 }}>
              Escribe una opción por línea (ej: Gas, Arriendo, Transporte...). Estas aparecen como botones rápidos.
            </div>
            <textarea
              value={expenseTemplatesText}
              onChange={e => setExpenseTemplatesText(e.target.value)}
              rows={6}
              style={{ width: "100%", background: "#2c1a0a", border: "1px solid #5a3a1a", borderRadius: 10, padding: "10px 12px", color: "#fff", fontSize: 14, resize: "vertical", boxSizing: "border-box" }}
            />
            <div style={{ display: "flex", gap: 10, marginTop: 16 }}>
              <button onClick={() => setShowExpenseConfig(false)} style={{ flex: 1, background: "#2c1a0a", border: "1px solid #5a3a1a", borderRadius: 10, padding: 12, color: "#fde9a0", cursor: "pointer", fontSize: 14 }}>Cancelar</button>
              <button onClick={handleSaveExpenseTemplates} style={{ flex: 2, background: "#c0392b", border: "none", borderRadius: 10, padding: 12, color: "#fff", fontWeight: "bold", cursor: "pointer", fontSize: 15 }}>✅ Guardar plantillas</button>
            </div>
          </div>
        </div>
      )}

      {/* MODAL: Config logo */}
      {showLogoConfig && (
        <div style={{ position: "fixed", inset: 0, background: "#000a", zIndex: 130, display: "flex", alignItems: "flex-end", justifyContent: "center" }}>
          <div style={{ background: "#1a0a00", border: "2px solid #922b21", borderRadius: "20px 20px 0 0", padding: 24, width: "100%", maxWidth: 480 }}>
            <div style={{ color: "#f5c842", fontWeight: "bold", fontSize: 17, marginBottom: 4 }}>🖼 Logo de Perrito Perrón</div>
            <div style={{ color: "#7a5a3a", fontSize: 12, marginBottom: 12 }}>
              Pega aquí la URL de tu logo (por ejemplo una imagen subida a tu hosting o a un CDN). Se verá en la parte superior.
            </div>
            <input
              value={logoInput}
              onChange={e => setLogoInput(e.target.value)}
              placeholder="https://.../mi-logo.png"
              style={{ width: "100%", background: "#2c1a0a", border: "1px solid #5a3a1a", borderRadius: 8, padding: "10px 12px", color: "#fff", fontSize: 14, boxSizing: "border-box", marginBottom: 16 }}
            />
            <div style={{ display: "flex", gap: 10 }}>
              <button onClick={() => setShowLogoConfig(false)} style={{ flex: 1, background: "#2c1a0a", border: "1px solid #5a3a1a", borderRadius: 10, padding: 12, color: "#fde9a0", cursor: "pointer", fontSize: 14 }}>Cancelar</button>
              <button
                onClick={() => {
                  setLogoUrl(logoInput.trim());
                  storage.set("logo_url", logoInput.trim());
                  setShowLogoConfig(false);
                }}
                style={{ flex: 2, background: "#c0392b", border: "none", borderRadius: 10, padding: 12, color: "#fff", fontWeight: "bold", cursor: "pointer", fontSize: 15 }}
              >
                ✅ Guardar logo
              </button>
            </div>
          </div>
        </div>
      )}

      {/* MODAL: Gasto */}
      {showExpense && (
        <div style={{ position: "fixed", inset: 0, background: "#000a", zIndex: 100, display: "flex", alignItems: "flex-end", justifyContent: "center" }}>
          <div style={{ background: "#1a0a00", border: "2px solid #922b21", borderRadius: "20px 20px 0 0", padding: 24, width: "100%", maxWidth: 480 }}>
            <div style={{ color: "#f5c842", fontWeight: "bold", fontSize: 17, marginBottom: 16 }}>💸 Registrar gasto</div>
            <div style={{ color: "#fde9a0", fontSize: 13, marginBottom: 6 }}>Tipo de gasto</div>
            <div style={{ display: "flex", gap: 8, marginBottom: 14 }}>
              {["variable", "fijo"].map(t => (
                <button key={t} onClick={() => setExpType(t)} style={{ flex: 1, background: expType === t ? "#c0392b" : "#2c1a0a", border: "1px solid #5a3a1a", borderRadius: 8, padding: "8px", color: expType === t ? "#fff" : "#fde9a0", cursor: "pointer", fontSize: 14 }}>
                  {t === "fijo" ? "🏠 Fijo" : "🛒 Variable"}
                </button>
              ))}
            </div>
            <div style={{ color: "#fde9a0", fontSize: 13, marginBottom: 6 }}>Descripción</div>
            <div style={{ display: "flex", flexWrap: "wrap", gap: 6, marginBottom: 10 }}>
              {expenseTemplates.map(op => (
                <button key={op} onClick={() => setExpName(op)} style={{ background: expName === op ? "#922b21" : "#2c1a0a", border: "1px solid #5a3a1a", borderRadius: 20, padding: "4px 12px", color: "#fde9a0", cursor: "pointer", fontSize: 12 }}>{op}</button>
              ))}
            </div>
            <input value={expName} onChange={e => setExpName(e.target.value)} placeholder="O escribe el nombre del gasto"
              style={{ width: "100%", background: "#2c1a0a", border: "1px solid #5a3a1a", borderRadius: 8, padding: "10px 12px", color: "#fff", fontSize: 15, marginBottom: 12, boxSizing: "border-box" }} />
            <div style={{ color: "#fde9a0", fontSize: 13, marginBottom: 6 }}>Monto (COP)</div>
            <input type="number" value={expAmount} onChange={e => setExpAmount(e.target.value)} placeholder="Ej: 15000"
              style={{ width: "100%", background: "#2c1a0a", border: "1px solid #5a3a1a", borderRadius: 8, padding: "10px 12px", color: "#fff", fontSize: 15, marginBottom: 16, boxSizing: "border-box" }} />
            <div style={{ display: "flex", gap: 10 }}>
              <button onClick={() => setShowExpense(false)} style={{ flex: 1, background: "#2c1a0a", border: "1px solid #5a3a1a", borderRadius: 10, padding: 12, color: "#fde9a0", cursor: "pointer", fontSize: 14 }}>Cancelar</button>
              <button onClick={addExpense} style={{ flex: 2, background: "#c0392b", border: "none", borderRadius: 10, padding: 12, color: "#fff", fontWeight: "bold", cursor: "pointer", fontSize: 15 }}>✅ Guardar gasto</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default App;
