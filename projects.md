---
layout: article
titles:
  # @start locale config
  en      : &EN       Projects
  # @end locale config
key: page-projects
permalink: projects
---

<div class="projects-columns">
{%- assign entries = site.projects | sort: "date" | reverse -%}
{%- for entry in entries -%}
{%- include papers-talks/card-project.html entry=entry -%}
{% endfor -%}
</div>
