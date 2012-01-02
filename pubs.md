---
title: Publications
published: true
layout: master
---

### Journal Papers

{% for post in site.categories.journal %}
{% capture pub %}
  {{ post.author }}. "**{{ post.title }}**" _{{ post.journal }}_.
  {% if post.volume %} Vol. {{ post.volume }} {% endif %} 
  {% if post.number %} No. {{ post.number }} {% endif %} 
  {% if post.pages %} pp. {{ post.pages }}. {% endif %} 
  {% if post.month %} {{ post.month }} {% endif %} 
  {{ post.year }}. 
  (
  [Abstract]({{post.url}}){% if post.link or post.file %},{% endif %}
  {% if post.link %} [Journal Page]({{post.link}}){% endif %}{% if post.link and post.file %},{% endif %}
  {% if post.file %} [Cached Copy](/papers/{{ post.file }}) {% endif %}
  )
{% endcapture %}
* {{ pub | strip_newlines }}
{% endfor %}

### Conference Proceedings

{% for post in site.categories.conference %}
{% capture pub %}
  {{ post.author }}. "**{{ post.title }}**" _{{ post.conference }}_.
  {% if post.city %} {{ post.city }}. {% endif %}
  {% if post.month %} {{ post.month }} {% endif %}
  {{ post.year }}.
  (
  [Abstract]({{post.url}}){% if post.link or post.file %},{% endif %}
  {% if post.link %} [Link]({{post.link}}){% endif %}{% if post.link and post.file %},{% endif %}
  {% if post.file %} [PDF](/papers/{{ post.file }}){% endif %}{% if post.appendix %},{% endif %}
  {% if post.appendix %} [Appendix](/papers/{{ post.appendix }}) {% endif %}
  )
{% endcapture %}
* {{ pub | strip_newlines }}
{% endfor %}

### Book Chapters

{% for post in site.categories.bookchap %}
{% capture pub %}
  {{ post.author }}. "**{{ post.title }}**." 
  In _{{ post.book }}_, Edited by {{ post.editor }}.
  {{ post.publisher }}.
  {% if post.city %} {{ post.city }}. {% endif %}
  {% if post.month %} {{ post.month }} {% endif %}
  {{ post.year }}.
  {% if post.isbn %} ISBN {{ post.isbn }} {% endif %}
  {% if post.abstract or post.link or post.file or post.appendix %}({% endif %}
  {% if post.abstract %} [Abstract]({{post.url}}){% if post.link or post.file %},{% endif %}{% endif %}
  {% if post.link %} [Link]({{post.link}}){% endif %}{% if post.link and post.file %},{% endif %}
  {% if post.file %} [PDF](/papers/{{ post.file }}){% endif %}{% if post.appendix %},{% endif %}
  {% if post.appendix %} [Appendix](/papers/{{ post.appendix }}) {% endif %}
  {% if post.abstract or post.link or post.file or post.appendix %}){% endif %}
{% endcapture %}
* {{ pub | strip_newlines }}
{% endfor %}

### Workshop Papers

{% for post in site.categories.workshop %}
{% capture pub %}
  {{ post.author }}. "**{{ post.title }}**" _{{ post.workshop }}_.
  {% if post.city %} {{ post.city }}. {% endif %}
  {% if post.month %} {{ post.month }} {% endif %}
  {{ post.year }}.
  {% if post.abstract or post.link or post.file or post.appendix %}({% endif %}
  {% if post.abstract %} [Abstract]({{post.url}}){% if post.link or post.file %},{% endif %}{% endif %}
  {% if post.link %} [Link]({{post.link}}){% endif %}{% if post.link and post.file %},{% endif %}
  {% if post.file %} [PDF](/papers/{{ post.file }}){% endif %}{% if post.appendix %},{% endif %}
  {% if post.appendix %} [Appendix](/papers/{{ post.appendix }}) {% endif %}
  {% if post.abstract or post.link or post.file or post.appendix %}){% endif %}
{% endcapture %}
* {{ pub | strip_newlines }}
{% endfor %}

### Working Papers

{% for post in site.categories.working %}
{% capture pub %}
  {{ post.author }}. "**{{ post.title }}**" _Working paper_.
  {% if post.month %} {{ post.month }} {% endif %}
  {{ post.year }}.
  (
  {% if post.project %} [Project page][{{post.project}}] {% endif %}
  {% if post.file %} [PDF](/papers/{{ post.file }}) {% endif %}
  )
{% endcapture %}
* {{ pub | strip_newlines }}
{% endfor %}

