#$dragon.require('app/screen.rb')

class Screen
  attr_accessor :cell_width, :cell_height, :buffer, :outputs, :grid, :redraw

  def render
    if @redraw
      @buffer.cells.each_with_index {|column, x|
        column.each_with_index{|cell, y|
          if cell.redraw
            cell.draw_to(@outputs, x*@cell_width+x, y*@cell_height+y, @cell_width, @cell_height)
            cell.redraw = false
          end
        }
      }
      @redraw = false
    end
  end

  def flush
    @buffer.flush
    @redraw = true
  end

  def set_cell(x, y, char, style)
    @buffer.set_cell(x, y, char, style)
  end

  def initialize(columns, rows, cell_width, cell_height)
    @cell_width = cell_width
    @cell_height = cell_height
    @buffer = CellBuffer.new(columns, rows)
    @redraw = true
  end
end

class CellBuffer
  attr_accessor :rows, :columns, :cells
    def initialize(columns, rows)
      @columns = columns
      @rows = rows
      @cells = Array.new(columns) { Array.new(rows) { Cell.new } }
    end
    
    def clear
    end

    def flush
    @cells.each_with_index {|column, x|
      column.each_with_index{|cell, y|
        if cell.dirty
          cell.clean
          cell.redraw = true
        end
      }
    }
    end

    def set_cell(x, y, char, style)
      if x < 0 || x >= @cells.count
        puts "oob"
      end
      if y < 0 || y >= @cells[x].count
        puts "oob"
      end
      @cells[x][y].char = char
      @cells[x][y].style = style
    end

    def sync
    end
end

class Cell
  attr_accessor :pending_char, :pending_style, :dirty, :redraw
  def initialize
    @char = ' '
    @pending_char = ' '
    @style = CellStyle.new
    @pending_style = CellStyle.new
    @dirty = true
    @redraw = true
  end
  def char
    @char
  end
  def char=(value)
    @pending_char = value
    @dirty = true
  end
  def style
    @style
  end
  def style=(value)
    @pending_style = value
    @dirty = true
  end
  def clean
    @char = @pending_char
    @style = @pending_style
    @dirty = false
  end
  def draw_to(outputs, x, y, w, h)
    outputs.borders << [x, y, w, h, 0, 0, 0, 128]
    outputs.solids << [x, y, w, h] + @style.background
    outputs.labels << [x+$screen.cell_width/2, y+$screen.cell_height, @char, 0, 1] + @style.foreground
    @redraw = false
  end
end

class CellStyle
  attr_accessor :foreground, :background, :bold
  def initialize(fg = [0,0,0,255], bg=[0,0,0,0],bold=false)
    @foreground = fg unless fg.nil?
    @background = bg unless bg.nil?
    @bold = bold unless bg.nil?
  end
end

def game_font
  [0, 0, 0, 0, 0, 255]
end

def handle_input(kb)
  if kb.key_down.l
    return {:move => {:y=>0, :x=>1}}
  elsif kb.key_down.h
    return {:move => {:y=>0, :x=>-1}}
  elsif kb.key_down.k
    return {:move => {:y=>1, :x=>0}}
  elsif kb.key_down.j
    return {:move => {:y=>-1, :x=>0}}
  end
  return nil
end

Color = {
  :none => [0,0,0,0],
  :red => [255,0,0,255],
  :black => [0,0,0,255],
  :white => [255,255,255,255]
}

$screen = Screen.new((1280/16).round, (720/30).round, 15, 29)

def tick args
  args.game.player_x ||= ($screen.buffer.columns/2).round
  args.game.player_y ||= ($screen.buffer.rows/2).round
  $screen.outputs = args.outputs
  $screen.grid = args.grid

  action = handle_input(args.inputs.keyboard)
  if action
    if action[:move]
      args.game.player_x += action[:move][:x]
      args.game.player_y += action[:move][:y]
    end
  end

  $screen.set_cell(args.game.player_x, args.game.player_y, '@', CellStyle.new(Color[:black], Color[:none]))
  $screen.flush

  $screen.render

end