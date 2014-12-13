---
layout: master
title: Publications during Tenure Review Period
---

### Research works during the tenure review period (2010 -- present)

Authors are ordered by amount of contribution; the first listed author had the largest contribution, the second listed author the second, and so on.  
\* Indicates peer-reviewed publications

#### Journal Papers (all strictly peer reviewed)

{% for post in site.categories.journal %}{%if post.year >= 2010 %} {% capture pub %}
  {% include journal.md %}
  {% if post.link %} <{{post.link}}>{% endif %}
{% endcapture %} * \*{{ pub | strip_newlines }}
{% endif %}{% endfor %}

#### Conference Proceedings (all strictly peer reviewed)

{% for post in site.categories.conference %}{% if post.year >= 2010 %} {% capture pub %}
  {% include conference.md %}
  {% if post.doi %} DOI [{{ post.doi }}](http://dx.doi.org/{{ post.doi }}) {% endif %}
{% endcapture %} * \*{{ pub | strip_newlines | strip_html }}
{% endif %}{% endfor %}

#### Book Chapters (invited)

{% for post in site.categories.bookchap %}{% if post.year >= 2010 %} {% capture pub %}
  {% include bookchap.md %}
{% endcapture %} * {{ pub | strip_newlines }}
{% endif %}{% endfor %}

#### Magazine Articles (invited)

{% for post in site.categories.magazine %}{% if post.year >= 2010 %} {% capture pub %}
  {% include magazine.md %}
{% endcapture %} * {{ pub | strip_newlines }}
{% endif %}{% endfor %}

#### Workshop Papers (lightly peer reviewed)

{% for post in site.categories.workshop %}{% if post.year >= 2010 %} {% capture pub %}
  {% include workshop.md %}
{% endcapture %} * {{ pub | strip_newlines }}
{% endif %}{% endfor %}

#### Invited Talks

* Rick Wash and Emilee Rader. "Influencing Mental Models of Security." At Lansing Torch Club, East Lansing, MI. (2014)
* Rick Wash. "Folk Security." At *Indiana University, School of Informatics*. (2013)
* Rick Wash. "Thinking and Talking About Security." At *Indiana University, School of Informatics*. (2012)
* Rick Wash. "Thinking and Talking About Security." At *Cornell University, Information Science Colloquium*. (2012)

#### Patents

* US Patent #7,890,338: Method for Managing a Whitelist.  Inventors: Theodore C Loder, Marshall van Alstyne, Richard L Wash. Issued February 15, 2011 
