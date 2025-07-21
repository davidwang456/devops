# JSON 转 PDF 命令行方案

本指南介绍如何在**无需写代码**的情况下，通过命令行工具将 JSON 文件转换为 PDF，适合追求最小依赖和简单操作的场景。

---

## 方案一：json → text → pdf（最通用，依赖极少）

### 步骤 1：json 格式化为文本

- Linux/Mac/Windows（需有 Python）：
  ```bash
  cat data.json | python -m json.tool > data.txt
  ```
  或
  ```bash
  jq . data.json > data.txt
  ```

### 步骤 2：文本转 PDF

- **Linux/Mac**（需安装 enscript 和 ps2pdf）：
  ```bash
  enscript data.txt -o - | ps2pdf - data.pdf
  ```
- **Windows**：
  - 用记事本/Notepad++ 打开 data.txt，选择“打印”→“Microsoft Print to PDF”虚拟打印机。

---

## 方案二：json → html → pdf

### 步骤 1：json 转 html

- 需安装 aha（ansi2html）：
  ```bash
  cat data.json | python -m json.tool | aha > data.html
  ```

### 步骤 2：html 转 pdf

- 用浏览器打开 data.html，选择“打印”→“另存为 PDF”
- 或用命令行工具（如 wkhtmltopdf）：
  ```bash
  wkhtmltopdf data.html data.pdf
  ```

---

## 方案三：pandoc 一步到位

### 步骤 1：json 转 markdown

```bash
cat data.json | python -m json.tool > data.md
```

### 步骤 2：markdown 转 pdf

```bash
pandoc data.md -o data.pdf
```

---

## 依赖说明

- `python`：大多数系统自带
- `jq`：可选，格式化 json
- `enscript`、`ps2pdf`：Linux/Mac 常见包
- `aha`：ansi2html 工具，部分发行版可直接安装
- `pandoc`、`wkhtmltopdf`：通用文档/网页转 PDF 工具

---

## 总结

- 以上方案均**无需写代码**，只需命令行操作
- 适合简单归档、阅读、归档
- 生成的 PDF 为纯文本或简单结构
- 如需美观排版或复杂格式，建议用 Python 脚本（如 fpdf、reportlab）

如有特殊平台或格式需求，可进一步定制命令！ 

---

## 附录：如何将美化后的 JSON 放入 HTML 中

有时你只想把美化后的 JSON 直接嵌入 HTML 文件，方便浏览器查看。以下是常用方法：

### 方案一：<pre> 标签包裹

1. 先美化 JSON 并输出到文件：
   ```bash
   cat data.json | python3 -m json.tool > pretty.json
   ```
2. 生成 HTML 文件：
   ```bash
   echo '<!DOCTYPE html><html><head><meta charset="utf-8"><title>JSON Pretty</title></head><body><pre>' > data.html
   cat pretty.json >> data.html
   echo '</pre></body></html>' >> data.html
   ```
3. 用浏览器打开 data.html 即可。

### 方案二：一条命令直接生成 HTML

```bash
(echo '<!DOCTYPE html><html><head><meta charset="utf-8"><title>JSON Pretty</title></head><body><pre>'; cat data.json | python3 -m json.tool; echo '</pre></body></html>') > data.html
```

### 方案三：带语法高亮（需 aha 工具）

```bash
cat data.json | python3 -m json.tool | aha > data.html
```
> 这种方式生成的 HTML 带有颜色，但结构上仍是 <pre> 标签。

### 方案四：手动插入到已有 HTML

1. 先美化 JSON：
   ```bash
   cat data.json | python3 -m json.tool > pretty.json
   ```
2. 打开你的 HTML 文件，在合适位置插入：
   ```html
   <pre>
   （把 pretty.json 的内容粘贴进来）
   </pre>
   ```

---

**总结**
- 最简单方式：用 <pre> 标签包裹美化后的 JSON
- 一条命令即可生成完整 HTML
- 如需高亮，需用 aha 或前端 JS 库（如 highlight.js）

如需自动化脚本或更美观的样式，可以继续提问！ 
