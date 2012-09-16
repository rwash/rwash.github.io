---
layout: master
title: Rick Wash
---

I am an Assistant Professor at Michigan State University with a joint appointment in the School of Journalism and the
Department of Telecommunications, Information Studies and Media. I completed my PhD at the School of Information at the
University of Michigan working under Jeff MacKie-Mason. My research focuses on understanding the motivations and
incentives of users of social media systems, and looking at how those incentives lead to group-level patterns of
behavior.

I am one of the lead PIs in the [Behavior, Information, and Technology Lab](http://bitlab.cas.msu.edu) (BITLab) at MSU.
Most of my research projects are coordinated through that website.

For more information, see my [Google Citations profile](http://scholar.google.com/citations?user=ef0ApTwAAAAJ).

Recent News
-----------

{% for post in site.categories.news limit:site.news %}
{% if post.link %}
* {{ post.short }} ([more info]({{post.url}}))
{% else %}
* {{ post.short }}
{% endif %}
{% endfor %}

