---
layout: article
titles:
  # @start locale config
  en      : &EN       Talks
  # @end locale config
key: page-talks
permalink: talks
---

<div class="talks-columns">
{%- assign _shared = site.papers | where_exp: "e", "e.type == 'paper-and-talk'" -%}
{%- assign entries = site.talks | concat: _shared | sort: "talk_date" | reverse -%}
{%- for entry in entries -%}
{%- include papers-talks/card-talk.html entry=entry -%}
{% endfor -%}
</div>
