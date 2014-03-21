---
layout: master
title: Rick Wash
---

I am an Assistant Professor at Michigan State University with a joint appointment in the School of Journalism and the
Department of Telecommunications, Information Studies and Media. My research focuses on understanding how people think
about and reason about their use of technology, with particular focuses on information security, crowdsourcing, and
online communities. I completed my PhD at the School of Information at the University of Michigan working under Jeff
MacKie-Mason. 

I am one of the lead PIs in the [Behavior, Information, and Technology Lab](http://bitlab.cas.msu.edu) (BITLab) at MSU.
Most of my research projects are coordinated through that website.

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

