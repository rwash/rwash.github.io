---
layout: master
title: Rick Wash
---

I am an Associate Professor at the [Information School](https://ischool.wisc.edu) at the University of Wisconsin,
Madison.  My research focuses on understanding how people think about and reason about their use of technology, with
particular focuses on information security, crowdsourcing, and online communities. 

Previously, I was an associate professor at Michigan State University, where I was one of the lead PIs in the 
[Behavior, Information, and Technology Lab](http://bitlab.cas.msu.edu) (BITLab) at MSU.

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

