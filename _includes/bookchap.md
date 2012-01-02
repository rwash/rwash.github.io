  {{ post.author }}. "**{{ post.title }}**."
  In _{{ post.book }}_, Edited by {{ post.editor }}.
  {{ post.publisher }}.
  {% if post.city %} {{ post.city }}. {% endif %}
  {% if post.month %} {{ post.month }} {% endif %}
  {{ post.year }}.
  {% if post.isbn %} ISBN {{ post.isbn }} {% endif %}
