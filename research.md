---
layout: master
title: Research
---

I have three active projects going right now.  Each project, though, often has
multiple studies and papers. In general, I am interested in how people reason
about and make decisions about using technology, and then how we can better
design those technologies to work with those reasoning processes to create
valuable socio-technical systems.

Socio-Technical Design of Crowdfunding Websites
-----------------------------------------------
Crowdfunding websites like Kickstarter.com and Spot.us allow anyone to post
project ideas and solicit donations. These systems create a two-sided matching
market: interested donors need to be matched with interesting projects.
However, there is a complication: projects need a minimum amount of money to be
likely to succeed.  I am studying how the rules and technologies that support
such websites can be designed to create efficient donations and to encourage
participation and donation. 

{% for post in site.categories.papers %}
{% if post.tags contains 'crowdfunding' %}
{% capture pub %}
{% include paper.md %}
{% endcapture %}
* {{ pub | strip_newlines }}
{% endif %}
{% endfor %}


Influencing Mental Models of Security
-------------------------------------
Many people have computers in their homes. But unlike computers located in
businesses, these computers are administered largely byuntrained home users.
This has led to many of these computers being the victims of numerous computer
crimes. I am investigating how homecomputer users think about the process of
securing their home computers: what are the threats that they face, and how do
they dealwith those threats?  In addition, I am looking at how we can change
people's understanding -- their mental models of security threats -- in a way that
will lead to better security decisions. 

{% for post in site.categories.papers %}
{% if post.tags contains 'securitymodels' %}
{% capture pub %}
{% include paper.md %}
{% endcapture %}
* {{ pub | strip_newlines }}
{% endif %}
{% endfor %}


Mental Models, Expectations, and Critical Mass in Online Communities
--------------------------------------------------------------

Social media systems require user participation and user contribution in order
to succeed.  However, users' participation decisions are not made in isolation;
there is a strong feedback influence.  People only choose to participate in
social media systems based on what contributions they see others making, and
their expectations about the future of the social media system.  I am
investigating how this process works, how we can "bootstrap" this process at the
beginning of the life of a social media system, and how it eventually produces a
"critical mass" of self-sustaining contributions.

{% for post in site.categories.papers %}
{% if post.tags contains 'onlinecommunities' %}
{% capture pub %}
{% include paper.md %}
{% endcapture %}
* {{ pub | strip_newlines }}
{% endif %}
{% endfor %}
