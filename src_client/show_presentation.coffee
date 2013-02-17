###
Presentz.org - A website to publish presentations with video and slides synchronized.

Copyright (C) 2012 Federico Fissore

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
###

"use strict"

PLAY_ON_LOAD = true

Controls =

  resize_timeout: null

  init: () ->
    Controls.resize()

    $agenda_chapters = $("#controls .chapter")
    totalChapters = $agenda_chapters.length
    $agenda_chapters.each () ->
      $instance = $(this)

      $instance.unbind("mouseenter").bind "mouseenter", () ->
        if Controls.resize_timeout?
          clearTimeout(Controls.resize_timeout)
          Controls.restoreOriginalWidth()
          Controls.resize_timeout = null

        selectedChapterWidth = $("#controls").width() + 1 - (totalChapters * 2)

        $agenda_chapters.not($instance).css "width", "2px"

        $instance.css("width", "#{selectedChapterWidth}px")
        $instance.find(".info").stop(true, true).delay(200).fadeIn(500)

      $instance.unbind("mouseleave").bind "mouseleave", () ->
        Controls.resize_timeout = setTimeout(Controls.restoreOriginalWidth, 400)

    $chapters = $("#controls .chapter, #chapters ol li")
    $chapters.unbind("click").bind "click", (e) ->
      $this = $(e.target)
      if $this.hasClass("comments") or $this.parent(".comments").length > 0
        $this = $this.parent()
        show_comments_for_slide $this.attr("chapter_index"), $this.attr("slide_index")
        show "#comments"
      else
        $("html:not(:animated),body:not(:animated)").animate({ scrollTop: $("div.main h3").position().top }, 400)
        if !$this.is("a")
          #"this" is NOT a typo
          $this = $(".info .title a", this)
        prsntz.changeChapter parseInt($this.attr("chapter_index")), parseInt($this.attr("slide_index")), PLAY_ON_LOAD, (err) ->
          alert(err) if err?
      false

    Controls.bind_link_to_slides_from_comments()

    $previous_slide = $("#prev_slide")
    $previous_slide.unbind("click").bind "click", ->
      prsntz.previous()
      false

    $next_slide = $("#next_slide")
    $next_slide.unbind("click").bind "click", ->
      prsntz.next()
      false

  bind_link_to_slides_from_comments: () ->
    $slides_in_comments = $("a.slide_title")
    $slides_in_comments.unbind("click").bind "click", (e) ->
      $("html:not(:animated),body:not(:animated)").animate({ scrollTop: $("div.main h3").position().top }, 400)
      $this = $(e.target).parent().parent()
      prsntz.changeChapter parseInt($this.attr("chapter_index")), parseInt($this.attr("slide_index")), PLAY_ON_LOAD, (err) ->
        alert(err) if err?
      false

  restoreOriginalWidth: () ->
    $("#controls .chapter").each () ->
      $(this).find(".info").stop(true, true).hide()
    Controls.resize()

  resize: () ->
    container_width = $("#controls").width()
    min_pixel_width = 2
    min_pixel_width_as_percentage = 100 * min_pixel_width / container_width
    $chapters = $("#controls .chapter")
    stolen_percentage = 0
    long_chapters_percentage = 0
    percentages = []

    #gather percentages and fix them if too low, accumulating stolen_percentage
    for chapter in $chapters
      $chapter = $(chapter)
      percentage = parseFloat($chapter.attr("percentage"))
      if percentage < min_pixel_width_as_percentage
        stolen_percentage += (min_pixel_width_as_percentage - percentage)
        percentage = min_pixel_width_as_percentage
      else
        long_chapters_percentage += percentage
      percentages.push(percentage)

    #resize chapters considering stolen_percentage and fix small chapters
    long_chapter_removed = false
    rounds = 0
    fix_as_many_small_chapters_as_possibile = () ->
      long_chapter_removed = false
      percentage_to_remove_from_long_chapters = 100 * stolen_percentage / long_chapters_percentage
      for percentage in percentages
        if percentage > min_pixel_width_as_percentage
          new_percentage = percentage - (percentage / 100 * percentage_to_remove_from_long_chapters)
          if new_percentage < min_pixel_width_as_percentage
            min_pixel_width_as_percentage = percentage
            long_chapter_removed = true
            long_chapters_percentage -= percentage
      rounds++
    fix_as_many_small_chapters_as_possibile()
    fix_as_many_small_chapters_as_possibile() while long_chapter_removed and rounds < 6

    #now percentages should be correct, lets rewrite the original ones
    percentage_to_remove_from_long_chapters = 100 * stolen_percentage / long_chapters_percentage
    for percentage, idx in percentages
      if percentage > min_pixel_width_as_percentage
        percentage -= (percentage / 100 * percentage_to_remove_from_long_chapters)
        percentages[idx] = percentage

    #percentages to pixels
    sum_of_pixels = 0
    pixel_widths = []
    for percentage in percentages
      chapter_pixels = Math.floor(container_width / 100 * percentage)
      sum_of_pixels += chapter_pixels
      pixel_widths.push(chapter_pixels)

    if sum_of_pixels > 0
      #some pixel may still be missing, lets spread them
      while (container_width - sum_of_pixels) > 0
        for pixel_width, idx in pixel_widths when (container_width - sum_of_pixels) > 0
          pixel_widths[idx] = pixel_widths[idx] + 1
          sum_of_pixels += 1

    #now give each div its width in pixel
    for pixel_width, idx in pixel_widths
      $($chapters[idx]).css("width", "#{pixel_widths[idx]}px")

