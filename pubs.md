---
title: Publications
published: true
layout: master
---

### Journal Papers

{% for post in site.categories.journal %}
{% capture pub %}
  {% include journal.md %}
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
{% include conference.md %}
  (
  [Abstract]({{post.url}}){% if post.link or post.file %},{% endif %}
  {% if post.link %} [Link]({{post.link}}){% endif %}{% if post.link and post.file %},{% endif %}
  {% if post.file %} [PDF](/papers/{{ post.file }}){% endif %}{% if post.acmdl %},{% endif %}
  {% if post.acmdl %} [ACM DL]({{post.acmdl}}){% endif %}{% if post.appendix %},{% endif %}
  {% if post.appendix %} [Appendix](/papers/{{ post.appendix }}) {% endif %}
{% comment %}  {% if post.doi %} DOI [{{ post.doi }}](http://dx.doi.org/{{ post.doi }}) {% endif %} {% endcomment %}
  )
{% endcapture %}
* {{ pub | strip_newlines }}
{% endfor %}

### Book Chapters

{% for post in site.categories.bookchap %}
{% capture pub %}
  {% include bookchap.md %}
  {% if post.abstract or post.link or post.file or post.appendix %}({% endif %}
  {% if post.abstract %} [Abstract]({{post.url}}){% if post.link or post.file %},{% endif %}{% endif %}
  {% if post.link %} [Link]({{post.link}}){% endif %}{% if post.link and post.file %},{% endif %}
  {% if post.file %} [PDF](/papers/{{ post.file }}){% endif %}{% if post.appendix %},{% endif %}
  {% if post.appendix %} [Appendix](/papers/{{ post.appendix }}) {% endif %}
  {% if post.abstract or post.link or post.file or post.appendix %}){% endif %}
{% endcapture %}
* {{ pub | strip_newlines }}
{% endfor %}

### Magazine Articles

{% for post in site.categories.magazine %}
{% capture pub %}
  {% include magazine.md %}
  (
  [Abstract]({{post.url}}){% if post.link or post.file %},{% endif %}
  {% if post.link %} [Link]({{post.link}}){% endif %}{% if post.link and post.file %},{% endif %}
  {% if post.file %} [PDF](/papers/{{ post.file }}){% endif %}{% if post.acmdl %},{% endif %}
  {% if post.acmdl %} [ACM DL]({{post.acmdl}}){% endif %}{% if post.appendix %},{% endif %}
  {% if post.appendix %} [Appendix](/papers/{{ post.appendix }}) {% endif %}
{% comment %}  {% if post.doi %} DOI [{{ post.doi }}](http://dx.doi.org/{{ post.doi }}) {% endif %} {% endcomment %}
  )
{% endcapture %}
* {{ pub | strip_newlines }}
{% endfor %}

### Workshop Papers

{% for post in site.categories.workshop %}
{% capture pub %}
  {% include workshop.md %}
  {% if post.abstract or post.link or post.file or post.poster or post.appendix %}({% endif %}
  {% if post.abstract %} [Abstract]({{post.url}}){% if post.link or post.file %},{% endif %}{% endif %}
  {% if post.link %} [Link]({{post.link}}){% endif %}{% if post.link and post.file %},{% endif %}
  {% if post.file %} [PDF](/papers/{{ post.file }}){% endif %}{% if post.appendix or post.poster %},{% endif %}
  {% if post.appendix %} [Appendix](/papers/{{ post.appendix }}) {% endif %}
  {% if post.poster %} [Poster](/papers/{{ post.poster }}) {% endif %}
  {% if post.abstract or post.link or post.file or post.poster or post.appendix %}){% endif %}
{% endcapture %}
* {{ pub | strip_newlines }}
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

