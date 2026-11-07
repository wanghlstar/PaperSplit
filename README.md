<div align="center">
  <img src="public/favicon.png" alt="PaperSplit Logo" width="120" height="120">
  <h1>PaperSplit</h1>
</div>

> **二开说明 / Fork Note**
>
> 本项目基于上游 [TwoBall/PaperSplit](https://github.com/TwoBall/PaperSplit) 二次开发，新增**三栏切割**与 **macOS / Windows / 飞牛 fnOS 客户端**；原始版权与 MIT 许可保持不变。
>
> Forked from [TwoBall/PaperSplit](https://github.com/TwoBall/PaperSplit), adding **three-column splitting** and **macOS / Windows / fnOS apps**. Original copyright and the MIT license are retained.

**[English](#english) | [中文指南](#中文)**

<div id="english"></div>

## 📖 English

**PaperSplit** is a lightweight, privacy-focused web tool designed to split **A3 exam papers or documents into A4 format**. It runs entirely in your browser, ensuring your data remains private and secure.

### ✨ Key Features

*   **Smart Import**: Supports drag-and-drop for A3 PDFs or images (JPG/PNG).
*   **Visual Splitting**: Supports two- or three-column layouts, with draggable red splitter lines to adjust each cut position.
*   **Seal Line Removal**:
    *   Dedicated "Remove Seal Line" mode.
    *   **Smart Detection**: Odd pages default to left, even pages default to right.
    *   Adjustable seal area that is automatically cropped during export.
*   **Batch Application**:
    *   **Apply to Same Type**: One-click apply settings to all Odd or all Even pages.
    *   **Apply to All**: Apply current configuration to every page.
*   **HD Export**: Generates high-quality A4 PDF documents using `jsPDF`, with selectable page-fit modes (standard A4 with margins, auto-trim uniform scaling, stretch-to-fill, or original crop size).
*   **Desktop & NAS Apps**: The same codebase also builds macOS 13+ (Apple Silicon / Intel), Windows 10/11 x64, and fnOS FPK packages.
*   **Responsive Design**: Works perfectly on both PC and mobile devices.

### 🚀 Quick Start

#### 1. Install Dependencies
This project uses `npm` for dependency management.
```bash
npm install
```

#### 2. Start Development Server
```bash
npm run dev
```
Open the local URL shown in the terminal (usually `http://localhost:5173`).

#### 3. How to Use
1.  **Import**: Click "Select File" or drag your file into the workspace.
2.  **Adjust**:
    *   Choose **two or three columns**, then move the **Red Lines** to set each cut position.
    *   Click "**Remove Seal Line**" to add a cut-off area if needed (draggable).
3.  **Batch**: Use "Same Type" or "All Pages" buttons to apply your settings to other pages.
4.  **Export**: Click "Export as PDF (A4)" to download your processed file.

---

<div id="中文"></div>

## 🇨🇳 中文指南

**PaperSplit** (原 PDF Edit) 是一个基于 Web 的轻量级工具，专为将 **A3 格式的试卷或文档拆分为 A4 格式**而设计。它完全在浏览器端运行，确保数据隐私安全。

### ✨ 核心功能

*   **智能导入**：支持拖拽上传 A3 PDF 文件或图片（JPG/PNG）。
*   **可视化分割**：支持两栏 / 三栏版面，每条红色分割线均可拖动调整切割位置。
*   **密封线处理**：
    *   支持“去除密封线”模式。
    *   **智能识别**：奇数页默认在左侧，偶数页默认在右侧。
    *   可拖动调整密封线范围，导出时自动裁切该区域。
*   **批量应用**：
    *   **同类页**：一键应用当前配置到所有奇数页或所有偶数页。
    *   **所有页**：一键应用到文档所有页面。
*   **高清导出**：基于 `jsPDF` 生成高质量的 A4 PDF 文档，并可选择导出尺寸适配方式（标准A4等比留白 / 去白边等比放大 / 拉伸填满 / 原始裁剪尺寸）。
*   **各端 App**：同一套代码提供 macOS 13+（Apple Silicon / Intel）、Windows 10/11 x64 与飞牛 fnOS 安装包。
*   **响应式设计**：完美适配 PC 和移动端操作，手机上也能轻松处理试卷。

### 🚀 快速开始

#### 1. 安装依赖
```bash
npm install
```

#### 2. 启动开发服务器
```bash
npm run dev
```
启动后，访问终端显示的本地地址（通常是 `http://localhost:5173`）。

#### 3. 使用流程
1.  **导入**：点击“选择文件”或直接拖拽文件到工作区。
2.  **调整**：
    *   选择**两栏 / 三栏**，再移动红色**分割线**确定各栏分页界限。
    *   若有密封线需要去除，点击“去除密封线”，调整灰色虚线区域。
3.  **批量**：调整好一页后，点击“同类页”或“所有页”将配置应用到其他页面。
4.  **导出**：点击底部的“导出为 PDF (A4)”，文件将自动下载。

---

## �️ Tech Stack / 技术栈

*   **Core**: Native JavaScript (ES6 Modules)
*   **PDF Processing**: `pdfjs-dist` (Rendering), `jspdf` (Generation)
*   **Styling**: CSS3 (Flexbox/Grid), locally bundled Material Icons / Outfit fonts
*   **Build**: Vite
*   **Packaging**: Go static server + Swift/WKWebView (macOS) + Go/Edge app mode (Windows) + fnOS FPK

## �📂 Project Structure / 项目结构

```
/
├── index.html          # Entry HTML
├── style.css           # Global Styles
├── vite.config.js      # Vite Configuration
├── src/                # Source Code
│   ├── main.js         # Entry Point
│   ├── state.js        # State Management
│   ├── dom.js          # DOM Elements
│   ├── file-handler.js # File Upload & Processing
│   ├── viewer.js       # Canvas Rendering
│   ├── editor.js       # Split/Seal Line Logic
│   ├── split-utils.js  # Column Split/Slice Math
│   └── exporter.js     # PDF Export Logic
├── packaging/          # macOS / Windows / fnOS packaging scripts
├── public/             # favicon + bundled fonts
└── DEPLOY.md           # Deployment Guide
```

## 📦 Desktop & NAS Packages / 桌面与 NAS 打包

PDF.js worker 和字体都已本地打包，各端离线包均不依赖 CDN。

- **macOS App**（macOS 13+；默认 universal，同时支持 Intel 与 Apple Silicon）
  ```bash
  ./packaging/macos/build-app.sh              # universal
  ARCH=x86_64 ./packaging/macos/build-app.sh  # 仅 Intel
  ARCH=arm64  ./packaging/macos/build-app.sh  # 仅 Apple Silicon
  ```
  产物：`dist-app/PaperSplit.app` 和对应 zip。CI 会分别构建 arm64 与 x86_64 两个 zip。采用 ad-hoc 签名；若首次打开被系统拦截，右键 → 打开，或执行 `xattr -dr com.apple.quarantine PaperSplit.app`。

- **Windows x64**（Windows 10/11，需系统自带 Edge）
  ```bash
  ./packaging/windows/build-win.sh
  ```
  产物：`dist-packages/PaperSplit-<version>-Windows-x64.zip`（单 exe，内嵌全部网页资源，以 Edge 应用模式打开窗口；无需 .NET / WebView2 运行时）。

- **飞牛 fnOS FPK**
  ```bash
  ./packaging/fnos/build-fpk.sh
  ```
  产物：`dist-packages/papersplit_<version>_all.fpk`（内置 linux x86_64 / aarch64 / armv7 服务端）。在飞牛应用中心手动安装；默认端口 **15100**，安装向导和应用设置中均可修改。

- **GitHub Actions**：`.github/workflows/build-packages.yml` 支持手动触发或 push 构建 FPK、macOS（arm64 / x86_64）与 Windows x64，并上传为 Artifacts；推送 `v*` tag 时会自动创建 Release 并附加安装包（仅推分支不会发布 Release）。

## 📄 License



MIT License

## 📅 Changelog / 更新日志

### 2026-11-07 (Three-Column Support / 三栏支持)
- **Multi-Column Splitting**: Added a column-count selector (two or three columns) and generic slice export. Each split line is draggable and clamped between its neighbors, so three-column exam papers are cut into three pages per sheet. 新增两栏 / 三栏选择与通用切片导出；每条分割线可独立拖动且不会越过相邻分割线，三栏试卷每张可切出三页。
- **Auto-Trim Uniform Scaling**: Added an "标准 A4（去白边等比放大）" export mode. It detects page whitespace, crops it, and applies one document-wide scale so every output page keeps the same text size without distortion (about 7–10% larger than plain A4 fit on scanned papers). The stretch-to-fill option is now labelled as distorting. 新增“去白边等比放大”导出模式：自动裁掉扫描空白并全文档统一比例缩放，各页字号一致且不变形；拉伸填满选项已注明会变形。

### 2026-06-20 (Export Fit Modes / 导出尺寸适配)
- **Selectable Export Fit**: Added an "导出尺寸" selector with three modes — **Standard A4 (fit, with margins)** [default], **Standard A4 (stretch to fill)**, and **Original crop size (WYSIWYG)**. Dragging the split line off-center no longer forces non-A4 pages unless you choose WYSIWYG. 新增"导出尺寸"选择器：标准A4等比留白(默认)、标准A4拉伸填满、原始裁剪尺寸；切割线偏离中心也能稳定输出标准 A4。

### 2026-06-20 (Bug Fixes / 问题修复)
- **Render Race Fix**: `renderCurrentPage` now uses a render token to discard stale concurrent renders, and the window-resize handler is debounced (150ms) — no more duplicate canvases / overlapping guide lines when resizing or switching pages quickly. 修复窗口缩放、快速翻页时画布与辅助线重影的问题。
- **Unsupported File Handling**: File type is now validated *before* enabling controls; unknown formats show an alert and abort instead of leaving the UI half-enabled. `resetState` now also resets `isPdf`. 上传不支持的文件类型不再留下"半启用"状态。
- **Seal Line Symmetry**: Even-page default seal position corrected from `0.8` to `0.85`, symmetric with the odd-page `0.15`. 修正偶数页默认密封线位置，与奇数页对称。
- **Export Geometry**: Seal direction is now driven by `seal.type` (not its position relative to the split line), and the split point is clamped into the kept region — dragging a seal line across the split line can no longer leak the sealed area or produce inverted slices. 导出时密封方向由语义决定并钳制分割点，杜绝密封区外泄与反向切片。

### 2025-12-13 (Evening Update)
- **Bug Fix**: Fixed seal line drag jumping issue using delta-based calculation.
- **UX Improvement**: Auto-hide left thumbnail panel when no file is uploaded.
- **Config Adjustment**: Optimized default seal line position to 0.15/0.85 for better accuracy.

### 2025-12-13
- **Mobile Support**: Added touch event support for smooth split-line dragging on mobile devices.
- **UI Redesign**: Replaced split-line dots with an arrow handle (`↔`) for better visibility and usability.
- **Style Optimization**: Refactored `style.css` with cleaner structure and removed redundant code.
- **Branding**: Updated project icon and header logo.

