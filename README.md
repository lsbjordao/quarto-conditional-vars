# conditional-vars

![quarto-conditional-vars logo](logo.png)

A Quarto extension that enables conditional content blocks based on values defined in `_variables.yml` — filling a gap not covered by Quarto's built-in `.when` (which is profile-based only).

Works with **all Quarto engines** (knitr, Jupyter, Julia, Observable, etc.) since it reads from `_variables.yml`.

## Installation

```bash
quarto add lsbjordao/quarto-conditional-params
```

## Quarto Wizard support

This extension includes Quarto Wizard metadata for editor autocompletion,
validation, hover documentation, and snippets:

- `_extensions/conditional-vars/_schema.yml`
- `_extensions/conditional-vars/_snippets.json`

Available snippet prefixes:

- `show-vars`
- `when-var-block`
- `unless-var-block`
- `when-var-inline`
- `unless-var-inline`
- `when-unless-combined`

## Setup

Define your variables in `_variables.yml` at the root of your project:

```yaml
# _variables.yml
type: detailed
region: south
active: true
year: 2024
report:
  audience: public
  level: 2
```

Add the filter to your document or project frontmatter:

```yaml
---
filters:
  - conditional-vars
---
```

---

### Show active variables

```markdown
{{< show-vars >}}
```

Renders a list of all variable names and values from `_variables.yml`. Useful for debugging.

---

### `.when-var` — show when condition matches

```markdown
::: {.when-var type="detailed"}
Shown only when `type` equals `detailed`.
:::
```

---

### `.unless-var` — show when condition does NOT match

```markdown
::: {.unless-var region="north"}
Shown in every region except `north`.
:::
```

---

### Inline conditionals

You can use the same logic inline with span attributes:

```markdown
This text [appears only for detailed reports]{.when-var type="detailed"} in the same paragraph.

This text [is hidden in south region]{.unless-var region="south"}.

Inline OR: [works for `south` or `north`]{.when-var region="south|north"}.

Inline numeric: [shown when year is >= 2024]{.when-var year=">=2024"}.

Inline numeric range (50% <= support_pct < 60%):
[in range]{.when-var support_pct=">=50&<60"}

Support by percentage (`support_pct`):
[weak support]{.when-var support_pct="<40"}
[moderate support]{.when-var .unless-var when-support_pct=">=40" unless-support_pct=">=70"}
[strong support]{.when-var support_pct=">=70"}
```

`when-<var>` and `unless-<var>` prefixes also work inline when both classes are present.
You can also combine constraints for the same variable with `&` (AND), and combine alternatives with `|` (OR).

---

### AND — multiple attributes

All attributes must match simultaneously.

```markdown
::: {.when-var type="detailed" region="south"}
Shown only when `type` is `detailed` and `region` is `south`.
:::
```

---

### OR — pipe-separated values

Any value in the list is sufficient to match.

```markdown
::: {.when-var type="detailed|summary"}
Shown when `type` is `detailed` or `summary`.
:::
```

Works with numeric conditions too:

```markdown
::: {.when-var year=">2025|<2020"}
Shown when `year` > 2025 or `year` < 2020.
:::
```

---

### Numeric comparisons

Supports `>`, `>=`, `<`, `<=` operators, and `&` for AND ranges.

```markdown
::: {.when-var year=">2020"}
Shown when `year` > 2020.
:::

::: {.when-var year=">=2024"}
Shown when `year` >= 2024.
:::

::: {.when-var year="<2024"}
Shown when `year` < 2024.
:::

::: {.when-var year="<=2023"}
Shown when `year` <= 2023.
:::

::: {.when-var year=">=2020&<2025"}
Shown when `year` is in [2020, 2025).
:::

::: {.when-var year=">=2025&<2030"}
Shown when `year` is in [2025, 2030).
:::

::: {.when-var year=">=2020&<2023|>=2024&<2026"}
Shown when `year` is in [2020, 2023) or [2024, 2026).
:::

::: {.when-var year=">=2010&<2015|>=2030&<2035"}
Shown when `year` is in [2010, 2015) or [2030, 2035).
:::
```

---

### Boolean variables

```markdown
::: {.when-var active="true"}
Shown only when `active` is `true`.
:::
```

---

### Nested variables

Nested mappings in `_variables.yml` are accessible with dot notation.

```yaml
# _variables.yml
report:
  audience: public
  level: 2
```

```markdown
::: {.when-var report.audience="public"}
Shown only when `report.audience` is `public`.
:::

::: {.when-var report.level=">=2"}
Shown when `report.level` >= 2.
:::
```

---

### Mixed — `.when-var` + `.unless-var`

When both classes are present, use `when-<var>` and `unless-<var>` prefixes to declare each condition explicitly.

```markdown
::: {.when-var .unless-var when-type="detailed" unless-region="north"}
Shown when `type` is `detailed` and `region` is not `north`.
:::
```

---

### Unknown variables emit a warning

A reference to a variable that does not exist evaluates to `false` (block hidden) and prints a warning to the console:

```markdown
::: {.when-var country="Brazil"}
Shown only when `country` equals `Brazil`.
:::
```

```text
WARNING [conditional-vars]: unknown variable 'country' referenced in .when-var / .unless-var
```

---

## Why this extension?

Quarto's `.when` conditional content supports profiles and other build-time conditions, but cannot evaluate conditions based on variable values. This extension enables conditional content driven directly by `_variables.yml`, allowing variable-aware rendering workflows that work across all document engines.

## License

MIT © Lucas S.B. Jordão
