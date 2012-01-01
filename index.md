---
layout: master
title: Rick Wash
---

I am an Assistant Professor at Michigan State University with a joint appointment in the School of
Journalism and the Department of Telecommunications, Information Studies and Media. I completed my
PhD at the School of Information at the University of Michigan working under Jeff MacKie-Mason. My
research focuses on understanding the motivations and incentives of users of social media systems,
and looking at how those incentives lead to group-level patterns of behavior.

Recent News
-----------

{% for post in site.categories.news %}
{% if post.link %}
* [{{ post.short }}]({{post.url}})
{% else %}
* {{ post.short }}
{% endif %}
{% endfor %}

