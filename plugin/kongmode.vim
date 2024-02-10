pa rubywrapper

fu! s:KongModeSetup()
ruby << KONG
module Kong
  def self.display_mode
    Ex.redraw
    Ex.echohl 'Todo'
    Ex.echon '"-- KONG MODE '+Var['g:kong_submode']+' --"'
    Ex.echohl 'None'
  end

  def self.feedkey
    c = Ev.getcharstr
    match_id = nil
    col = 1

    while c != '	'
      # Ev.matchdelete(match_id) if match_id
      Ev.clearmatches

      case c
      when 'j', 'k'
        catch do |early|
          direction = c == 'j' ? '' : 'b'

          query = case Var["g:kong_submode"]
                  when 'q'
                    '\v^.{-}[\'"]\zs.{-}\ze[\'"]'
                  when 'd'
                    '^\s*def\> \zs.*\ze'
                  when 't'
                    '^\s*test\> [\'"]\zs.*\ze[\'"]'
                  when 'i'
                    '\v^[^#A-Z]*\zs[A-Z][A-z:]*\ze'
                  when 'o'
                    '\v^\s*(class|module)'
                  when 'b'
                    '^.\{-}\zs(\zs.*\ze)'
                  when '['
                    '^.\{-}\zs\[\zs.*\ze\]'
                  when 'm'
                    Ev.CycleUppercaseMarks(direction == 'b' ? -1 : 1)
                    match_id = Ev.matchadd 'VISUAL', '\\%.l.*'
                    throw early
                  end
          match_pattern = '\\%.l' + query

          Ev.search query.sq, direction
          col = Ev.col('.')
          match_id = Ev.matchadd 'VISUAL', match_pattern.sq
        end
      when 'q', 'd', 'b', 'i', 'm', '[', 'o', 't'
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
  end

  def self.kong_mode
    display_mode
    feedkey
  end
end

Var["g:kong_submode"] = 'd'
KONG
endfu

call s:KongModeSetup()

nno dk :ruby Kong.kong_mode<CR>
