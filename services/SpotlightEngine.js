// =============================================================================
// SpotlightEngine.js - Universal Math, Conversion, Palette & Glyph Inspector
// For Antigravity Omnibar (Super + K)
// =============================================================================

.pragma library

// ── 1. CURRENCY EXCHANGE RATES (USD Base) ───────────────────────────────────
var currencyRates = {
    "usd": 1.0,
    "inr": 86.85,
    "eur": 0.96,
    "gbp": 0.81,
    "jpy": 154.20,
    "cad": 1.41,
    "aud": 1.58,
    "cny": 7.28,
    "aed": 3.67,
    "chf": 0.90,
    "sgd": 1.35,
    "rub": 98.50,
    "krw": 1420.0,
    "brl": 5.80,
    "mxn": 20.40
};

var currencySymbols = {
    "usd": "$",
    "inr": "₹",
    "eur": "€",
    "gbp": "£",
    "jpy": "¥",
    "cny": "¥",
    "cad": "CA$",
    "aud": "A$",
    "aed": "AED",
    "chf": "CHF",
    "sgd": "S$"
};

// ── 2. UNIT CONVERSION TABLES ───────────────────────────────────────────────
var digitalUnits = {
    "b": 1, "byte": 1, "bytes": 1,
    "kb": 1024, "kilobyte": 1024, "kilobytes": 1024,
    "mb": 1024 * 1024, "megabyte": 1024 * 1024, "megabytes": 1024 * 1024,
    "gb": 1024 * 1024 * 1024, "gigabyte": 1024 * 1024 * 1024, "gigabytes": 1024 * 1024 * 1024,
    "tb": 1024 * 1024 * 1024 * 1024, "terabyte": 1024 * 1024 * 1024 * 1024,
    "pb": 1024 * 1024 * 1024 * 1024 * 1024
};

var lengthUnits = {
    "mm": 0.001, "millimeter": 0.001, "millimeters": 0.001,
    "cm": 0.01, "centimeter": 0.01, "centimeters": 0.01,
    "m": 1.0, "meter": 1.0, "meters": 1.0,
    "km": 1000.0, "kilometer": 1000.0, "kilometers": 1000.0,
    "in": 0.0254, "inch": 0.0254, "inches": 0.0254,
    "ft": 0.3048, "foot": 0.3048, "feet": 0.3048,
    "yd": 0.9144, "yard": 0.9144, "yards": 0.9144,
    "mi": 1609.344, "mile": 1609.344, "miles": 1609.344
};

var massUnits = {
    "mg": 0.001, "milligram": 0.001,
    "g": 1.0, "gram": 1.0, "grams": 1.0,
    "kg": 1000.0, "kilogram": 1000.0, "kilograms": 1000.0,
    "oz": 28.3495, "ounce": 28.3495, "ounces": 28.3495,
    "lb": 453.592, "lbs": 453.592, "pound": 453.592, "pounds": 453.592,
    "ton": 1000000.0, "tonne": 1000000.0, "tons": 1000000.0
};

var speedUnits = {
    "m/s": 1.0, "mps": 1.0,
    "km/h": 0.277778, "kph": 0.277778,
    "mph": 0.44704,
    "knot": 0.514444, "knots": 0.514444
};

// ── 3. WORLD CITIES TIMEZONE DICTIONARY ─────────────────────────────────────
var cityTimezones = {
    "tokyo": { tz: "Asia/Tokyo", name: "Tokyo, Japan", flag: "🇯🇵" },
    "kyoto": { tz: "Asia/Tokyo", name: "Kyoto, Japan", flag: "🇯🇵" },
    "london": { tz: "Europe/London", name: "London, UK", flag: "🇬🇧" },
    "new york": { tz: "America/New_York", name: "New York, USA", flag: "🇺🇸" },
    "nyc": { tz: "America/New_York", name: "New York, USA", flag: "🇺🇸" },
    "san francisco": { tz: "America/Los_Angeles", name: "San Francisco, USA", flag: "🇺🇸" },
    "sf": { tz: "America/Los_Angeles", name: "San Francisco, USA", flag: "🇺🇸" },
    "los angeles": { tz: "America/Los_Angeles", name: "Los Angeles, USA", flag: "🇺🇸" },
    "la": { tz: "America/Los_Angeles", name: "Los Angeles, USA", flag: "🇺🇸" },
    "chicago": { tz: "America/Chicago", name: "Chicago, USA", flag: "🇺🇸" },
    "seattle": { tz: "America/Los_Angeles", name: "Seattle, USA", flag: "🇺🇸" },
    "paris": { tz: "Europe/Paris", name: "Paris, France", flag: "🇫🇷" },
    "berlin": { tz: "Europe/Berlin", name: "Berlin, Germany", flag: "🇩🇪" },
    "amsterdam": { tz: "Europe/Amsterdam", name: "Amsterdam, Netherlands", flag: "🇳🇱" },
    "dubai": { tz: "Asia/Dubai", name: "Dubai, UAE", flag: "🇦🇪" },
    "singapore": { tz: "Asia/Singapore", name: "Singapore", flag: "🇸🇬" },
    "hong kong": { tz: "Asia/Hong_Kong", name: "Hong Kong", flag: "🇭🇰" },
    "sydney": { tz: "Australia/Sydney", name: "Sydney, Australia", flag: "🇦🇺" },
    "melbourne": { tz: "Australia/Melbourne", name: "Melbourne, Australia", flag: "🇦🇺" },
    "toronto": { tz: "America/Toronto", name: "Toronto, Canada", flag: "🇨🇦" },
    "vancouver": { tz: "America/Vancouver", name: "Vancouver, Canada", flag: "🇨🇦" },
    "bangalore": { tz: "Asia/Kolkata", name: "Bengaluru, India", flag: "🇮🇳" },
    "mumbai": { tz: "Asia/Kolkata", name: "Mumbai, India", flag: "🇮🇳" },
    "delhi": { tz: "Asia/Kolkata", name: "New Delhi, India", flag: "🇮🇳" },
    "india": { tz: "Asia/Kolkata", name: "India (IST)", flag: "🇮🇳" },
    "utc": { tz: "UTC", name: "UTC / Coordinated Universal Time", flag: "🌐" },
    "gmt": { tz: "UTC", name: "GMT / Greenwich Mean Time", flag: "🌐" }
};

