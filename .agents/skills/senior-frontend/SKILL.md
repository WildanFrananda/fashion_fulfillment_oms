---
name: senior-frontend
description: Senior Frontend Engineer & UI/UX Specialist skill guide for crafting high-converting, modern, non-generic, responsive, glassmorphic, and accessible web application interfaces. Use whenever creating or modifying HTML/ERB views, CSS stylesheets, layout designs, and client-side interactions.
---

# Senior Frontend Engineer & UI/UX Specialist Skill Guide

This skill equips Antigravity with senior frontend engineering capabilities and design principles to build visually stunning, production-ready, enterprise-grade web interfaces.

---

## 🎨 1. Aesthetic Philosophy: Non-Generic, Premium Design

1. **Avoid Generic AI Defaults:**
   - Never use default browser fonts, plain gray backgrounds (`#ffffff`/`#f0f0f0`), or basic flat primary colors (`#0000ff`/`#ff0000`).
   - Always use curated dark mode palettes (Slate `#0f172a` & `#1e293b`) with vibrant HSL accent gradients (Indigo `#6366f1`, Emerald `#10b981`, Violet `#8b5cf6`, Amber `#f59e0b`).

2. **Glassmorphism & Depth:**
   - Wrap cards and panels in semi-transparent glass containers:
     ```css
     background: rgba(30, 41, 59, 0.75);
     backdrop-filter: blur(16px);
     -webkit-backdrop-filter: blur(16px);
     border: 1px solid rgba(255, 255, 255, 0.1);
     box-shadow: 0 10px 30px -10px rgba(0, 0, 0, 0.5);
     border-radius: 16px;
     ```

---

## 🔤 2. Typography & Hierarchy Standard

1. **Font Family Selection:**
   - Always load modern Google Fonts such as `Outfit`, `Plus Jakarta Sans`, or `Inter`.
2. **Strict Font Weight Hierarchy:**
   - **Page Titles / Hero Headers:** `font-size: 24px - 32px`, `font-weight: 800`, `letter-spacing: -0.5px`.
   - **Card Titles & Section Headers:** `font-size: 16px - 18px`, `font-weight: 700`.
   - **Body & Details:** `font-size: 13px - 14px`, `font-weight: 500`, `color: #94a3b8` (muted text).
   - **Monospace Tabular Data:** Use `font-family: 'JetBrains Mono', monospace` for SKU numbers, barcodes, coordinates, and prices.

---

## ⚡ 3. Micro-Animations & Interactive Motion

1. **Interactive Hover Lift:**
   ```css
   .order-card {
     transition: transform 0.25s cubic-bezier(0.4, 0, 0.2, 1), border-color 0.25s ease, box-shadow 0.25s ease;
   }
   .order-card:hover {
     transform: translateY(-4px);
     border-color: rgba(99, 102, 241, 0.5);
     box-shadow: 0 20px 40px -15px rgba(99, 102, 241, 0.25);
   }
   ```

2. **Live Status Pulsing Dot:**
   ```css
   .pulse-dot {
     width: 10px;
     height: 10px;
     background: #10b981;
     border-radius: 50%;
     animation: pulseRing 1.5s cubic-bezier(0.45, 0, 0.55, 1) infinite;
   }
   @keyframes pulseRing {
     0% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(16, 185, 129, 0.7); }
     70% { transform: scale(1.05); box-shadow: 0 0 0 8px rgba(16, 185, 129, 0); }
     100% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(16, 185, 129, 0); }
   }
   ```

---

## 📐 4. Layout Architecture & Component Design

1. **Responsive CSS Grid:**
   - Always layout cards using dynamic CSS Grid:
     `display: grid; grid-template-columns: repeat(auto-fill, minmax(340px, 1fr)); gap: 20px;`
2. **Pill Badges:**
   - Status and urgency badges must use soft 15% opacity background fills with matching 30% border color:
     `background: rgba(16, 185, 129, 0.15); color: #34d399; border: 1px solid rgba(16, 185, 129, 0.3); border-radius: 20px; padding: 4px 12px; font-size: 11px; font-weight: 700;`
3. **Empty States & Feedback Banners:**
   - Banners and empty states must have clear icons, rich contrast, and helpful guidance text.

---

## 🛠️ 5. Clean Code Practices (DRY & Modular)

1. **Reusable Component Partials:**
   - Extract repeating layout patterns (e.g. Navbars, Tab Headers, Stat Cards, Flash Banners) into Rails Partials under `app/views/shared/`.
2. **Separation of Concerns:**
   - Keep styling strictly inside CSS stylesheets (`app/assets/stylesheets/`).
   - Use clean semantic HTML tags.