prsntz = new Presentz("#player_video", "460x420", "#slideshow_player", "460x420")

youtube_ready = false
presentation_ready = false
slides_hidden = false

init_presentz = (presentation) ->
  window.presentation = presentation

  oneBasedAbsoluteSlideIndex = (presentation, chapter_index, slide_index) ->
    absoluteSlideIndex = 0
    if chapter_index > 0
      for idx in [0...chapter_index]
        absoluteSlideIndex += presentation.chapters[idx].slides.length

    absoluteSlideIndex + slide_index + 1

  prsntz.on "slidechange", (previous_chapter_index, previous_slide_index, new_chapter_index, new_slide_index) ->
    hide_show_slides(new_chapter_index, new_slide_index, 500)

    fromSlide = oneBasedAbsoluteSlideIndex window.presentation, previous_chapter_index, previous_slide_index
    $from = $("#controls .chapter:nth-child(#{fromSlide}), #chapters ol li:nth-child(#{fromSlide}) a:nth-child(1)")
    $from.removeClass "selected"
    $from.addClass "past"

    toSlide = oneBasedAbsoluteSlideIndex window.presentation, new_chapter_index, new_slide_index
    $to = $("#controls .chapter:nth-child(#{toSlide}), #chapters ol li:nth-child(#{toSlide}) a:nth-child(1)")
    $to.removeClass "past"
    $to.addClass "selected"

    window.current_chapter = new_chapter_index
    window.current_slide = new_slide_index
    show_comments_for_slide(new_chapter_index, new_slide_index)
    return

  prsntz.init window.presentation
  prsntz.changeChapter 0, 0, PLAY_ON_LOAD, (err) ->
    alert(err) if err?

  return

hide_show_slides = (chapter_index, slide_index, duration = 0) ->
  real_hide_show_slide = () ->
    $player_video = $("#player_video")
    $slideshow_player = $("#slideshow_player")
    starting_width = parseInt($player_video.css("width"))
    if !presentation.chapters[chapter_index].slides[slide_index].url? and !slides_hidden
      $slideshow_player.hide()
      $player_video.animate { width: "#{starting_width * 2 + 20}px" }, duration
      slides_hidden = true
    else if presentation.chapters[chapter_index].slides[slide_index].url? and slides_hidden
      $player_video.animate { width: "#{starting_width / 2 - 10}px" }, duration, () ->
       $slideshow_player.show()
      slides_hidden = false
  
  setTimeout real_hide_show_slide, 500

