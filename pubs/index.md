---
title: Publications
published: true
---

### Journal Papers

{% for post in site.categories.journal %}
{% capture pub %}
  {{ post.author }}. "**{{ post.title }}**" _{{ post.journal }}_.
  {% if post.month %} {{ post.month }} {% endif %}
  {{ post.year }}.
  (
  {% if post.project %} [Project page][{{post.project}}] {% endif %}
  {% if post.link %} [Journal Page][{{post.link}}] {% endif %}
  {% if post.file %} [Cached Copy](/papers/{{ post.file }}) {% endif %}
  )
{% endcapture %}
* {{ pub | strip_newlines }}
{% endfor %}

### Conference Proceedings

{% for post in site.categories.conference %}
{% capture pub %}
  {{ post.author }}. "**{{ post.title }}**" _{{ post.conference }}_.
  {% if post.month %} {{ post.month }} {% endif %}
  {{ post.year }}.
  (
  {% if post.project %} [Project page][{{post.project}}] {% endif %}
  {% if post.file %} [PDF](/papers/{{ post.file }}) {% endif %}
  )
{% endcapture %}
* {{ pub | strip_newlines }}
{% endfor %}

[Security]: /projects/security