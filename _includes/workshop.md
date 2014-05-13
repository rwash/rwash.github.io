  {{ post.author }}. "**{{ post.title }}**." 
  {% if post.papertype %} {{ post.papertype }} in {% endif %}
  _{{ post.workshop }}_{% if post.conference %}, at {{ post.conference }}{% endif %}. 
  {% if post.city %} {{ post.city }}. {% endif %} 
  {% if post.month %} {{ post.month }} {% endif %}
  {{ post.year }}.