openPopupTo = (width, height, url) ->
  left = (screen.width - width) / 2
  left = 0 if left < 0

  top = (screen.height - height) / 2
  top = 0 if top < 0

  window.open url, "share", "height=#{height},location=no,menubar=no,width=#{width},top=#{top},left=#{left}"
  return

fbShare = () ->
  openPopupTo 640, 350, "https://www.facebook.com/sharer.php?u=#{encodeURIComponent(document.location)}&t=#{encodeURIComponent(document.title)}"
  return

twitterShare = () ->
  openPopupTo 640, 300, "https://twitter.com/intent/tweet?text=#{encodeURIComponent("#{document.title} #{document.location} via @presentzorg")}"
  return

plusShare = () ->
  openPopupTo 640, 350, "https://plus.google.com/share?url=#{encodeURIComponent(document.location)}"
  return

hide = (to_hide_selector) ->
  $(to_hide_selector).css "display", "none"
  true

show = (to_show_selector) ->
  hide "#player .box8, #player .box8 #comment_form"
  $to_show_selector = $(to_show_selector)
  $(to_show_selector).css "display", ""

  $player_video = $("#player_video")
  if $to_show_selector.height() < $player_video.height()
    scroll_destination = $to_show_selector.height() + $player_video.position().top + 31
  else
    scroll_destination = $to_show_selector.offset().top - ($player_video.position().top + 3)

  if $(window).scrollTop() < scroll_destination
    $("html:not(:animated),body:not(:animated)").animate({ scrollTop: scroll_destination }, 400)

  false

show_comments_for_slide = (chapter, slide) ->
  $("#comments div.item_comment").each (idx, elem) ->
    $elem = $(elem)
    if $elem.attr("chapter_index") isnt "#{chapter}" or $elem.attr("slide_index") isnt "#{slide}"
      $elem.hide()
    else
      $elem.show()

comment_this_slide = (to_show_selector, notify_label_selector) ->
  comment to_show_selector, window.current_chapter, window.current_slide
  title = presentation.chapters[window.current_chapter].slides[window.current_slide].title
  if title?
    $(notify_label_selector).text "slide \"#{title}\""
  else
    $(notify_label_selector).text "slide #{window.current_slide + 1}"
  show_comments_for_slide(window.current_chapter, window.current_slide)
  false

comment_this_presentation = (to_show_selector, notify_label_selector) ->
  comment to_show_selector, "", ""
  $(notify_label_selector).text "the presentation"
  show_comments_for_slide("", "")
  false

comment = (to_show_selector, chapter_index_val, slide_index_val) ->
  show to_show_selector
  prsntz.pause()
  $("#comment_form form input[name=chapter_index]").val chapter_index_val
  $("#comment_form form input[name=slide_index]").val slide_index_val
  true

insert_new_comment = ($container, chapter, slide, new_comment_html) ->
  if $("div.item_comment", $container).length is 0
    $("div.content_comments", $container).append(new_comment_html)
    return

  if chapter is "" and slide is ""
    $("div.item_comment", $container).first().before(new_comment_html)
    return

  if $("div.item_comment[chapter_index=#{chapter}][slide_index=#{slide}]", $container).length isnt 0
    $("div.item_comment[chapter_index=#{chapter}][slide_index=#{slide}]", $container).first().before(new_comment_html)
    return

  chapter = parseInt(chapter)
  slide = parseInt(slide)
  $target_comment = undefined
  for c in $("div.item_comment", $container) when !$target_comment?
    $comment = $(c)
    current_chapter = parseInt($comment.attr("chapter_index"))
    current_slide = parseInt($comment.attr("slide_index"))
    if current_chapter > chapter or (current_chapter is chapter and current_slide > slide)
      $target_comment = $comment

  if $target_comment?
    $target_comment.before(new_comment_html)
    return

  $("div.content_comments", $container).append(new_comment_html)

