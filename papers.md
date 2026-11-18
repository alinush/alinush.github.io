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
{%- comment -%} Upcoming (`status: upcoming`) papers come first, then the rest by date (newest first). {%- endcomment -%}
{%- assign upcoming = site.papers | where_exp: "e", "e.status == 'upcoming'" | sort: "date" | reverse -%}
{%- assign rest = site.papers | where_exp: "e", "e.status != 'upcoming'" | sort: "date" | reverse -%}
{%- assign entries = upcoming | concat: rest -%}
{%- for entry in entries -%}
{%- include papers-talks/card-paper.html entry=entry -%}
{% endfor -%}
</div>