// ── 4. GLYPH & SYMBOL CATALOGUE ────────────────────────────────────────────
var symbolLibrary = [
    // Arrows
    { char: "→", name: "Right Arrow", tag: "arrow", code: ":arrow_right:" },
    { char: "←", name: "Left Arrow", tag: "arrow", code: ":arrow_left:" },
    { char: "↑", name: "Up Arrow", tag: "arrow", code: ":arrow_up:" },
    { char: "↓", name: "Down Arrow", tag: "arrow", code: ":arrow_down:" },
    { char: "↔", name: "Left-Right Arrow", tag: "arrow", code: ":arrow_lr:" },
    { char: "⇒", name: "Implies / Double Arrow", tag: "arrow", code: ":implies:" },
    { char: "⇐", name: "Implied By", tag: "arrow", code: ":implied_by:" },
    { char: "⇔", name: "Equivalent", tag: "arrow", code: ":iff:" },
    { char: "➔", name: "Heavy Arrow", tag: "arrow", code: ":heavy_arrow:" },
    { char: "➜", name: "Round Arrow", tag: "arrow", code: ":round_arrow:" },

    // Math & Engineering
    { char: "✓", name: "Check / Tick", tag: "math", code: ":check:" },
    { char: "✕", name: "Cross / X", tag: "math", code: ":cross:" },
    { char: "★", name: "Star", tag: "math", code: ":star:" },
    { char: "☆", name: "Empty Star", tag: "math", code: ":star_empty:" },
    { char: "•", name: "Bullet Point", tag: "math", code: ":bullet:" },
    { char: "±", name: "Plus-Minus", tag: "math", code: ":plusminus:" },
    { char: "≈", name: "Approximately Equal", tag: "math", code: ":approx:" },
    { char: "≠", name: "Not Equal", tag: "math", code: ":neq:" },
    { char: "≤", name: "Less Than or Equal", tag: "math", code: ":leq:" },
    { char: "≥", name: "Greater Than or Equal", tag: "math", code: ":geq:" },
    { char: "∞", name: "Infinity", tag: "math", code: ":inf:" },
    { char: "π", name: "Pi", tag: "math", code: ":pi:" },
    { char: "λ", name: "Lambda", tag: "math", code: ":lambda:" },
    { char: "∑", name: "Summation", tag: "math", code: ":sum:" },
    { char: "√", name: "Square Root", tag: "math", code: ":sqrt:" },
    { char: "∫", name: "Integral", tag: "math", code: ":int:" },
    { char: "∂", name: "Partial Derivative", tag: "math", code: ":partial:" },
    { char: "°", name: "Degree", tag: "math", code: ":deg:" },

    // Tech & Keyboard Modifiers
    { char: "⌘", name: "Command / Place of Interest", tag: "keyboard", code: ":cmd:" },
    { char: "⌥", name: "Option / Alt", tag: "keyboard", code: ":opt:" },
    { char: "⇧", name: "Shift", tag: "keyboard", code: ":shift:" },
    { char: "⌃", name: "Control", tag: "keyboard", code: ":ctrl:" },
    { char: "⎋", name: "Escape", tag: "keyboard", code: ":esc:" },
    { char: "↵", name: "Return / Enter", tag: "keyboard", code: ":return:" },
    { char: "⌫", name: "Backspace", tag: "keyboard", code: ":backspace:" },
    { char: "⇥", name: "Tab", tag: "keyboard", code: ":tab:" },

    // Popular Emojis
    { char: "🔥", name: "Fire / Lit", tag: "emoji", code: ":fire:" },
    { char: "🚀", name: "Rocket / Launch", tag: "emoji", code: ":rocket:" },
    { char: "✨", name: "Sparkles / Magic", tag: "emoji", code: ":sparkles:" },
    { char: "⚡", name: "Zap / High Voltage", tag: "emoji", code: ":zap:" },
    { char: "💡", name: "Lightbulb / Idea", tag: "emoji", code: ":bulb:" },
    { char: "🎯", name: "Bullseye / Target", tag: "emoji", code: ":target:" },
    { char: "📦", name: "Package / Box", tag: "emoji", code: ":package:" },
    { char: "🐛", name: "Bug / Issue", tag: "emoji", code: ":bug:" },
    { char: "🔒", name: "Lock / Security", tag: "emoji", code: ":lock:" },
    { char: "🔑", name: "Key / Auth", tag: "emoji", code: ":key:" },
    { char: "💻", name: "Laptop / Dev", tag: "emoji", code: ":laptop:" },
    { char: "🎨", name: "Art / Palette", tag: "emoji", code: ":art:" },
    { char: "🤖", name: "Robot / AI", tag: "emoji", code: ":robot:" },
    { char: "💬", name: "Chat / Speech", tag: "emoji", code: ":chat:" },
    { char: "❤️", name: "Red Heart", tag: "emoji", code: ":heart:" },
    { char: "👍", name: "Thumbs Up", tag: "emoji", code: ":thumbsup:" },
    { char: "🎉", name: "Party Popper / Tada", tag: "emoji", code: ":tada:" },
    { char: "☕", name: "Coffee / Break", tag: "emoji", code: ":coffee:" },
    { char: "🍕", name: "Pizza", tag: "emoji", code: ":pizza:" },
    { char: "🧠", name: "Brain / Thinking", tag: "emoji", code: ":brain:" },
    { char: "🏆", name: "Trophy / Winner", tag: "emoji", code: ":trophy:" },
    { char: "⏳", name: "Hourglass / Loading", tag: "emoji", code: ":hourglass:" }
];

