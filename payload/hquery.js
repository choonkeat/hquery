jQuery(document).ready(function() {
  function padded_space(count) {
    if (count < 1) return "";
    return "&nbsp;" + padded_space(count-1);
  }
  
  function element2css(element, level) {
    level = (level || 0);
    if (!element || !element.nodeName || element.nodeName.match(/^\s*\/|\#text/)) {
      // wierd that IE6 lets "</abbr>" comes through here?
      return;
    }
    var csspath_str = csspath2text(element, level);
    var identity = [["<span title='", csspath_str, "' class='tag'>", element.nodeName.toLowerCase(), "</span>"].join('')];
    if (element.id) {
      identity.push(["<span title='", csspath_str, "' class='id'>#", element.id, "</span>"].join(''));
    }
    if (element.className && element.className != "") {
      identity.push(["<span title='", csspath_str, "' class='class'>.",
        element.className.split(' ').join("</span><span title='", csspath_str, "' class='class'>."),
        "</span>"].join(''));
    }
    var children = [];
    jQuery(element).children().each(function(index, child) {
      children.push(element2css(child, level + 1));
    });

    return (["<div class='block'>", padded_space(level * 2), identity.join(''), children.join(''), "</div>"].join(''));
  }
  function csspath2text(ele, level) {
    function identify(element) {
      var identity = [element.nodeName.toLowerCase()];
      if (element.id) {
        identity.push(["#", element.id].join(''));
      }
      if (element.className && element.className != "") {
        identity.push([".",
          element.className.split(' ').join("."),
          ""].join(''));
      }
      return identity;
    }
    var path = [identify(ele)];
    jQuery(ele).parents().each(function(index, element) {
      var identity = identify(element);
      if (element.nodeName.toLowerCase() == 'html' || (level && index >= level)) {
        // ignore <html>
      } else {
        path.unshift(identity.join(''));
      }
    })
    return path.join(' ');
  }
  function csspath2html(ele) {
    var path = [];
    jQuery(ele).parents().each(function(index, element) {
      var csspath_str = csspath2text(element);
      var identity = [["<span title='", csspath_str, "' class='tag'>", element.nodeName.toLowerCase(), "</span>"].join('')];
      if (element.id) {
        identity.push(["<span title='", csspath_str, "' class='id'>#", element.id, "</span>"].join(''));
      }
      if (element.className && element.className != "") {
        identity.push(["<span title='", csspath_str, "' class='class'>.",
          element.className.split(' ').join("</span><span title='", csspath_str, "' class='class'>."),
          "</span>"].join(''));
      }
      if (element.nodeName.toLowerCase() == 'html') {
        // ignore <html>
      } else {
        path.unshift(identity.join(''));
      }
    })
    return path.join(' ');
  }
  function inspect_element(target) {
    if ((target.id == 'hquery_display') || jQuery(target).parents('#hquery_display').length > 0) {
      if (jQuery(target).hasClass('close')) {
        jQuery('#hquery_display').fadeOut('slow', function() { jQuery(this).remove(); });
      } else {
        var new_target = jQuery(target.title, this.prev_target);
        if (new_target.length < 1) new_target = jQuery(target.title);
        if (new_target.length > 0) inspect_element(new_target[0]);
      }
    } else {
      jQuery('#hquery_display').fadeOut('fast', function() { jQuery(this).remove(); });
      var domobj = jQuery(target);
      var children = [];
      domobj.each(function(index, child) {
        children.push(element2css(child, 0));
      });
      var new_output = jQuery("<div id='hquery_display'>" + 
        "<div class='close'>close</div>" +
        "<h2>Path:</h2>" +
        "<div class='csspath'>" + csspath2html(target) + "</div>" +
        "<h2>Structure:</h2>" +
        children.join('') + 
        "</div>");
      new_output.css({
        'left': 10, // ((jQuery(window).width() - new_output.width()) / 4),
        'top':  (jQuery(window).scrollTop() + 10),
      }).hide();
      new_output.appendTo(document.body);
      new_output.fadeIn('slow');
      this.prev_target = target;
    }
  }
  jQuery(document.body).click(function(evt) {
    var target = evt.target;
    inspect_element(target);
    return false;
  }).mouseover(function(evt) {
    var target = evt.target;
    if ((target.id == 'hquery_display') || jQuery(target).parents('#hquery_display').length > 0) {
      //
    } else {
      if (!target.old_bg) target.old_bg = jQuery(target).css('background');
      jQuery(target).css('background', 'rgb(255, 255, 128)');
    }
  }).mouseout(function(evt) {
    var target = evt.target;
    if ((target.id == 'hquery_display') || jQuery(target).parents('#hquery_display').length > 0) {
      //
    } else {
      jQuery(target).css('background', target.old_bg || '');
    }
  });
});