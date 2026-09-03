---
layout: article
titles:
  # @start locale config
  en      : &EN       Papers
  # @end locale config
key: page-papers
permalink: papers
---

My academic papers throughout the years.

<div class="papers-columns">
{%- assign entries = site.papers | sort: "date" | reverse -%}
{%- for entry in entries -%}
{%- include papers-talks/card-paper.html entry=entry -%}
{% endfor -%}
</div>
