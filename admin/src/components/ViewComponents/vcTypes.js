/**
 * Shared helpers for ViewComponents.
 * Each component receives the raw DB-backed `component` object:
 *   { type, input_values, children, uuid, id, ... }
 */

export function getComponentKey(component) {
  return component?.uuid || component?.id || component?.key;
}

export function coerceBoolean(v, fallback = false) {
  if (typeof v === "boolean") return v;
  if (typeof v === "number") return v !== 0;
  if (typeof v === "string") {
    const s = v.trim().toLowerCase();
    if (["true", "1", "yes", "y", "on"].includes(s)) return true;
    if (["false", "0", "no", "n", "off"].includes(s)) return false;
  }
  return fallback;
}

export function coerceNumber(v, fallback = undefined) {
  if (typeof v === "number") return v;
  if (typeof v === "string" && v.trim() !== "") {
    const n = Number(v);
    return Number.isFinite(n) ? n : fallback;
  }
  return fallback;
}

export function normalizeOptions(options) {
  if (!options) return [];
  if (Array.isArray(options)) {
    return options.map((opt) => {
      if (opt && typeof opt === "object") {
        const value = opt.value ?? opt.key ?? opt.id ?? opt.label;
        const label = opt.label ?? String(value ?? "");
        return { value, label };
      }
      return { value: opt, label: String(opt) };
    });
  }

  // Accept "a,b,c" string as options
  if (typeof options === "string") {
    return options
      .split(",")
      .map((s) => s.trim())
      .filter(Boolean)
      .map((s) => ({ value: s, label: s }));
  }

  return [];
}

