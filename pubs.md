---
title: Publications
published: true
layout: master
---

{% assign lastyear = 2100 %}
{% for post in site.categories.papers %}
{% unless post.categories contains "working" %}
{% if lastyear != post.year %}
### {{ post.year }}
{% assign lastyear = post.year %}
{% endif %}
{% capture pub %}
{% include paper.md %}
{% endcapture %}
* {{ pub | strip_newlines }}
{% endunless %}
{% endfor %} 


### Working Papers

{% for post in site.categories.working %}
{% capture pub %}
  {% include working.md %}
  {% if post.abstract or post.link or post.file or post.appendix %}({% endif %}
  {% if post.abstract %} [Abstract]({{post.url}}){% if post.link or post.file %},{% endif %}{% endif %}
  {% if post.file %} [PDF](/papers/{{ post.file }}) {% endif %}
  {% if post.abstract or post.link or post.file or post.appendix %}){% endif %}
{% endcapture %}
* {{ pub | strip_newlines }}
{% endfor %}

