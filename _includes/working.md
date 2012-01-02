  {{ post.author }}. "**{{ post.title }}**"
  {% if post.working %} _{{ post.working }}_. {% else %} _Working paper_. {% endif %}
  {% if post.month %} {{ post.month }} {% endif %}
  {{ post.year }}.