fullscreen_selectors = []
fullscreen_active = false
fullscreen_deactivate_called = false

fullscreen_activate = (event) ->
  $fullscreen = $("#fullscreen")
  $fullscreen.toggleClass("enter_fullscreen exit_fullscreen")
  $(window).scrollTop(0)
  $("div.main h3, div.main h4, #tools, #header, #footer, #allcomments, #comments, #chapters, #embed, #share").hide()

  new_width = $(window).width()
  ratio = new_width / parseInt($("div.main").css("width"))
  fullscreen_selectors.push("div.main")
  $("div.main").css({ "width": new_width })

  fullscreen_selectors.push("#player")
  $("#player").css({ "margin-top": 10 })

  fullscreen_selectors.push("#player_video")
  $("#player_video").css({"width": Math.floor(parseInt($("#player_video").css("width")) * ratio) + 11, "height": Math.floor(parseInt($("#player_video").css("height")) * ratio) + 11, "margin-left": 5, "margin-right": 5})
  fullscreen_selectors.push("#slideshow_player")
  $("#slideshow_player").css({"width": Math.floor(parseInt($("#slideshow_player").css("width")) * ratio) + 11, "height": Math.floor(parseInt($("#slideshow_player").css("height")) * ratio) + 11, "margin-left": 5, "margin-right": 5})

  fullscreen_selectors.push("#site_wrapper")
  $("#site_wrapper").css({"padding-bottom": 0, display: "table-cell", "vertical-align": "middle"})

  fullscreen_selectors.push("#wrapper")
  $("#wrapper").css({ display: "table", height: 400, overflow: "hidden"})

  fullscreen_selectors.push("body")
  $("body").css({ "background-color": $("#presentation").css("background-color") })

  window_width = $(window).width()
  if window_width >= 1257
    fullscreen_selectors.push("#controls_slide")
    if window_width < 1587
      $("#controls_slide").css({ "padding-left": 5 })
    else
      $("#controls_slide").css({ "padding-left": 0 })

  fullscreen_selectors.push("#controls")
  $("#controls").css({ "width": $("#player").width() - 25, "margin-left": 5 })
  Controls.restoreOriginalWidth();

  $fullscreen.unbind("click").bind("click", fullscreen_de_activate)

  elem = document.body
  if elem.requestFullScreen?
    elem.requestFullScreen()
  else if elem.mozRequestFullScreen?
    elem.mozRequestFullScreen()
  else if elem.webkitRequestFullScreen?
    elem.webkitRequestFullScreen()
  else
    fullscreen_active = true

  false

fullscreen_de_activate = (event) ->
  fullscreen_deactivate_called = true

  $fullscreen = $("#fullscreen")
  $fullscreen.toggleClass("enter_fullscreen exit_fullscreen")
  $("div.main h3, div.main h4, #tools, #header, #footer").show()
  $(selector).attr("style", "") for selector in fullscreen_selectors
  slides_hidden = false
  hide_show_slides(current_chapter, current_slide)
  Controls.restoreOriginalWidth()
  $fullscreen.unbind("click").bind("click", fullscreen_activate)

  if document.cancelFullScreen?
    document.cancelFullScreen()
  else if document.mozCancelFullScreen?
    document.mozCancelFullScreen()
  else if document.webkitCancelFullScreen?
    document.webkitCancelFullScreen()
  else
    fullscreen_active = false

  false

toggle_fullscreen_active = () ->
  fullscreen_de_activate() if fullscreen_active and !fullscreen_deactivate_called
  fullscreen_active = !fullscreen_active
  fullscreen_deactivate_called = false

