$(function(){
   var path = location.pathname.substring(1);
   if ( path )
     $('#nav a[href$="' + path + '"]').parent().attr('class', 'active');
   else
     $('#nav a[href$="index.html"]').parent().attr('class', 'active');
 });
