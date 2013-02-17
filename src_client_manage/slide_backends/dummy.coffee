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

class Dummy

  constructor: () ->
    @import_file_value_column = "Slide URL"

  handle: (url) ->
    return url?

  is_dummy: () -> true

  thumb_type_of: (url) ->
    return "none" if !url?
    return "swf" if url.indexOf(".swf") isnt -1
    "img"

  slide_info: (slide, callback) ->
    if !slide.url? or utils.is_url_valid(slide.url)
      callback undefined, slide,
        slide_thumb: slide.url
        public_url: slide.url
    else
      callback("Invalid URL: '#{slide.url}'")

  first_slide: (slideshow) ->
    return slide_backends.make_new_slide(null, 0) if !slideshow?

    new_slide = slide_backends.make_new_slide(slideshow.url, 0)
    new_slide._plugin_id = slideshow._plugin_id if slideshow._plugin_id?
    new_slide

  slideshow_info: (url, callback) ->
    url = "http://#{url}" unless _.str.startsWith(url, "http")
    @slide_info url: url, (err, slide, slide_info) ->
      return callback(err) if err?
      slide.slide_thumb = slide_info.slide_thumb
      slide.public_url = slide_info.public_url
      callback(undefined, slide)

  url_from_public_url: (slide, public_url, callback) ->
    if utils.is_url_valid public_url
      callback undefined, public_url
    else
      callback("Invalid URL: #{public_url}")

  set_slide_value_from_import: (slide, slide_url) ->
    slide.url = slide_url
    slide.public_url = slide_url

  check_slide_value_from_import: (slide, slide_number, callback) ->
    callback()

  make_new_from: (slide) ->
    new_slide = slide_backends.make_new_slide(slide.url.substr(0, slide.url.lastIndexOf("/") + 1), slide.time)
    new_slide._thumb_type = "img"
    new_slide._plugin_id = slide._plugin_id if slide._plugin_id?
    new_slide

@slide_backends.Dummy = Dummy