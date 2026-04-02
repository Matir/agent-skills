# Spreadsheet Skill Manual

## Temp and Output Conventions

- Use `tmp/spreadsheets/` for intermediate files; delete when done.
- Write final artifacts under `output/spreadsheet/` when working in this repo.
- Keep filenames stable and descriptive.

## Primary Tooling

- **openpyxl**: For creating/editing `.xlsx` files and preserving formatting.
- **pandas**: For analysis and CSV/TSV workflows; write results back to `.xlsx` or `.csv`.
- **openpyxl.chart**: For native Excel charts.

## Rendering and Visual Checks

If LibreOffice (`soffice`) and Poppler (`pdftoppm`) are available, render sheets for visual review:
```bash
soffice --headless --convert-to pdf --outdir $OUTDIR $INPUT_XLSX
pdftoppm -png $OUTDIR/$BASENAME.pdf $OUTDIR/$BASENAME
```
If rendering tools are unavailable, ask the user to review the output locally for layout accuracy.

## Dependencies

Prefer `uv` for dependency management:
```bash
uv pip install openpyxl pandas matplotlib
```
System tools (macOS): `brew install libreoffice poppler`
System tools (Ubuntu): `sudo apt-get install -y libreoffice poppler-utils`

## Formula Requirements

- Use formulas for derived values; keep them simple and legible.
- Avoid volatile functions like `INDIRECT` and `OFFSET` unless required.
- Prefer cell references over magic numbers (e.g., `=H6*(1+$B$3)` not `=H6*1.04`).
- Guard against errors (#REF!, #DIV/0!) with validation.
- **Note**: openpyxl does not evaluate formulas; results will calculate in Excel/Sheets.

## Citation Requirements

- Cite sources inside the spreadsheet using plain text URLs.
- For financial models, cite inputs in cell comments.
- For tabular data, include a "Source" column with URLs.

## Formatting Requirements

### Existing Workbooks
- Render and inspect before modifying.
- Preserve existing formatting and style exactly.
- Match styles for newly filled cells.

### New or Unstyled Workbooks
- Use appropriate number and date formats.
- Clean visual layout: headers distinct, consistent spacing, readable column widths.
- Avoid borders around every cell; use whitespace for structure.

## Color Conventions (Default)

- **Blue**: User input
- **Black**: Formulas/derived values
- **Green**: Linked/imported values
- **Gray**: Static constants
- **Orange**: Review/caution
- **Light Red**: Error/flag
- **Purple**: Control/logic
- **Teal**: Visualization anchors (KPIs or chart drivers)

## Finance-Specific Requirements

- Format zeros as "-".
- Negative numbers: Red and in parentheses.
- Units in headers: (e.g., "Revenue ($mm)").
- IB-style models: Sum ranges directly above, hide gridlines, use horizontal borders above totals. Section headers should be merged with dark fill and white text.

## Original References
- [Openpyxl Examples](examples/openpyxl/)
