#!/usr/bin/ruby
# monitors the integration framework for status / errors
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
#
# to use rbcurse (currently not used):
#   $ export RUBY_FFI_NCURSES_LIB=/lib64/libncursesw.so.5.9

require 'rubygems'
require 'ncursesw'
require 'active_support/core_ext/string/filters'
require 'omega'

# ncurses output class
class OmegaNcurses
  #### Data to display, after setting, call 'refresh'

  attr_accessor :users
  attr_accessor :galaxies
  attr_accessor :tests

  ##### Output parameters

  PANEL_WIDTH   = 95
  PANEL_HEIGHT  = 40
  PANEL_PADDING = 5

  ##### General ncurses init

  def init_ncurses
    @terminate = false
    screen = Ncurses.initscr();
    Ncurses.cbreak();
    Ncurses.noecho();
    Ncurses.nodelay(screen, true);
    Ncurses.keypad(screen, true);
    screen
  end

  def close_ncurses
    @terminate = true
    Ncurses.echo()
    Ncurses.nocbreak()
    Ncurses.nl()
    Ncurses.endwin();
    return self
  end

  def init_colors(screen)
    Ncurses.start_color();
    Ncurses.init_pair(1, Ncurses::COLOR_BLACK,   Ncurses::COLOR_BLUE);
    Ncurses.init_pair(2, Ncurses::COLOR_BLACK,   Ncurses::COLOR_WHITE);
    Ncurses.init_pair(3, Ncurses::COLOR_RED,     Ncurses::COLOR_WHITE);
    Ncurses.init_pair(4, Ncurses::COLOR_GREEN,   Ncurses::COLOR_WHITE);
    Ncurses.init_pair(5, Ncurses::COLOR_YELLOW,  Ncurses::COLOR_WHITE);
    Ncurses.init_pair(6, Ncurses::COLOR_CYAN,    Ncurses::COLOR_WHITE);
    Ncurses.init_pair(7, Ncurses::COLOR_MAGENTA, Ncurses::COLOR_WHITE);
    Ncurses.init_pair(8, Ncurses::COLOR_BLUE,    Ncurses::COLOR_WHITE);
    screen.bkgd(Ncurses.COLOR_PAIR(1));
  end

  def get_color(i)
    Ncurses::COLOR_PAIR(i)
  end

  def init_win(controls=false)
    win = controls ? Ncurses::WINDOW.new(10, 50, PANEL_HEIGHT * 2 / 3, PANEL_WIDTH + 10) :
                     Ncurses::WINDOW.new(PANEL_HEIGHT, PANEL_WIDTH, 1, 1)
    win.bkgd(Ncurses.COLOR_PAIR(2))
    win.keypad(TRUE)
    win
  end

  def init_panel(win)
    Ncurses::Panel.new_panel(win)
  end

  def set_current_panel(panel)
    @current_panel = panel
    Ncurses::Panel.top_panel(panel)
    Ncurses::Panel.update_panels
  end

  def next_panel
    Ncurses::Panel.panel_userptr(@current_panel)
  end

  def link_panels(*panels)
    1.upto(panels.size-1){ |i|
      Ncurses::Panel.set_panel_userptr(panels[i-1],  panels[i])
    }
    Ncurses::Panel.set_panel_userptr(panels[-1], panels[0])
  end

  def initialize
    # config
    @show_asteroids = false
    @show_resources = false
    @scroll_distance = 0

    screen = init_ncurses
    init_colors(screen)

    tests_win  = init_win
    manu_win   = init_win
    users_win  = init_win
    cosmos_win = init_win
    @controls_win = init_win(true)
    @view_windows = {:tests => tests_win, :manu => manu_win,
                     :users => users_win, :cosmos => cosmos_win }

    tests_panel  = init_panel(tests_win)
    users_panel  = init_panel(users_win)
    manu_panel   = init_panel(manu_win)
    cosmos_panel = init_panel(cosmos_win)
    controls_panel = init_panel(@controls_win)
    view_panels = {:cosmos => cosmos_panel, :users => users_panel,
                   :manu => manu_panel,     :tests => tests_panel }

    link_panels *view_panels.values
    set_current_panel view_panels[:cosmos]
  end

  ##### monitor specific drawing

  def draw_titles(window, current_window_title)
    ["Cosmos", "Users", "Manufactured", "Tests"].each { |t|
      window.attron(Ncurses::A_UNDERLINE)
      window.attron(Ncurses::A_BOLD)  if t.downcase == current_window_title.to_s
      window.addstr(t)
      window.attroff(Ncurses::A_BOLD) if t.downcase == current_window_title.to_s
      window.attroff(Ncurses::A_UNDERLINE)
      window.addstr('|') #unless  t == title_str.last
    }
  end

  def color_text(window_id, color)
    @view_windows[window_id].attron(color)
    yield
    @view_windows[window_id].attroff(color)
  end

  def append_text(window_id, text, y)
    @view_windows[window_id].move(@win_counters[window_id] += 1, y)
    @view_windows[window_id].addstr(text.truncate(PANEL_WIDTH - 10))
  end

  def refresh_controls
    @controls_win.clear
    @controls_win.box(0, 0)
    @controls_win.move(1,1)

    @controls_win.attron(Ncurses::A_BOLD)
    @controls_win.addstr("Controls")
    @controls_win.attroff(Ncurses::A_BOLD)

    @controls_win.move(2,1)
    @controls_win.addstr("TAB to browse through the panels")
    @controls_win.move(3,1)
    @controls_win.addstr("Arrows to scroll")
    @controls_win.move(4,1)
    @controls_win.addstr("Q to exit");
    if @current_panel.window == @view_windows[:cosmos]
      @controls_win.move(5,1)
      @controls_win.addstr("A to toggle asteroids")
    end

    if @current_panel.window == @view_windows[:cosmos] ||
       @current_panel.window == @view_windows[:manu]
      @controls_win.move(6,1)
      @controls_win.addstr("R to toggle resources") 
    end
  end

  def draw
    @current_panel.window.move(0,0)
    Ncurses::Panel.update_panels
    Ncurses.doupdate
  end

  def refresh(invalidated = nil)
    @view_windows.each { |i,w|
      w.clear
      w.box(0,0)
      w.move(1,1)
      draw_titles(w, i)
    }

    @win_counters = {:tests => 1, :manu => 1,
                     :users => 1, :cosmos => 1}
    @users.each { |u|
      append_text :users, "- #{u.id}", 2
      u.ships.each { |s|
        append_text :manu, "- #{s.id} (@#{s.location})", 2
        if @show_resources
          s.resources.each { |ri,q|
            color_text(:manu, get_color(7)) {
              append_text :manu, "#{q} of #{ri}", 4
            }
          }
        end
      }
      u.stations.each { |s|
        append_text :manu, "- #{s.id} (@#{s.location})", 2
        if @show_resources
          s.resources.each { |ri,q|
            color_text(:manu, get_color(7)) {
              append_text :manu, "#{q} of #{ri}", 4
            }
          }
        end
      }
    }

    @galaxies.each { |g|
      append_text :cosmos, "Galaxy: #{g.name}", 2
      g.solar_systems.each { |sys|
        color_text(:cosmos, get_color(8)) {
          append_text :cosmos, "System: #{sys.name}", 3
        }
        append_text :cosmos, "Star: #{sys.star.name}", 4 if sys.star
        sys.planets.each { |pl|
          append_text :cosmos, "Planet: #{pl.name} (@#{pl.location})", 4
          #pl.moons.each { |mn|
          #  append_text :cosmos, "Moon: #{mn.name}", 4
          #}
        }
        if @show_asteroids
          sys.asteroids.each { |a|
            color_text(:cosmos, get_color(6)) {
              append_text :cosmos, "Asteroid: #{a.name}", 4
            }
            if @show_resources
              a.resource_sources.each { |rs|
                color_text(:cosmos, get_color(7)) {
                  append_text :cosmos, "#{rs.quantity} of #{rs.resource.id}", 5
                }
              }
            end
          }
        end
      }
    }

    @tests.each { |i,ta|
      append_text :tests, i.to_s, 2
      ta.each { |test|
        str   = test[:success] ? "success" : "failed"
        str   = "#{str} #{test[:entity]} #{test[:message]}"
        color = test[:success] ? get_color(4) : get_color(4)
        color_text :tests, color {
          append_text :tests, str, 3
        }
      }
    }

    refresh_controls
    draw
  end

  def handle_input
    until @terminate
      refresh
      chin = @current_panel.window.getch
      if chin == 'q'.ord
        close_ncurses
      elsif chin == 'a'.ord
        @show_asteroids = !@show_asteroids
      elsif chin == 'r'.ord
        @show_resources = !@show_resources
      elsif chin == "\t"[0].ord
        set_current_panel next_panel
      #elsif chin == Ncurses::KEY_UP
      #elsif chin == Ncurses::KEY_DOWN
      end
    end
    return self
  end

end

puts "Getting serverside entities"

node = RJR::AMQPNode.new :broker => 'localhost', :node_id => 'monitor'
Omega::Client::User.login node, 'admin', 'nimda'

output = OmegaNcurses.new
output.users = Omega::Client::User.get_all
output.galaxies = Omega::Client::Galaxy.get_all
output.tests = []

# periodically sync entities & resources
Omega::Client::Tracker.em_repeat_async(10) {
  output.users = Omega::Client::User.get_all
  output.galaxies.each { |g|
    g.solar_systems.each { |s|
      s.asteroids.each { |a|
        a.update!
      }
    }
  }
  output.refresh
}

output.handle_input # blocks

# reset the terminal to defaults & exit
exec("reset")