// ── 5. EVALUATE FUNCTIONS ──────────────────────────────────────────────────

function formatNumber(num) {
    if (isNaN(num)) return "0";
    if (Math.abs(num) >= 1e9 || (Math.abs(num) < 0.0001 && num !== 0)) {
        return num.toExponential(4);
    }
    // Round to max 6 decimals
    const rounded = Math.round(num * 1000000) / 1000000;
    const parts = rounded.toString().split(".");
    parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    return parts.join(".");
}

// 5A. Math Evaluation
function evaluateMath(raw) {
    let expr = raw.trim();
    // Quick reject if letters exist (unless it is a known math func like sqrt, sin, cos, tan, abs, log, pi, e)
    const sanitized = expr
        .replace(/×/g, "*")
        .replace(/÷/g, "/")
        .replace(/\^/g, "**")
        .replace(/(\d+(?:\.\d+)?)%\s*of\s*([\d\.]+)/gi, "(($1 / 100) * $2)")
        .replace(/(\d+(?:\.\d+)?)%/g, "($1 / 100)");

    // Safety check: only allow digits, operators, parentheses, and math functions
    const validChars = /^[0-9\s\+\-\*\/\(\)\.\,\%\!\^eE\s]|sqrt|cbrt|sin|cos|tan|log|abs|round|floor|ceil|min|max|pi|PI/i;
    // Strip allowed tokens
    const testStr = sanitized
        .replace(/sqrt|cbrt|sin|cos|tan|log|abs|round|floor|ceil|min|max|pi|PI/gi, "")
        .replace(/[0-9\s\+\-\*\/\(\)\.\,\%\!\^]/g, "");

    if (testStr.length > 0) return null;

    // Check that there is at least one operator or function or calculation
    if (!/[\+\-\*\/\^%]/.test(sanitized) && !/sqrt|sin|cos|tan|log/i.test(sanitized)) {
        return null;
    }

    try {
        // Expand Math functions
        const code = sanitized
            .replace(/sqrt/gi, "Math.sqrt")
            .replace(/cbrt/gi, "Math.cbrt")
            .replace(/sin/gi, "Math.sin")
            .replace(/cos/gi, "Math.cos")
            .replace(/tan/gi, "Math.tan")
            .replace(/log/gi, "Math.log10")
            .replace(/abs/gi, "Math.abs")
            .replace(/pi/gi, "Math.PI");

        const res = Function('"use strict"; return (' + code + ');')();
        if (typeof res === "number" && isFinite(res)) {
            return {
                mode: "math",
                icon: "🧮",
                lucide: "code",
                title: "CALCULATION RESULT",
                expression: expr,
                result: formatNumber(res),
                rawResult: res.toString(),
                copyValue: res.toString()
            };
        }
    } catch (e) {
        return null;
    }
    return null;
}

