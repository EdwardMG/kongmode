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

    while c != '	'
      # Ev.matchdelete(match_id) if match_id
      Ev.clearmatches

      case c
      when 'j', 'k'
        catch do |early|
          direction = c == 'j' ? '' : 'b'

          # Stage 1
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
