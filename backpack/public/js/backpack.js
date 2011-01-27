(function(){
  var badges = $('li.badge')
  var containers = $('section')
  var update_badges = function(){
    badges = {
      'private': [],
      'public': [],
      'rejected': []
    }
    containers.find('ul').each(function(){
      var me = $(this)
      var visibility = me.attr('rel')
      me.find('li').each(function(){
        badges[visibility].push($(this).attr('id'))
      })
    })
    jQuery.post('/update-privacy', {badges: badges}, function(data){
      console.log(data)
    })
  }
  
  badges.bind('click', function(){
    console.log('clicked')
  })
  badges.draggable({
    opacity: 0.65,
    revert: "invalid",
    revertDuration: 250,
    helper: 'clone'
  })
  containers.droppable({
    hoverClass: 'drophover',
    drop: function(event, ui){
      var parent = $(this).find('ul')
      if (ui.draggable.parent() != parent) {
        ui.draggable.fadeOut(250, function(){
          parent.append(ui.draggable)
          ui.draggable.fadeIn(250)
          update_badges()
        })
        
      }
    }
  })
})()