// 5B. Unit & Currency Conversion
function evaluateConversion(raw) {
    const q = raw.trim();

    // Pattern 1: <number> <unit1> (to|in|as) <unit2>
    const m = q.match(/^([\d\.\,]+)\s*([a-zA-Z\/\$€£₹]+)\s+(?:in|to|as)\s+([a-zA-Z\/\$€£₹]+)$/i);
    if (!m) return null;

    const valStr = m[1].replace(/,/g, "");
    const val = parseFloat(valStr);
    if (isNaN(val)) return null;

    let u1 = m[2].toLowerCase();
    let u2 = m[3].toLowerCase();

    // Symbol to code mapping
    if (u1 === "$") u1 = "usd";
    if (u2 === "$") u2 = "usd";
    if (u1 === "₹") u1 = "inr";
    if (u2 === "₹") u2 = "inr";
    if (u1 === "€") u1 = "eur";
    if (u2 === "€") u2 = "eur";
    if (u1 === "£") u1 = "gbp";
    if (u2 === "£") u2 = "gbp";
    if (u1 === "¥") u1 = "jpy";
    if (u2 === "¥") u2 = "jpy";

    // 1. Temperature conversions
    if ((u1 === "c" || u1 === "celsius") && (u2 === "f" || u2 === "fahrenheit")) {
        const res = (val * 9 / 5) + 32;
        return {
            mode: "conversion",
            icon: "🌡️",
            lucide: "gauge",
            title: "TEMPERATURE CONVERSION",
            expression: val + " °C ➜ °F",
            result: formatNumber(res) + " °F",
            rawResult: res.toString(),
            copyValue: res.toFixed(2)
        };
    }
    if ((u1 === "f" || u1 === "fahrenheit") && (u2 === "c" || u2 === "celsius")) {
        const res = (val - 32) * 5 / 9;
        return {
            mode: "conversion",
            icon: "🌡️",
            lucide: "gauge",
            title: "TEMPERATURE CONVERSION",
            expression: val + " °F ➜ °C",
            result: formatNumber(res) + " °C",
            rawResult: res.toString(),
            copyValue: res.toFixed(2)
        };
    }

    // 2. Currency conversion
    if (currencyRates[u1] !== undefined && currencyRates[u2] !== undefined) {
        const valInUsd = val / currencyRates[u1];
        const res = valInUsd * currencyRates[u2];
        const sym = currencySymbols[u2] || (u2.toUpperCase() + " ");
        return {
            mode: "conversion",
            icon: "💱",
            lucide: "refresh-cw",
            title: "CURRENCY CONVERSION",
            expression: val + " " + u1.toUpperCase() + " ➜ " + u2.toUpperCase(),
            result: sym + " " + formatNumber(res),
            rawResult: res.toFixed(2),
            copyValue: res.toFixed(2)
        };
    }

    // 3. Digital storage
    if (digitalUnits[u1] !== undefined && digitalUnits[u2] !== undefined) {
        const bytes = val * digitalUnits[u1];
        const res = bytes / digitalUnits[u2];
        return {
            mode: "conversion",
            icon: "💾",
            lucide: "hard-drive",
            title: "DIGITAL STORAGE CONVERSION",
            expression: val + " " + u1.toUpperCase() + " ➜ " + u2.toUpperCase(),
            result: formatNumber(res) + " " + u2.toUpperCase(),
            rawResult: res.toString(),
            copyValue: res.toString()
        };
    }

    // 4. Length
    if (lengthUnits[u1] !== undefined && lengthUnits[u2] !== undefined) {
        const meters = val * lengthUnits[u1];
        const res = meters / lengthUnits[u2];
        return {
            mode: "conversion",
            icon: "📏",
            lucide: "sliders",
            title: "LENGTH CONVERSION",
            expression: val + " " + u1 + " ➜ " + u2,
            result: formatNumber(res) + " " + u2,
            rawResult: res.toString(),
            copyValue: res.toString()
        };
    }

    // 5. Mass / Weight
    if (massUnits[u1] !== undefined && massUnits[u2] !== undefined) {
        const grams = val * massUnits[u1];
        const res = grams / massUnits[u2];
        return {
            mode: "conversion",
            icon: "⚖️",
            lucide: "sliders",
            title: "MASS & WEIGHT CONVERSION",
            expression: val + " " + u1 + " ➜ " + u2,
            result: formatNumber(res) + " " + u2,
            rawResult: res.toString(),
            copyValue: res.toString()
        };
    }

    // 6. Speed
    if (speedUnits[u1] !== undefined && speedUnits[u2] !== undefined) {
        const mps = val * speedUnits[u1];
        const res = mps / speedUnits[u2];
        return {
            mode: "conversion",
            icon: "⚡",
            lucide: "gauge",
            title: "SPEED CONVERSION",
            expression: val + " " + u1 + " ➜ " + u2,
            result: formatNumber(res) + " " + u2,
            rawResult: res.toString(),
            copyValue: res.toString()
        };
    }

    return null;
}

// 5C. Time In City
function evaluateTime(raw) {
    const q = raw.trim().toLowerCase();
    const m = q.match(/^(?:what\s+is\s+the\s+)?time\s+(?:in|for|at)\s+([a-zA-Z\s]+)$/);
    if (!m) return null;

    const cityKey = m[1].trim();
    const city = cityTimezones[cityKey];
    if (!city) return null;

    try {
        const now = new Date();
        const timeStr = now.toLocaleTimeString("en-US", { timeZone: city.tz, hour: "numeric", minute: "2-digit", second: "2-digit", hour12: true });
        const dateStr = now.toLocaleDateString("en-US", { timeZone: city.tz, weekday: "short", month: "short", day: "numeric" });

        return {
            mode: "time",
            icon: city.flag || "⏰",
            lucide: "clock",
            title: "WORLD CLOCK // " + city.name.toUpperCase(),
            expression: dateStr + " • " + city.name,
            result: timeStr,
            rawResult: timeStr,
            copyValue: timeStr
        };
    } catch (e) {
        return null;
    }
}

