# frozen_string_literal: true

require_relative 'level'

class TitleScreen < Screen
  attr_accessor :bg_image

  def initialize
    @bg_image = {
      dim_x: 1024,
      dim_y: 1024,
      path: 'sprites/gosu/background/colored_grass.png'
    }
  end

  def tick
    audio[:music] ||= { input: "sounds/music.mp3", looping: true }
  end

  def draw
    render_background
    outputs.sprites << [100, 420, 1082, 93, "sprites/gosu/logo.png" ]
    outputs.labels << [520, 400, "By Tyler and Will", 5]
    outputs.labels << [500, 140, "Click anywhere to play", 4]
  end

  def handle_input
    state.screen = Level.new if inputs.mouse.click
  end

  def render_background
    outputs.sprites << scrolling_background(state.tick_count, 1.0)
  end

  def scrolling_background(at, rate, y = -100)
    # Right now this re-draws the sprite on each frame, with x decrementing as the image
    # should move across the screen. Can this be done such that the images are only ever
    # drawn once, then just moved around (with wrapping the further left to the back of
    # the list on the right once it moves off-screen)?
    dim_x = bg_image[:dim_x]
    [0, dim_x, dim_x*2].map do |x|
      { x: x - at.*(rate) % dim_x, y: y, w: dim_x, h: bg_image[:dim_y], path: bg_image[:path] }
    end
  end
end
