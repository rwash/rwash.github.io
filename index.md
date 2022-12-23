---
layout: master
title: Rick Wash
---

I am an Associate Professor at Michigan State University in the Department of
Media and Information. My research focuses on understanding how people think
about and reason about their use of technology, with particular focuses on
information security, crowdsourcing, and online communities. 

I was one of the lead PIs in the [Behavior, Information, and Technology Lab](http://bitlab.cas.msu.edu) (BITLab) at MSU.
Many of my research projects are coordinated through that website.

For more information about my research publications, see my [Google Citations profile](http://scholar.google.com/citations?user=ef0ApTwAAAAJ).



Recent News
-----------

{% for post in site.categories.news limit:site.news %}
{% if post.link %}
* {{ post.short }} ([more info]({{post.url}}))
{% else %}
* {{ post.short }}
{% endif %}
{% endfor %}

