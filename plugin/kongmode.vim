pa rubywrapper

fu! s:KongModeSetup()
ruby << KONG
# Stages to add a binding

  # Stage 1: amend `case Var["g:kong_submode"]` switch
  # Stage 2: amend `when 'q', 'd', 'b', 'i', 'm', '[', 'o', 't', 'n'`
  # Stage 3: amend `case Var["g:kong_submode"]` switch

  # Stage 1 decides what j and k do
  # Stage 2 assigns changing modes to influence what Stage 1 does
  # Stage 3 assigns behaviour of `change` c hotkey on match

# These stages could be refactored to be represented by a class, a hash
# or some other contrivance, but to little benefit at time of writing. The
# most time effective option is simply to record this guide here.

$kong_info = ""
$nyao_box_index = 0

module Kong
  def self.display_mode
    Ex.redraw
    Ex.echohl 'Todo'
    Ex.echon '"-- KONG MODE '+Var['g:kong_submode']+' --'+$kong_info.to_s+'"'
    Ex.echohl 'None'
  end

  def self.feedkey
    c = Ev.getcharstr
    match_id = nil
    col = 1

    $cycle_classes = CycleClasses.new
    $cycle_defs = CycleDefs.new

    while c != '	'
      # Ev.matchdelete(match_id) if match_id
      Ev.clearmatches

      case c
      when 'j', 'k'
        catch do |early|
          direction = c == 'j' ? '' : 'b'

          Ev.popup_close( $cycle_classes_popid ) if $cycle_classes_popid
          Ev.popup_close( $cycle_defs_popid ) if $cycle_defs_popid

          # Stage 1
          query = case Var["g:kong_submode"]
                  when 'q'
                    '\v^.{-}[\'"]\zs.{-}\ze[\'"]'
                  when 'd'
                    # '^\s*def\> \zs.*\ze'
                    # match_id = Ev.matchadd 'VISUAL', '\\%.l' + '^\s*def\> \zs.*\ze'.sq
                    $cycle_defs.cycle(c == 'j' ? 1 : -1)
                    match_id = Ev.matchadd 'VISUAL', '\%.l.*'.sq
                    throw early
                  when 't'
                    '^\s*test\> [\'"]\zs.*\ze[\'"]'
                  when 'i'
                    '\v^[^#A-Z]*\zs[A-Z][A-z:]*\ze'
                  when 'o'
                    # '\v^\s*(class|module)'
                    $cycle_classes.cycle(c == 'j' ? 1 : -1)
                    match_id = Ev.matchadd 'VISUAL', '\%.l.*'.sq
                    throw early
                  when 'b'
                    '^.\{-}(\zs.*\ze)'
                  when '['
                    '^.\{-}\[\zs.*\ze\]'
                  when 'm'
                    Ev.CycleUppercaseMarks(direction == 'b' ? -1 : 1)
                    match_id = Ev.matchadd 'VISUAL', '\%.l.*'.sq
                    mark = Var["g:current_mark"]
                    Ev.sign_unplace "marknames"
                    Ex.hi "RedText ctermbg=1 ctermfg=235 cterm=reverse guibg=#262626 guifg=#8787af gui=reverse"
                    Ev.sign_define("markname-#{mark}", { text: mark, texthl: "RedText", linehl: "RedText" })
                    Ev.sign_place(mark.ord, 'marknames', "markname-#{mark}", Ev.bufnr, {lnum: Ev.line('.'), priority: 99})
                    throw early
                  when 'n'
                    $nyao_box_index += (direction == 'b' ? -1 : 1)

                    if $nyao_box_index > NyaoBoxes.current_box.length - 1
                      $nyao_box_index = 0
                    elsif $nyao_box_index < 0
                      $nyao_box_index = NyaoBoxes.current_box.length - 1
                    end

                    item = NyaoBoxes.current_box[$nyao_box_index]

                    Ex.edit item["fname"]
                    Ex.normal! 'zR'
                    unless (Ev.search ('\M'+item["line"]).sq) > 0
                      Ex.normal! "#{item['nr']}gg"
                    end

                    Ex.normal! "zz"

                    match_id = Ev.matchadd 'VISUAL', '\%.l.*'.sq
                    throw early
                  end
          match_pattern = '\\%.l' + query

          Ev.search query.sq, direction
          Ex.normal! "zz"
          col = Ev.col('.')
          match_id = Ev.matchadd 'VISUAL', match_pattern.sq
        end
      # Stage 2
      when 'q', 'd', 'b', 'i', 'm', '[', 'o', 't', 'n'
        $cycle_classes.reload
        $cycle_defs.reload
        Var["g:kong_submode"] = c
        c = 'j'
        display_mode
        next
      when 'c'
        break
      end

      display_mode
      c = Ev.getcharstr
    end

    Ev.clearmatches
    Ex.redraw!
    case c
    when 'c'
      # Stage 2
      case Var["g:kong_submode"]
      when 'q'
        Ex.s '/\v^.{-}[\'"]\zs.{-}\ze[\'"]//'.sq
        Ev.search '\v^.{-}[\'"]\zs'.sq
        Ex.startinsert
      when 'b'
        Ex.normal "ldt)"
        Ex.startinsert
      when '['
        Ex.normal "dt]"
        Ex.startinsert
      when 'd'
        Ex.s '/^\s*def\> \zs.*\ze//'.sq
        Ex.startinsert!
      when 't'
        Ex.s '/^\s*test\> [\'"]\zs.*\ze[\'"]//'.sq
        Ev.search '\v^.{-}[\'"]\zs'.sq
        Ex.startinsert
      when 'o'
        Ex.normal "wde"
        Ex.startinsert!
      when 'm'
        Ex.normal "vilc"
        Ex.startinsert!
      end
    end

    Ev.sign_unplace "marknames"
    Ev.popup_close( $cycle_classes_popid ) if $cycle_classes_popid
    Ev.popup_close( $cycle_defs_popid ) if $cycle_defs_popid
  end

  def self.kong_mode
    display_mode
    feedkey
  end

  class Ring < ::Array
    attr_accessor :current_index, :current

    def initialize *args
      @current_index = 0
      super *args
    end

    def normalized_index = @current_index % length
    def current          = self[@current_index % length]
    def next             = tap { @current_index += 1 }
    def prev             = tap { @current_index -= 1 }

    def range(u, b) = self[ @current_index-u..@current_index ].concat(self[@current_index+1..@current_index+b])
    def surround(i) = range(i, i)
  end

  class CycleDefs
    attr_accessor :ring, :current_file

    Location = Struct.new :lnum, :fname, :content, :name

    def initialize
      reload
    end

    def reload
      @current_file = Ev.expand("%")
      lnum          = Ev.line('.')
      lines         = []

      File
        .readlines(@current_file)
        .each_with_index do |l, i|
          if l.match? /^\s*(function|def)\s/
            lines << Location.new(i+1, @current_file, l, l.match(/^\s*(function|def)\s([A-z0-9_\.]*)/)[2])
          end
        end

      @ring = Ring.new(lines)

      distance = 99999
      @ring.each_with_index do |l, i|
        new_distance = (lnum - l.lnum).abs

        if new_distance < distance
          @ring.current_index = i - 1
          distance = new_distance
        end
      end
    end

    def cycle dir
      reload if @current_file != Ev.expand("%")

      dir == 1 ? @ring.next : @ring.prev

      Ex.normal! "#{@ring.current.lnum}ggzz"

      Ev.popup_close( $cycle_defs_popid ) if $cycle_defs_popid
      $cycle_defs_popid = Ev.popup_create(
        @ring.map.with_index do |l, j|
          @ring.normalized_index == j ? "> #{l.name}" : "  #{l.name}"
        end,
        {
          title: '',
          padding: [1,1,1,1],
          line: 1,
          col: Var['&columns'] - 23,
          pos: 'topright',
          scrollbar: 1
        }
      )
    end
  end

  class CycleClasses
    attr_accessor :ring, :current_file

    Location = Struct.new :lnum, :fname, :content, :name

    def initialize
      reload
    end

    def reload
      @current_file = Ev.expand("%")
      current_lnum = Ev.line(".")
      lines        = []

      Ev.getbufinfo.map { _1['name'] }.select { _1.match? /(\.rb|\.vim)$/ }.each do |f|
        File
          .readlines(f)
          .each_with_index do |l, i|
            if l.match? /^\s*(class|module)\s/
              lines << Location.new(i+1, f, l, l.match(/^\s*(class|module)\s([A-z0-9_]*)/)[2])
            end
          end
      end
      lines = lines.sort {|a,b|
        if a.fname.match?(@current_file) && b.fname.match?(@current_file)
          a.lnum <=> b.lnum
        elsif a.fname.match?(@current_file)
          -1
        elsif b.fname.match?(@current_file)
          1
        else
          if a.fname == b.fname
            a.lnum <=> b.lnum
          else
            a.fname <=> b.fname
          end
        end
      }

      @ring = Ring.new(lines)

      distance = 99999
      @ring.each_with_index do |l, i|
        new_distance = (current_lnum - l.lnum).abs

        if l.fname == @current_file && new_distance < distance
          @ring.current_index = i - 1
          distance = new_distance
        end
      end
    end

    def cycle dir
      # @current_file is nil
      reload if current_file != Ev.expand("%")

      dir == 1 ? @ring.next : @ring.prev

      Ex.edit @ring.current.fname
      Ex.normal! "#{@ring.current.lnum}ggzz"

      Ev.popup_close( $cycle_classes_popid ) if $cycle_classes_popid
      $cycle_classes_popid = Ev.popup_create(
        @ring.map.with_index do |l, j|
          @ring.normalized_index == j ? "> #{l.name}" : "  #{l.name}"
        end,
        {
          title: '',
          padding: [1,1,1,1],
          line: 1,
          col: Var['&columns'] - 23,
          pos: 'topright',
          scrollbar: 1
        }
      )
    end
  end
end
KONG
endfu

let g:kong_submode = 'd'

call s:KongModeSetup()

nno dk :ruby Kong.kong_mode<CR>
