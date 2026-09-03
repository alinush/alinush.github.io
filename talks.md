---
layout: article
titles:
  # @start locale config
  en      : &EN       Talks
  # @end locale config
key: page-talks
permalink: talks
---

Some of my talks throughtout the years, both academic and otherwise.
Among these are some unrecorded, slides-only talks.
More talks can be found in [my CV](/files/cv.pdf) and [this YouTube playlist](https://www.youtube.com/playlist?list=PLQnmw99gY3HBaEk5A9pacleVVQNu7oxGg).

<div class="talks-columns">
{%- assign _shared = site.papers | where_exp: "e", "e.type == 'paper-and-talk'" -%}
{%- assign entries = site.talks | concat: _shared | sort: "talk_date" | reverse -%}
{%- for entry in entries -%}
{%- include papers-talks/card-talk.html entry=entry -%}
{% endfor -%}
</div>
