// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require jquery.scrollTo
// Required by Blacklight
//= require blacklight/blacklight
//= require_tree .
//= require bootstrap

function setup_div_toggle() {
  $('.collapse_icon').mouseover(function() {
    this.src = '/minimize_black.png';
  });
  $('.collapse_icon').mouseout(function() {
    this.src = '/minimize_grey.png';
  });
  $('.collapse_icon').click(function() {
    $(this).parent().next().slideToggle();
  });
}

function setup_hider() {
  $('.hider').click(function() {
    var hide_id = $(this).attr('data-hide-selector');
    if (hide_id) {
      $(hide_id).slideToggle();
    }
  });
}

function do_time_change(fragment) {
  fragment = fragment.replace(/#t=(.*)/, "$1");
  if (!fragment) {
    return;
  }

  var times = fragment.split(',');
  if (times.length != 2) {
    return;
  }

  var start = parseFloat(times[0]);
  var end = parseFloat(times[1]);

  var m;
  if ($('video').length) {
    m = $('video').first();
  } 
  else if ($('audio').length) {
    m = $('audio').first();
  }
  m.attr('data-start', start);
  m.attr('data-pause', end);
  m[0].currentTime = start;
  m.trigger('play');
}

function do_transcript_change(fragment) {
  var matches = fragment.match(/^#!\/p([^\/]*)(?:\/w([^\/]*))?(?:\/m([^\/]*))?/);
  var phrase_num = matches[1];
  var word_num = matches[2];
  var morpheme_num = matches[3];

  var phrase = '.phrase:eq(' + (phrase_num - 1) + ')';
  $('#transcript_display').scrollTo(phrase);

  var elem;
  if (word_num) {
    elem = phrase + ' .word:eq(' + (word_num - 1) + ')';

    if (morpheme_num) {
      elem = elem + ' .morpheme:eq(' + (morpheme_num - 1) + ')';
    }
  }

  jQuery('.impress').removeClass('impress');
  $(elem).addClass('impress');
}

// set url in current url box
function set_url(fragment) {
  var baseurl = window.location.protocol+"//"+window.location.host+window.location.pathname
  var url = baseurl + fragment;
  $('span#cur_url').html("<a href='"+url+"'>"+url+"</a>");  
}

// changing URL hash on window
function do_fragment_change() {
  var fragment = window.location.hash;
  set_url(fragment);

  if (fragment.match(/^#t=/)) {
    do_time_change(fragment);
  }
  else if (fragment.match(/^#!/)) {
    do_transcript_change(fragment);
  }
}

function setup_embedding() {
  $('#embed_code').click(function() {
    $(this).focus();
    $(this).select();
  });
}

function setup_playback(media) {
  // on timeupdate check if we are still playing and adjust the highlighted region
  media.bind('timeupdate', function() {
    // var cur_time = parseFloat(media.attr('currentTime'));
    var cur_time = parseFloat(media[0].currentTime);
    if (media.attr('paused') || media.attr('ended')) {
      return;
    }
    // highlight and scroll to currently playing time offset
    $('.play_button').each(function(index) {
      if (cur_time >= (parseFloat($(this).attr('data-start'))) &&
          cur_time < parseFloat($(this).attr('data-end'))) {
        var line = $(this).closest('.line');
        if (!line.find('.tracks').hasClass('highlight')) {
          // check if we have to scroll
          var scroller = $('#transcript_display');
          var bottom_s = scroller.offset().top+scroller.height();
          var bottom_l = line.offset().top+line.height();
          if ((bottom_l > (bottom_s-20)) ||
              (line.offset().top < scroller.offset().top)) {
            scroller.scrollTo(line, 500, {offset: -20, easing: 'linear'});
          }
          // highlight currently playing track
          line.find('.tracks').addClass('hilight');

          // change hash on URL in cur_url textarea
          set_url("#t="+$(this).attr('data-start')+","+$(this).attr('data-end'));
        }
      } 
      else {
        $(this).closest('.line').find('.tracks').removeClass('hilight');
      }      
    });

    // pause the video if we played past the last segment
    if (cur_time > (parseFloat($('.play_button').last().attr('data-end')))) {
      media.trigger('pause');
      media.attr('data-pause', '');
    }

    // Pause the video if we played a segment and it's finished
    var pause_time = parseFloat(media.attr('data-pause'))+0.1;
    if (pause_time) {
      // we've just gone past the end of the segment, trigger a pause
      if (Math.abs(cur_time - pause_time) < 0.1 && Math.abs(cur_time - pause_time) > 0.0) {
        media.trigger('pause');
        media.attr('data-pause', '');
      }
      // Something weird happend and we missed the pause
      // maybe user skipped ahead; so just reset the data-pause attribute
      if (media.attr('currentTime') > pause_time) {
        media.attr('data-pause', '');
      }
    }
  });

  $('a.play_button').click(function() {
    // need to reset it first in case we have moved past the phrase so it actually does something
    window.location.hash = "";
    window.location.hash = "t="+ $(this).attr('href').replace(/.*#t=(.*)/, "$1");
  });
}

$(document).ready(function() {
  // Get media element
  var media;
  if ($('video').length) {
    media = $('video').first();
  } 
  else if ($('audio').length) {
    media = $('audio').first();
  }
  set_url("");

  // also act on hash change of page
  $(window).bind('hashchange', function() {
    do_fragment_change();    
  });

  // Collapsing elements
  setup_div_toggle();
  setup_hider();
  setup_embedding();

  // Country Code Selector
  // setup_country_code();

  // Transcript box 
  // do_onResize();
  $(window).resize(do_onResize);

  // Form bits
  // setup_transcript_media_item();

  // Search
  // setup_concordance();
  // setup_validations();

  // if the page is loaded with a different hash, execute that
  if (media) {
    media.bind('loadedmetadata', do_fragment_change);
    setup_playback(media)
  }
  else {
    do_fragment_change();
  }


});