// 5D. Color & Hex Swatch Inspector
function evaluateColor(raw) {
    const q = raw.trim();

    let r = 0, g = 0, b = 0, a = 1.0;
    let hexStr = "";

    // Match Hex: #FFF, #FFFFFF, #FFFFFFFF or without #
    const hexMatch = q.match(/^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/);
    if (hexMatch) {
        let hex = hexMatch[1];
        if (hex.length === 3) {
            hex = hex.split("").map(function(c) { return c + c; }).join("");
        }
        r = parseInt(hex.slice(0, 2), 16);
        g = parseInt(hex.slice(2, 4), 16);
        b = parseInt(hex.slice(4, 6), 16);
        if (hex.length === 8) {
            a = parseInt(hex.slice(6, 8), 16) / 255.0;
        }
        hexStr = "#" + hex.slice(0, 6).toUpperCase();
    } else {
        // Match RGB / RGBA: rgb(56, 189, 248)
        const rgbMatch = q.match(/^rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)(?:\s*,\s*([\d\.]+))?\s*\)$/i);
        if (rgbMatch) {
            r = Math.min(255, Math.max(0, parseInt(rgbMatch[1])));
            g = Math.min(255, Math.max(0, parseInt(rgbMatch[2])));
            b = Math.min(255, Math.max(0, parseInt(rgbMatch[3])));
            if (rgbMatch[4]) a = parseFloat(rgbMatch[4]);
            const toHex = function(n) { return (n < 16 ? "0" : "") + n.toString(16).toUpperCase(); };
            hexStr = "#" + toHex(r) + toHex(g) + toHex(b);
        } else {
            return null;
        }
    }

    // Convert RGB to HSL
    const rNorm = r / 255, gNorm = g / 255, bNorm = b / 255;
    const max = Math.max(rNorm, gNorm, bNorm), min = Math.min(rNorm, gNorm, bNorm);
    let h = 0, s = 0, l = (max + min) / 2;

    if (max !== min) {
        const d = max - min;
        s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
        switch (max) {
            case rNorm: h = (gNorm - bNorm) / d + (gNorm < bNorm ? 6 : 0); break;
            case gNorm: h = (bNorm - rNorm) / d + 2; break;
            case bNorm: h = (rNorm - gNorm) / d + 4; break;
        }
        h /= 6;
    }

    const hDeg = Math.round(h * 360);
    const sPct = Math.round(s * 100);
    const lPct = Math.round(l * 100);

    // Calculate Luminance (Perceived Brightness) for Contrast Text
    const lum = 0.299 * r + 0.587 * g + 0.114 * b;
    const textContrast = lum > 140 ? "#000000" : "#FFFFFF";

    return {
        mode: "color",
        icon: "🎨",
        lucide: "palette",
        title: "COLOR PALETTE INSPECTOR",
        hex: hexStr,
        rgb: "rgb(" + r + ", " + g + ", " + b + ")",
        hsl: "hsl(" + hDeg + ", " + sPct + "%, " + lPct + "%)",
        r: r, g: g, b: b, a: a,
        lum: lum,
        textContrast: textContrast,
        copyValue: hexStr
    };
}

// 5D. Glyphs & Emoji Search
function evaluateGlyphs(raw) {
    const q = raw.trim().toLowerCase();
    if (q.length < 2) return null;

    const isEmojiCode = q.startsWith(":");
    const term = isEmojiCode ? q.slice(1).replace(/:/g, "") : q;
    if (term.length === 0) return null;

    // Filter symbol library
    const matches = symbolLibrary.filter(function(item) {
        if (item.code.toLowerCase().includes(term)) return true;
        if (item.name.toLowerCase().includes(term)) return true;
        if (item.tag.toLowerCase().includes(term)) return true;
        if (item.char === term) return true;
        return false;
    });

    if (matches.length === 0) return null;

    return {
        mode: "glyphs",
        icon: matches[0].char,
        lucide: "sparkles",
        title: "GLYPH & SYMBOL INSPECTOR",
        matches: matches.slice(0, 12),
        primary: matches[0],
        copyValue: matches[0].char
    };
}

// 5E. Programmer Number Base Conversion (hex / dec / bin / oct)
function evaluateBaseConversion(raw) {
    const q = raw.trim().toLowerCase();
    
    // Pattern: 0x... to dec / bin / oct
    const hexMatch = q.match(/^(?:0x)?([0-9a-f]+)\s+(?:in|to|as)\s+(dec|decimal|bin|binary|oct|octal)$/i);
    if (hexMatch && /^[0-9a-f]+$/i.test(hexMatch[1])) {
        const val = parseInt(hexMatch[1], 16);
        if (!isNaN(val)) {
            const target = hexMatch[2].toLowerCase();
            let res = "";
            let title = "";
            if (target.startsWith("dec")) {
                res = val.toString(10);
                title = "HEXADECIMAL ➜ DECIMAL";
            } else if (target.startsWith("bin")) {
                res = "0b" + val.toString(2);
                title = "HEXADECIMAL ➜ BINARY";
            } else {
                res = "0o" + val.toString(8);
                title = "HEXADECIMAL ➜ OCTAL";
            }
            return {
                mode: "math",
                icon: "💻",
                lucide: "binary",
                title: title,
                expression: "0x" + hexMatch[1].toUpperCase() + " ➜ " + target.toUpperCase(),
                result: res,
                rawResult: res,
                copyValue: res
            };
        }
    }

    // Pattern: [0-9]+ to hex / bin / oct
    const decMatch = q.match(/^([0-9]+)\s+(?:in|to|as)\s+(hex|hexadecimal|bin|binary|oct|octal)$/i);
    if (decMatch) {
        const val = parseInt(decMatch[1], 10);
        if (!isNaN(val)) {
            const target = decMatch[2].toLowerCase();
            let res = "";
            let title = "";
            if (target.startsWith("hex")) {
                res = "0x" + val.toString(16).toUpperCase();
                title = "DECIMAL ➜ HEXADECIMAL";
            } else if (target.startsWith("bin")) {
                res = "0b" + val.toString(2);
                title = "DECIMAL ➜ BINARY";
            } else {
                res = "0o" + val.toString(8);
                title = "DECIMAL ➜ OCTAL";
            }
            return {
                mode: "math",
                icon: "💻",
                lucide: "binary",
                title: title,
                expression: decMatch[1] + " ➜ " + target.toUpperCase(),
                result: res,
                rawResult: res,
                copyValue: res
            };
        }
    }

    // Direct standalone hex like 0x7f or 0xDEADBEEF
    if (/^0x[0-9a-f]+$/i.test(q)) {
        const val = parseInt(q.slice(2), 16);
        if (!isNaN(val)) {
            return {
                mode: "math",
                icon: "💻",
                lucide: "binary",
                title: "HEX EVALUATION",
                expression: q.toUpperCase() + " ➜ Decimal",
                result: val.toLocaleString(),
                rawResult: val.toString(),
                copyValue: val.toString()
            };
        }
    }

    return null;
}