mejs.MediaElementDefaults.pluginPath = "/assets/img/mediaelementjs/"

window.init_presentz = init_presentz
window.fbShare = fbShare
window.twitterShare = twitterShare
window.plusShare = plusShare
window.hide = hide
window.show = show
window.comment_this_slide = comment_this_slide
window.comment_this_presentation = comment_this_presentation

$().ready () ->
  Controls.init()

  $window = $(window)
  $window.unbind("resize").bind "resize", () ->
    Controls.resize() if $("#controls").length > 0

  $("#comment_form form").submit (e) ->
    $submit = $("input[type=submit]", @)
    $submit.attr("disabled", true)

    $textarea = $(e.currentTarget.comment)
    text = $.trim($textarea.val())
    return false if text is ""

    $chapter_index = $(e.currentTarget.chapter_index)
    chapter_index_val = $chapter_index.val()
    $slide_index = $(e.currentTarget.slide_index)
    slide_index_val = $slide_index.val()

    $.ajax
      type: "POST"
      url: "#{document.location}/comment"
      data:
        comment: text
        chapter: chapter_index_val
        slide: slide_index_val
      success: (new_comment_html) ->
        insert_new_comment($("#comments"), chapter_index_val, slide_index_val, new_comment_html)
        insert_new_comment($("#allcomments"), chapter_index_val, slide_index_val, new_comment_html)
        Controls.bind_link_to_slides_from_comments()
        #$new_comment = $("div.item_comment[chapter_index=#{$chapter_index.val()}][slide_index=#{$slide_index.val()}]").first()
        #$("p", $new_comment).effect("highlight", {color: "#5d7908"}, 1500)
        prsntz.play()
        hide "#comment_form"
        $textarea.val ""
        $chapter_index.val ""
        $slide_index.val ""
        $submit.attr("disabled", false)
      error: () ->
        $submit.attr("disabled", false)
        alert("An error occured while saving your comment")
    false

  $li_share_facebook = $("#share li.li_share_facebook")
  $li_share_facebook.unbind("click").bind "click", () ->
    fbShare()
    false
  $li_share_twitter = $("#share li.li_share_twitter")
  $li_share_twitter.unbind("click").bind "click", () ->
    twitterShare()
    false
  $li_share_gplus = $("#share li.li_share_gplus")
  $li_share_gplus.unbind("click").bind "click", () ->
    plusShare()
    false

  #ensure speakerdeck iframe has not width/height, so it becomes responsive
  speakerdeck_message = (event) ->
    return if event.origin.indexOf("speakerdeck.com") is -1
    $speakerdeck_iframe = $("iframe.speakerdeck-iframe")
    $speakerdeck_iframe.css({"width": "100%", "height": "100%" })

  window.addEventListener "message", speakerdeck_message, false

  $(document).bind("fullscreenchange", toggle_fullscreen_active)
  $(document).bind("webkitfullscreenchange", toggle_fullscreen_active)
  $(document).bind("mozfullscreenchange", toggle_fullscreen_active)

  $("#fullscreen").unbind("click").bind "click", fullscreen_activate

  $document = $(document)
  $document.unbind("keyup")
  $document.unbind("keypress")
  $document.unbind("keydown").bind "keydown", (event) ->
    keyCode = event.keyCode
    return if keyCode isnt 32 and keyCode isnt 37 and keyCode isnt 39 and keyCode isnt 27

    if keyCode is 27 and fullscreen_active
      $("#fullscreen").click()
      return

    tagName = (event.target or event.srcElement).tagName.toUpperCase()

    return if tagName is "INPUT" or tagName is "SELECT" or tagName is "TEXTAREA"

    event.preventDefault()
    switch keyCode
      when 32
        if prsntz.isPaused()
          prsntz.play()
        else
          prsntz.pause()
      when 37
        prsntz.previous()
      when 39
        prsntz.next()

  return