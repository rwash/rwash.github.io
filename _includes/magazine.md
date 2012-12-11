  {{ post.author }}. "**{{ post.title }}**" _{{ post.magazine }}_.
  {% if post.volume %} Vol. {{ post.volume }} {% endif %}
  {% if post.number %} No. {{ post.number }} {% endif %}
  {% if post.pages %} pp. {{ post.pages }}. {% endif %}
  {% if post.month %} {{ post.month }} {% endif %}
  {{ post.year }}.