// 5F. Smart Web Jump (@gh, @jira, @web)
function evaluateWebJump(raw, context) {
    const q = raw.trim();

    // 0. Screen Area OCR: @ocr
    if (/^(@ocr|ocr)(\s+|$)/i.test(q)) {
        return {
            mode: "action",
            isAction: true,
            isOcr: true,
            title: "Screen Area OCR (Pure Rust)",
            expression: "Select screen area with mouse to extract text and copy to clipboard",
            result: "OCR",
            command: "screen-ocr",
            icon: "🔤",
            lucide: "copy",
            copyValue: "screen-ocr"
        };
    }

    // 0B. Screen QR Scanner & Generator: @qr <text/url> or @qr
    if (/^(@qr|qr)(\s+|$)/i.test(q)) {
        const term = q.replace(/^(@qr|qr)\s*/i, "").trim();
        if (term.length > 0) {
            return {
                mode: "action",
                isAction: true,
                isQrGen: true,
                title: "Generate QR Code (Rust)",
                expression: "Generate QR image & copy to clipboard for: " + term,
                result: "Generate",
                command: "ag-screen-tools qr-gen \"" + term.replace(/"/g, "\\\"") + "\"",
                icon: "▦",
                lucide: "copy",
                copyValue: term
            };
        } else {
            return {
                mode: "action",
                isAction: true,
                isQrScan: true,
                title: "Scan Screen QR Code (Rust)",
                expression: "Select a QR code on screen to decode and copy URL",
                result: "Scan",
                command: "screen-qr",
                icon: "▦",
                lucide: "copy",
                copyValue: "screen-qr"
            };
        }
    }

    // GitHub Quick Jump: @gh <query>, @gh prs, @gh issues, @gh <user/repo>, @pr <num/query>
    if (/^(@gh|@pr|gh|pr)(\s+|$)/i.test(q)) {
        const term = q.replace(/^(@gh|@pr|gh|pr)\s*/i, "").trim();
        const isNum = /^#?\d+$/.test(term);

        // 1. Direct PR number lookup (e.g. @gh 436 or @pr #436)
        if (isNum) {
            const numStr = term.replace(/^#/, "");
            let pr = null;
            if (context && context.githubService && context.githubService.getPr) {
                pr = context.githubService.getPr(numStr);
                if (!pr && context.githubService.fetchPr) {
                    context.githubService.fetchPr(numStr);
                }
            }

            if (pr) {
                const repoName = pr.repo || "repo";
                const authorName = pr.author || "alvinbengeorge";
                const authorStr = " • @" + authorName;
                const ciStr = pr.ci_status ? (" • CI: " + pr.ci_status) : "";
                const stateStr = (pr.state || "Open").toUpperCase();
                return {
                    mode: "github",
                    isPr: true,
                    isJira: false,
                    prNumber: pr.number,
                    title: pr.title || ("Pull Request #" + pr.number),
                    expression: repoName + " #" + pr.number + authorStr + ciStr + (pr.updated_ago ? (" • " + pr.updated_ago) : ""),
                    repo: pr.repo || "",
                    fullRepo: pr.full_repo || "",
                    author: authorName,
                    ciStatus: pr.ci_status || "",
                    updatedAgo: pr.updated_ago || "",
                    state: stateStr,
                    result: stateStr,
                    url: pr.url || ("https://github.com/askmeidentitycorp/" + (pr.repo || "") + "/pull/" + pr.number),
                    icon: "⎇",
                    lucide: "code",
                    copyValue: "#" + pr.number + " " + (pr.title || "") + " (" + (pr.url || "") + ")"
                };
            }

            // Pending / Loading PR
            const url = "https://github.com/pulls";
            return {
                mode: "github",
                isPr: true,
                isJira: false,
                prNumber: numStr,
                title: "Pull Request #" + numStr,
                expression: "Querying GitHub repository details...",
                repo: "GitHub",
                author: "",
                ciStatus: "",
                state: "OPEN",
                result: "LOOKUP...",
                url: url,
                icon: "⎇",
                lucide: "code",
                copyValue: "PR #" + numStr
            };
        }

        // 2. PR search by keyword in cache (e.g. @gh meetings or @pr stripe)
        if (context && context.githubService && context.githubService.searchPrs && term.length > 1 && !term.includes("/")) {
            const matchedPrs = context.githubService.searchPrs(term);
            if (matchedPrs && matchedPrs.length > 0) {
                const pr = matchedPrs[0];
                const repoName = pr.repo || "repo";
                const authorName = pr.author || "alvinbengeorge";
                const authorStr = " • @" + authorName;
                const ciStr = pr.ci_status ? (" • CI: " + pr.ci_status) : "";
                const stateStr = (pr.state || "Open").toUpperCase();
                return {
                    mode: "github",
                    isPr: true,
                    isJira: false,
                    prNumber: pr.number,
                    title: pr.title || ("Pull Request #" + pr.number),
                    expression: repoName + " #" + pr.number + authorStr + ciStr + (pr.updated_ago ? (" • " + pr.updated_ago) : ""),
                    repo: pr.repo || "",
                    fullRepo: pr.full_repo || "",
                    author: authorName,
                    ciStatus: pr.ci_status || "",
                    updatedAgo: pr.updated_ago || "",
                    state: stateStr,
                    result: stateStr,
                    url: pr.url,
                    icon: "⎇",
                    lucide: "code",
                    copyValue: "#" + pr.number + " " + (pr.title || "") + " (" + (pr.url || "") + ")"
                };
            }
        }

        let url = "https://github.com";
        let title = "GITHUB SEARCH";
        let expr = "Open GitHub.com";
        let res = "github.com";

        if (term.toLowerCase() === "prs" || term.toLowerCase() === "pulls") {
            url = "https://github.com/pulls";
            title = "GITHUB PULL REQUESTS";
            expr = "Open your GitHub Pull Requests";
            res = "github.com/pulls";
        } else if (term.toLowerCase() === "issues") {
            url = "https://github.com/issues";
            title = "GITHUB ISSUES";
            expr = "Open your assigned GitHub Issues";
            res = "github.com/issues";
        } else if (term.toLowerCase() === "notifications" || term.toLowerCase() === "notifs") {
            url = "https://github.com/notifications";
            title = "GITHUB NOTIFICATIONS";
            expr = "Open GitHub notifications inbox";
            res = "github.com/notifications";
        } else if (/^[a-zA-Z0-9_.-]+\/[a-zA-Z0-9_.-]+$/.test(term)) {
            // Direct repo jump: e.g. @gh quickshell-mirror/quickshell
            url = "https://github.com/" + term;
            title = "GITHUB REPOSITORY";
            expr = "Direct jump to " + term;
            res = "github.com/" + term;
        } else if (term.length > 0) {
            url = "https://github.com/search?q=" + encodeURIComponent(term);
            title = "GITHUB SEARCH";
            expr = "Search GitHub for '" + term + "'";
            res = "search: " + term;
        }

        return {
            mode: "webjump",
            icon: "⎇",
            lucide: "git-pull-request",
            title: title,
            expression: expr,
            result: res,
            url: url,
            copyValue: url
        };
    }

    // Jira Quick Jump: @jira <key/query>, @jira 270, @jira ABT-270, @jira board, @jira work
    if (/^(@jira|jira)(\s+|$)/i.test(q)) {
        const term = q.replace(/^(@jira|jira)\s*/i, "").trim();
        const cleanTerm = /^\d+$/.test(term) ? ("ABT-" + term) : term;
        const isIssue = /^[a-zA-Z]+-\d+$/i.test(cleanTerm);

        // 1. Direct Issue Key Lookup (e.g. @jira ABT-270 or @jira 270)
        if (isIssue) {
            const issueKey = cleanTerm.toUpperCase();
            let issue = null;
            if (context && context.jiraService && context.jiraService.getIssue) {
                issue = context.jiraService.getIssue(issueKey);
                if (!issue && context.jiraService.fetchIssue) {
                    context.jiraService.fetchIssue(issueKey);
                }
            }

            if (issue) {
                const statusStr = (issue.status || "Open").toUpperCase();
                const assigneeStr = issue.assignee ? (" • " + issue.assignee) : "";
                const typeStr = issue.issuetype || "Issue";
                const priorityStr = issue.priority ? (" • " + issue.priority + " Priority") : "";
                return {
                    mode: "jira",
                    isJira: true,
                    isPr: false,
                    issueKey: issue.key,
                    title: issue.summary || ("Issue " + issue.key),
                    expression: issue.key + " • " + (issue.status || "Open") + " • " + typeStr + priorityStr + assigneeStr,
                    status: issue.status || "Open",
                    statusCategory: issue.status_category || "To Do",
                    issueType: typeStr,
                    priority: issue.priority || "Medium",
                    assignee: issue.assignee || (context && context.jiraService && context.jiraService.user ? context.jiraService.user.displayName : "Alvin George"),
                    updatedAgo: issue.updated_ago || "",
                    result: statusStr,
                    url: issue.url || ("https://askmeidentity.atlassian.net/browse/" + issue.key),
                    icon: "🎫",
                    lucide: "check",
                    copyValue: issue.key + ": " + (issue.summary || "") + " (" + (issue.url || "") + ")"
                };
            }

            // Interim / Fetching state
            const url = "https://askmeidentity.atlassian.net/browse/" + issueKey;
            return {
                mode: "jira",
                isJira: true,
                isPr: false,
                issueKey: issueKey,
                title: "Issue " + issueKey,
                expression: "Querying AskMeIdentity Jira Cloud REST API...",
                status: "Loading",
                statusCategory: "To Do",
                issueType: "Issue",
                priority: "",
                assignee: "",
                result: "LOOKUP...",
                url: url,
                icon: "🎫",
                lucide: "check",
                copyValue: url
            };
        }

        // 2. Search tasks in cache by summary/key (e.g. @jira meetings or @jira password)
        if (context && context.jiraService && context.jiraService.searchTasks && term.length > 1) {
            const matchedTasks = context.jiraService.searchTasks(term);
            if (matchedTasks && matchedTasks.length > 0) {
                const issue = matchedTasks[0];
                const statusStr = (issue.status || "Open").toUpperCase();
                const assigneeStr = issue.assignee ? (" • " + issue.assignee) : "";
                const typeStr = issue.issuetype || "Issue";
                const priorityStr = issue.priority ? (" • " + issue.priority + " Priority") : "";
                return {
                    mode: "jira",
                    isJira: true,
                    isPr: false,
                    issueKey: issue.key,
                    title: issue.summary || ("Issue " + issue.key),
                    expression: issue.key + " • " + (issue.status || "Open") + " • " + typeStr + priorityStr + assigneeStr,
                    status: issue.status || "Open",
                    statusCategory: issue.status_category || "To Do",
                    issueType: typeStr,
                    priority: issue.priority || "Medium",
                    assignee: issue.assignee || (context && context.jiraService && context.jiraService.user ? context.jiraService.user.displayName : "Alvin George"),
                    updatedAgo: issue.updated_ago || "",
                    result: statusStr,
                    url: issue.url || ("https://askmeidentity.atlassian.net/browse/" + issue.key),
                    icon: "🎫",
                    lucide: "check",
                    copyValue: issue.key + ": " + (issue.summary || "") + " (" + (issue.url || "") + ")"
                };
            }
        }

        let url = "https://askmeidentity.atlassian.net";
        let title = "OPEN JIRA WORK";
        let expr = "Open AskMeIdentity Jira";
        let res = "askmeidentity.atlassian.net";

        if (term.toLowerCase() === "my" || term.toLowerCase() === "work" || term.toLowerCase() === "tasks") {
            url = "https://askmeidentity.atlassian.net/jira/your-work";
            title = "JIRA ASSIGNED WORK";
            expr = "Open your assigned Jira tasks & sprints";
            res = "jira/your-work";
        } else if (term.toLowerCase() === "boards" || term.toLowerCase() === "board") {
            url = "https://askmeidentity.atlassian.net/jira/software/projects/ABT/boards";
            title = "JIRA SPRINT BOARD";
            expr = "Open AskMeIdentity Agile Board";
            res = "jira/boards";
        } else if (term.length > 0) {
            url = "https://askmeidentity.atlassian.net/issues/?jql=text%20~%20%22" + encodeURIComponent(term) + "%22";
            title = "SEARCH JIRA: " + term.toUpperCase();
            expr = "Search AskMeIdentity issues for '" + term + "'";
            res = "search: " + term;
        }

        return {
            mode: "webjump",
            icon: "🎫",
            lucide: "check",
            title: title,
            expression: expr,
            result: res,
            url: url,
            copyValue: url
        };
    }

    // Web / Google Search: @web <query>, @g <query>, or ? <query>
    if (/^(@web|@g|\?)\s+/i.test(q)) {
        const term = q.replace(/^(@web|@g|\?)\s+/i, "").trim();
        const url = term.length > 0 ? ("https://www.google.com/search?q=" + encodeURIComponent(term)) : "https://www.google.com";
        return {
            mode: "webjump",
            icon: "🌐",
            lucide: "globe",
            title: "GOOGLE WEB SEARCH",
            expression: term.length > 0 ? ("Search Google for '" + term + "'") : "Open Google.com",
            result: term.length > 0 ? ("google.com/search?q=" + term) : "google.com",
            url: url,
            copyValue: url
        };
    }

    return null;
}

// ── 6. MASTER INSPECTOR DISPATCHER ─────────────────────────────────────────

function inspect(query, context) {
    if (!query) return null;
    const q = query.trim();
    if (q.length === 0) return null;

    // 0. Smart Web Jump (@gh, @jira, @web)
    const webJump = evaluateWebJump(q, context);
    if (webJump) return webJump;

    // 1. Color check (starts with # or matches hex/rgb)
    const colorRes = evaluateColor(q);
    if (colorRes) return colorRes;

    // 2. Base Conversion (0x7f to dec, 255 to hex)
    const baseRes = evaluateBaseConversion(q);
    if (baseRes) return baseRes;

    // 3. Conversion check (contains 'in', 'to', 'as')
    const convRes = evaluateConversion(q);
    if (convRes) return convRes;

    // 4. Time in city check
    const timeRes = evaluateTime(q);
    if (timeRes) return timeRes;

    // 5. Glyphs & emoji check (starts with : or matches glyph/arrow/symbol query)
    if (q.startsWith(":") || /^(arrow|glyph|symbol|math|greek|emoji|star|check|heart)/i.test(q)) {
        const glyphRes = evaluateGlyphs(q);
        if (glyphRes) return glyphRes;
    }

    // 6. Math check
    const mathRes = evaluateMath(q);
    if (mathRes) return mathRes;

    return null;
}
