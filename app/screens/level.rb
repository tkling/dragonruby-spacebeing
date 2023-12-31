# frozen_string_literal: true

class Level < Screen
  ADVANCE_DURATION = 2.seconds

  def initialize
    @stage = 0
    @level_pos_x = 0
    @level_scale = 0.5625 # 1280px to 720px.
    @level_sprite = {
      dim_x: 5120,
      dim_y: 1280,
      path: "sprites/gosu/levels/level1.png"
    }

    @fg_speed = 3.555
    @bg_speed = 1.78
    @bg_scale = 0.7032 # 1024px to 720px.
    @bg_image = {
      dim_x: 1024,
      dim_y: 1024,
      path: "sprites/gosu/background/colored_grass.png"
    }

    @spike_sprite = {
      dim_x: 128,
      dim_y: 64,
      path: "sprites/gosu/environment/spikes-cropped.png"
    }

    @potion_sprite = {
      dim_x: 68,
      dim_y: 87,
      path: "sprites/gosu/items/potionRed-cropped.png"
    }

    @floor_heights = [520, 304, 88].reverse # 1F, 2F, 3F. Pixels.

    @ui = UI.new
    @player = $gtk.args.state.player = Player.new(189, 72, self)

    @enable_collision_debug = true
  end

  def draw
    bg_positions.each do |x|
      outputs.sprites << sprite_values(@bg_image, x + @level_pos_x, 0, @bg_scale)
    end

    outputs.sprites << sprite_values(@level_sprite, @level_pos_x, 0, @level_scale)

    (spike_sprites + potion_sprites).each do |sprite|
      outputs.sprites << sprite
      outputs.borders << sprite.merge(r: 255) if @enable_collision_debug
    end

    @ui.draw
    @player.draw
  end

  def potion_sprites
    potion_positions.map do |(x, y)|
      sprite_values(@potion_sprite, x, y - 515, 0.75)
    end
  end

  def spike_sprites
    spike_positions.map do |(x, y)|
      sprite_values(@spike_sprite, x, y - 268, 0.75)
    end
  end

  def handle_input
    @ui.handle_input
    if inputs.mouse.click && !@ui.locked?
      if state.tutorial_done
        card = @ui.action_for_click(inputs.mouse.click)
        return if @player.dead || complete? || card.nil?

        @input_locked = true # Unlocked when stage ends.
        @player.handle_action(card)
        advance_stage! unless card.is_a?(ConcentrateCard)
      else
        @ui.finish_tutorial!
      end
    end
  end

  def sprite_values(sprite, x, y, scale = 1.0)
    w, h = sprite.values_at(:dim_x, :dim_y).map { |val| val * scale }
    {x: x, y: y, w: w, h: h, path: sprite[:path]}
  end

  def spike_positions
    @spike_positions ||= [
      # Stage 1.
      [510, 338],
      [750, 554],
      # Stage 3.
      [1380, 554],
      [1610, 554],
      # Stage 4.
      [1660, 338],
      [1760, 338],
      [1810, 770],
      [2040, 770],
      [2060, 338],
      [2160, 338],
      # Stage 5.
      [2240, 554],
      [2480, 770],
      [2470, 554]
      # Example solution: Jump, Walk, Walk, Walk, Jump (grab potion above), Walk.
    ]
  end

  def potion_positions
    @potion_positions ||= [
      [1060, 570],
      [1920, 136]
    ]
  end

  def remove_potion(index)
    potion_positions.delete_at(index)
  end

  def elevation_map
    @elevation_map ||= {
      0 => [true, false, false], # Starting stage, not accessed.
      1 => [true, true, false],
      2 => [true, false, true],
      3 => [true, true, false],
      4 => [true, false, true],
      5 => [true, true, false],
      6 => [true, false, false]
    }
  end

  def bg_positions
    @bg_positions ||= (-1..3).map { |x| x * @bg_image[:dim_x] * @bg_scale }
  end

  def complete?
    @stage == 6
  end

  def skip_stage
    state.skip_stage_at ||= state.tick_count
    @ui.lock!
  end

  def next_stage
    clamped_stage(@stage + 1)
  end

  def advance_stage!
    state.advance_stage_at ||= state.tick_count
    next_elevations
  end

  def next_elevations
    elevation_map[next_stage]
  end

  def clamped_stage(candidate_stage)
    candidate_stage.clamp(*@elevation_map.keys.minmax_by { |k, _v| k })
  end

  def tick
    state.advance_stage_at ||= false
    state.skip_stage_at ||= false

    @player.args = args
    @player.tick

    if (skipping = state.skip_stage_at)
      if skipping.elapsed_time >= 0.75
        @ui.unlock!
      end
    end

    if state.advance_stage_at
      advance_start_dt = state.advance_stage_at.elapsed_time

      # Move the player to the right by moving the level to the left.
      @level_pos_x -= @fg_speed
      spike_positions.map! { |(x, y)| [x - @fg_speed, y] }
      potion_positions.map! { |(x, y)| [x - @fg_speed, y] }
      bg_positions.map! { |x| x + @bg_speed }

      if advance_start_dt >= Level::ADVANCE_DURATION
        @stage = next_stage unless @player.dead
        @ui.unlock!
        if advance_start_dt >= 0.25.seconds
          @input_locked = complete?
          state.advance_stage_at = false
        end
      end
    end
  end
end
