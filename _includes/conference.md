  {{ post.author }}. "**{{ post.title }}**" _{{ post.conference }}_.
  {% if post.city %} {{ post.city }}. {% endif %}
  {% if post.month %} {{ post.month }} {% endif %}
  {{ post.year }}.
  {% if post.award %} *[Won {{ post.award}}]* {% endif %}
