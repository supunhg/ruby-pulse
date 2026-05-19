module RubyPulse
  module UI
    module Charts
      class Sparkline < Gtk::DrawingArea
        DEFAULT_COLOR = [0.31, 0.62, 0.87, 0.8].freeze
        FILL_COLOR = [0.31, 0.62, 0.87, 0.15].freeze
        BACKGROUND_COLOR = [0.5, 0.5, 0.5, 0.08].freeze
        MAX_POINTS = 120

        def initialize(max_points: MAX_POINTS, color: DEFAULT_COLOR, fill_color: FILL_COLOR)
          super()
          @data = []
          @max_points = max_points
          @color = color
          @fill_color = fill_color
          @min_range = nil
          @max_range = nil

          set_draw_func { |_area, cr, width, height| draw(cr, width, height) }
        end

        def push(value)
          @data << value.to_f
          @data.shift if @data.size > @max_points
          queue_draw
        end

        def reset
          @data.clear
          queue_draw
        end

        def set_range(min, max)
          @min_range = min
          @max_range = max
          queue_draw
        end

        private

        def draw(cr, width, height)
          draw_background(cr, width, height)
          return if @data.size < 2

          min_val = @min_range || @data.min
          max_val = @max_range || @data.max
          range = max_val - min_val
          range = 1.0 if range.zero?

          padding = 0
          draw_width = width - 2 * padding
          draw_height = height - 2 * padding

          points = @data.each_with_index.map do |val, i|
            x = padding + (i.to_f / (@data.size - 1)) * draw_width
            y = padding + draw_height - ((val - min_val) / range) * draw_height
            [x, y]
          end

          draw_fill(cr, points, draw_height, padding)
          draw_line(cr, points)
        end

        def draw_background(cr, width, height)
          cr.set_source_rgba(*BACKGROUND_COLOR)
          cr.rectangle(0, 0, width, height)
          cr.fill
        end

        def draw_fill(cr, points, height, padding)
          cr.move_to(points.first[0], height + padding)
          points.each { |x, y| cr.line_to(x, y) }
          cr.line_to(points.last[0], height + padding)
          cr.close_path

          cr.set_source_rgba(*@fill_color)
          cr.fill
        end

        def draw_line(cr, points)
          cr.move_to(points.first[0], points.first[1])
          points[1..].each { |x, y| cr.line_to(x, y) }

          cr.set_source_rgba(*@color)
          cr.set_line_width(1.5)
          cr.line_cap = Cairo::LineCap::ROUND
          cr.line_join = Cairo::LineJoin::ROUND
          cr.stroke
        end
      end
    end
  end
end
