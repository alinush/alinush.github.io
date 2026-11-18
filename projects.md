---
layout: article
titles:
  # @start locale config
  en      : &EN       Projects
  # @end locale config
key: page-projects
permalink: projects
---

Projects throughout the years that are either: not academic in nature, not published, or go beyond a single [paper](/papers).

<div class="projects-columns">
{%- comment -%} Projects with `pin_order` come first (ascending), then the rest by date (newest first). {%- endcomment -%}
{%- assign pinned = site.projects | where_exp: "e", "e.pin_order" | sort: "pin_order" -%}
{%- assign rest = site.projects | where_exp: "e", "e.pin_order == nil" | sort: "date" | reverse -%}
{%- assign entries = pinned | concat: rest -%}
{%- for entry in entries -%}
{%- include papers-talks/card-project.html entry=entry -%}
{% endfor -%}
</div>
