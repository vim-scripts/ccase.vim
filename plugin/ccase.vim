" rc file for VIM, clearcase extensions {{{
" Author:               Douglas L. Potts
" Created:              17-Feb-2000
" Last Modified:        01-Nov-2001 16:45
" Version:              1.11
"
" $Id: ccase.vim,v 1.14 2001/11/01 21:50:00 dp Exp $
"
" Modifications:
" $Log: ccase.vim,v $
" Revision 1.14  2001/11/01 21:50:00  dp
" Added options to mkelem function, fixed bug with autoloading directory.
"
" Revision 1.13  2001/11/01 16:53:44  dp
" Lots of modifications for using prompt box commenting, enhancements to diff
" functionality, menus.
"
" Revision 1.11  2001/10/30 18:43:29  dp
" Added new prompt functionality for checkin and checkout.
"
" Revision 1.7  2001/10/01 17:31:16  dp
"  Added full mkelem functionality and cleaned up header comments some.
"
" Revision 1.4  2001/09/07 13:56:39  dp
" Removed '-nc' so that user will now be prompted for checkin and checkout
" comments.  Also removed common directory shortcuts since I don't use
" them anyway, but left in example for other users.
"
" 08-Jun-2001 pottsdl   Versioned this script for upload to vim-online.
" 18-Jan-2001 pottsdl   Put this file on my vim macros page.
" 09-Mar-2000 pottsdl   Changed so checkout will allow for changes made before
"                       checkout command was given, but still does the e! so
"                       that no warning message come up.
"                       Added ctver to give version.
" 09-Mar-2000 pottsdl   Added Clearcase menu definition here.
"                       Made Menus use these mappings for ease of use.
" 17-Feb-2000 pottsdl   Created from .unixrc mappings
"
" TODO:  Revise output capture method to use redir to put shell output into a
"        register, and open a unmodifiable buffer to put it in.
" TODO:  Add some of my other functions for doing a diff between current file
"        and predecessor using the new diff functionality in Vim 6.0.
" TODO:  Maybe write up some documentation.
" }}}

if exists('g:loaded_ccase') | finish |endif
let g:loaded_ccase = 1

" If the *GUI* is running, either use the dialog box or regular prompt
if !exists("g:ccaseUseDialog")
  let g:ccaseUseDialog = 1      " Default is to use dialog box
endif

" Allow user to skip being prompted for comments all the time
if !exists("g:ccaseNoComment")
  let g:ccaseNoComment = 0      " Default is to ask for comments
endif

" Allow user to specify diffsplit of horiz. or vert.
if !exists("g:ccaseDiffVertSplit")
  let g:ccaseDiffVertSplit = 1  " Default to split for diff vertically
endif

" Allow user to specify automatically reloading file after checking in or
" checking out.
if !exists("g:ccaseAutoLoad")
  let g:ccaseAutoLoad = 1       " Default to reload file after ci/co operations
endif

" Allow for new elements to remained checked out
if !exists("g:ccaseMkelemCheckedout")
  let g:ccaseMkelemCheckedout = 0 " Default is to check them in upon creation
endif

" Allow for leaving directory checked out on Mkelem
if !exists("g:ccaseLeaveDirCO")
  let g:ccaseLeaveDirCO = 0     " Default is to prompt to check dir back in
endif

" Setup statusline to show current view, if your environment sets the
" $view variable when inside a view.
if exists("$view")
  set statusline=%<%f%h%m%r%=%{$view}\ %{&ff}\ %l,%c%V\ %P
endif

" Don't keep around other version control menus (CVS and RCS)
" create dummy entry so no warning message come up if they are already gone.
" DLP - I have cvsmenu.vim and rcs-menu.vim in my plugins directory, only
"       need one Version Control at a time though.
amenu &CVS.dummy echo "dummy"<cr>
aunmenu CVS
amenu &RCS.dummy echo "dummy"<cr>
aunmenu RCS

" ===========================================================================
"                      Beginning of Function Definitions
" ===========================================================================
" {{{
" If not already found elsewhere.
if !exists("*OpenIfNew")
  " ===========================================================================
  function! OpenIfNew( name )
  " I used the same logic in several functions, checking if the buffer was
  " already around, and then deleting and re-loading it, if it was.
  " ---------------------------------------------------------------------------
    " Find out if we already have a buffer for it
    let buf_no = bufnr(expand(a:name))

    " If there is a 'name' buffer, delete it
    if buf_no > 0
      if version < 600
        exe 'bd! '.a:name
      else
        exe 'bw! '.a:name
      endif
    endif
    " (Re)open the file (update).
    exe ':sp '.a:name
  endfunction
endif

" ===========================================================================
function! s:CtConsoleDiff( fname, ask_version )
" Requires: +diff
" Do a diff of the given filename with its cleartool predecessor or user
" specified version,
" ---------------------------------------------------------------------------

  if has("diff")
    let s:splittype = ""
    if g:ccaseDiffVertSplit == 1
      let s:splittype=":vert diffsplit "
    else
      let s:splittype=":diffsplit "
    endif

    if (a:ask_version != 0)
      let s:cmp_to_ver = ""
      let s:prompt_text = "Give version to compare to: "
      
      " While we aren't getting anything, keep prompting
      while (s:cmp_to_ver == "")
        if g:ccaseUseDialog == 1
          let s:cmp_to_ver = inputdialog(s:prompt_text)
        else
          let s:cmp_to_ver = input(s:prompt_text)
        endif
        echo "\n"
      endwhile

      " If they change their mind and want predecessor, allow that
      if s:cmp_to_ver =~ "pred"
        let s:cmp_to_ver = system('cleartool des -s -pre '.a:fname)
      endif
    else
      echo "Comparing to predecessor..."
      let s:cmp_to_ver = system('cleartool des -s -pre '.a:fname)
      let debug=expand(s:cmp_to_ver)

      echo "Predecessor version: ". debug
    endif
    exe s:splittype.a:fname.'@@'.s:cmp_to_ver
  else
    echohl Error
    echo "Unable to use console diff function.  Requires +diff compiled in"
    echohl None
  endif
endfunction

" ===========================================================================
function! s:IsCheckedout( filename )
" Determine if the given filename (could be a directory) is currently
" checked out.
" Return 1 if checked out, 0 otherwise
" ===========================================================================
  let ischeckedout = system('cleartool describe -short ' . a:filename)

  if ischeckedout =~ "CHECKEDOUT"
    return 1
  endif
  return 0
endfunction

" ===========================================================================
function! s:GetComment(text)
" ===========================================================================
  " if a:type == 1
  "   let ci_co_text = 'checkout'
  " else
  "   let ci_co_text = 'checkin'
  " endif

  echohl Question
  if has("gui_running") && 
        \ exists("g:ccaseUseDialog") && 
        \ g:ccaseUseDialog == 1
    let comment = inputdialog(a:text)
  else
    let comment = input(a:text)
    echo "\n"
  endif
  echohl None
  return comment
endfunction " GetComment()

" ===========================================================================
function! s:CtMkelem(filename)
" Make the current file an element of the current directory.
" ===========================================================================
  "let ct_mkelem_basename = expand("%:p:h")
  let elem_basename = fnamemodify(a:filename,":p:h")
  echo "elem_basename: ".elem_basename

  " Is directory checked out?  If no, ask to check it out.
  let isCheckedOut = s:IsCheckedout(elem_basename)
  if isCheckedOut == 0
    echo "WARNING!  Current directory is not checked out."
    let checkoutdir = input("Would you like to checkout the current directory (y/n): ")
    while checkoutdir !~ '[Yy]\|[Nn]'
      echo "\n"
      let checkoutdir = input("Input 'y' for yes, or 'n' for no: ")
    endwhile
    
    " No, don't checkout the directory
    if checkoutdir =~ '[Nn]'
      echo "\nERROR:  Unable to make file an element!\n"
      return
    else " Else, Yes, checkout the directory
      " Checkout the directory
      call s:CtCheckout(elem_basename)

      " Check that directory actually got checked out
      let isCheckedOut = s:IsCheckedout(elem_basename)
      if isCheckedOut == 0
        echo "\nERROR!  Exitting, unable to checkout directory.\n"
        return
      endif
    endif
  "else
  "  echo "\nDEBUG:  Directory already checked out.\n"
  endif

  let comment = ""
  if g:ccaseNoComment == 0
    " Make the file an element, ClearCase will prompt for comment
    let comment = s:GetComment("Enter element creation comment: ")
  endif

  if g:ccaseMkelemCheckedout == 0
    let s:CheckinElem = "-ci"
  else
    let s:CheckinElem = ""
  endif

  " Allow to use the default or no comment
  if comment =~ "-nc" || comment == "" || comment == "."
    exe "!cleartool mkelem ".s:CheckinElem." -nc ".a:filename
  else
    exe "!cleartool mkelem ".s:CheckinElem." -c \"".comment."\" ".a:filename
  endif

  if g:ccaseAutoLoad == 1
    exe "e! ".a:filename
  endif

  if g:ccaseLeaveDirCO == 0
    let checkoutdir = 
          \ input("Would you like to checkin the current directory (y/n): ")
    while checkoutdir !~ '[Yy]\|[Nn]'
      echo "\n"
      let checkoutdir = input("Input 'y' for yes, or 'n' for no: ")
    endwhile

    " Check the directory back in, ClearCase will prompt for comment
    if checkoutdir =~ '[Yy]'
      " Don't reload the directory upon checking it back in
      let s:tempAutoLoad = g:ccaseAutoLoad
      let g:ccaseAutoLoad = 0

      call s:CtCheckin(elem_basename)

      let g:ccaseAutoLoad = s:tempAutoLoad
    else
      echo "\nNot checking directory back in."
    endif
  else
      echo "\nNot checking directory back in."
  endif

  " Check the newly made element in (don't need to, -ci option won't leave
  " file).
  "execute "!cleartool ci %"
endfunction " s:CtMkelem()

" ===========================================================================
function! s:CtCheckout(file)
" Function to perform a clearcase checkout for the current file
" ===========================================================================
  let comment = ""
  if g:ccaseNoComment == 0
    let comment = s:GetComment("Enter checkout comment: ")
  endif

  " Allow to use the default or no comment
  if comment =~ "-nc" || comment == "" || comment == "."
    exe "!cleartool co -nc ".a:file
    "DEBUG echo "!cleartool co -nc ".a:file
  else
    exe "!cleartool co -c \"".comment."\" ".a:file
    "DEBUG echo "!cleartool co -c \"'.comment."\" ".a:file
  endif

  if g:ccaseAutoLoad == 1
    exe "e! ".a:file
  endif
endfunction " s:CtCheckout()

" ===========================================================================
function! s:CtCheckin(file)
" Function to perform a clearcase checkin for the current file
" ===========================================================================
  let comment = ""
  if g:ccaseNoComment == 0
    let comment = s:GetComment("Enter checkin comment: ")
  endif

  " Allow to use the default or no comment
  if comment =~ "-nc" || comment == "" || comment == "."
    exe "!cleartool ci -nc ".a:file
    "DEBUG echo "!cleartool ci -nc ".a:file
  else
    exe "!cleartool ci -c \"".comment."\" ".a:file
    "DEBUG echo "!cleartool ci -c \"".comment."\" ".a:file
  endif

  if g:ccaseAutoLoad == 1
    exe "e! ".a:file
  endif
endfunction " s:CtCheckin()

" ===========================================================================
fun! s:ListActiv()
"     List current clearcase activity
" ===========================================================================
  exe '!cleartool lsactiv -cact'
endfun
"cab  ctlsa  call <SID>ListActiv()<cr>
cmap ctlsa  call <SID>ListActiv()

" ===========================================================================
fun! s:SetActiv()
"     Set current activity
" ===========================================================================
  let activity = input("Enter activity code to change to:")
  echo "\n"
  if activity != ""
    exe "!cleartool setactiv ".activity
  endif
endfun
"cab  ctsta call <SID>SetActiv()<cr>
cmap  ctsta call <SID>SetActiv()<cr>
" }}}
" ===========================================================================
"                         End of Function Definitions
" ===========================================================================

" ===========================================================================
"                   Beginning of Command line Abbreviations
" ===========================================================================
" {{{
"     Make current file an element in the vob
cab  ctmk   call <SID>CtMkelem(expand("%"))

"     Abbreviate cleartool
cab  ct     !cleartool
"     check-out buffer (w/ edit afterwards to get rid of RO property)
cab  ctco   call <SID>CtCheckout("<c-r>=expand("%:p")<cr>")
"     check-in buffer (w/ edit afterwards to get RO property)
cab  ctci   call <SID>CtCheckin("<c-r>=expand("%:p")<cr>")
"     uncheckout buffer (w/ edit afterwards to get RO property)
cab  ctunco !cleartool unco % <CR>:e!<cr>
"     Diff buffer with predecessor version
cab  ctpdif call <SID>CtConsoleDiff('<c-r>=expand("%:p")<cr>', 0)<cr>
"     Diff buffer with queried version
cab  ctqdif call <SID>CtConsoleDiff('<c-r>=expand("%:p")<cr>', 1)<cr>
"     describe buffer
cab  ctdesc !cleartool describe %
"     give version of buffer
cab  ctver  !cleartool describe -aattr version %

"     List my checkouts in the current view and directory
cab  ctcoc  !cleartool lsco -cview -short -me
"     List my checkouts in the current view and directory, and it's sub-dir's
cab  ctcor  !cleartool lsco -cview -short -me -recurse 
      \ > $HOME/tmp/results.txt<cr>:call OpenIfNew('~/tmp/results.txt')<cr>
"     List all my checkouts in the current view (ALL VOBS)
cab  ctcov  !cleartool lsco -avob -cview -short -me 
      \ > $HOME/tmp/results.txt<cr>:call OpenIfNew('~/tmp/results.txt')<cr>

"       These commands don't work the same on UNIX vs. WinDoze
if has("unix")
  "     buffer text version tree
  cab  cttree !cleartool lsvtree -all -merge %
        \ > $HOME/tmp/results.txt<CR>:sp ~/tmp/results.txt<CR>
  "     buffer history
  cab  cthist !cleartool lshistory %
        \ > $HOME/tmp/results.txt<CR>:sp ~/tmp/results.txt<CR>
  "     xlsvtree on buffer
  cab  ctxlsv !xlsvtree % &<CR>
  "     xdiff with predecessor
  "cab  ctdiff !cleartool xdiff -pred % &<CR>
  cab  ctdiff !cleartool diff -graphical -pred % &<CR>
  "     Give the current viewname
  cab  ctpwv echo "Current view is: "$view
else
  "     buffer text version tree
  cab  cttree !cleartool lsvtree -all -merge %
        \ > c:/temp/results.txt<CR>:sp c:/temp/results.txt<CR>
  "     buffer history
  cab  cthist !cleartool lshistory %
        \ > c:/temp/results.txt<CR>:sp c:/temp/results.txt<CR>
  "     xlsvtree on buffer
  cab  ctxlsv !start clearvtree.exe %<cr>
  "     xdiff with predecessor
  cab  ctdiff !start cleartool xdiff -pred %<CR>
  "     Give the current viewname
  cab  ctpwv !cleartool pwv
endif
" }}}
" ===========================================================================
"                              Beginning of Maps
" ===========================================================================
" {{{
" ===========================================================================
" Public Interface:
" ===========================================================================
if !hasmapto('<Plug>CleartoolCI')
  nmap <unique> <Leader>ctci <Plug>CleartoolCI
endif
if !hasmapto('<Plug>CleartoolCO')
  nmap <unique> <Leader>ctco <Plug>CleartoolCO
endif
if !hasmapto('<Plug>CleartoolUnCheckout')
  nmap <unique> <Leader>ctunco <Plug>CleartoolUnCheckout
endif
if !hasmapto('<Plug>CleartoolListHistory')
  nmap <unique> <Leader>cthist <Plug>CleartoolListHistory
endif
if !hasmapto('<Plug>CleartoolGraphVerTree')
  nmap <unique> <Leader>ctxl <Plug>CleartoolGraphVerTree
endif
if !hasmapto('<Plug>CleartoolConsolePredDiff')
  nmap <unique> <Leader>pdif <Plug>CleartoolConsolePredDiff
endif
if !hasmapto('<Plug>CleartoolConsoleQueryDiff')
  nmap <unique> <Leader>qdif <Plug>CleartoolConsoleQueryDiff
endif

" ===========================================================================
" Global Maps:
"       For use on a file that has filenames in it:
"       just put the cursor on the filename and use the map sequence.
" ===========================================================================
" nmap <unique> <script> <Plug>CleartoolCI
"       \ !cleartool ci -c <C-R>=input("Enter checkout comment: ")<CR>
"       \ <c-r>=expand("<cfile>")<cr>
" nmap <unique> <script> <Plug>CleartoolCO
"       \ :!cleartool co -c <C-R>=input("Enter checkout comment: ")<CR>
"       \ <c-r>=expand("<cfile>")<cr>
nmap <unique> <script> <Plug>CleartoolCI
      \ :call <SID>CtCheckin("<c-r>=expand("<cfile>")<cr>")<cr>
nmap <unique> <script> <Plug>CleartoolCO
      \ :call <SID>CtCheckout("<c-r>=expand("<cfile>")<cr>")<cr>
nmap <unique> <script> <Plug>CleartoolUnCheckout
      \ :!cleartool unco -rm <c-r>=expand("<cfile>")<cr>
nmap <unique> <script> <Plug>CleartoolListHistory
      \ :!cleartool lshistory <c-r>=expand("<cfile>")<cr>
      \ > $HOME/tmp/results.txt<cr>:call OpenIfNew('~/tmp/results.txt')<cr>
nmap <unique> <script> <Plug>CleartoolConsolePredDiff
      \ :call <SID>CtConsoleDiff('<c-r>=expand("<cfile>")<cr>', 0)<cr>
nmap <unique> <script> <Plug>CleartoolConsoleQueryDiff
      \ :call <SID>CtConsoleDiff('<c-r>=expand("<cfile>")<cr>', 1)<cr>

if has("unix")
  nmap <unique> <script> <Plug>CleartoolGraphVerTree 
        \ :!xlsvtree <c-r>=expand("<cfile>")<cr> &
else
  nmap <unique> <script> <Plug>CleartoolGraphVerTree 
        \ :!start clearvtree.exe <c-r>=expand("<cfile>")<cr>
endif
" }}}

" ===========================================================================
"                                 End of Maps
" ===========================================================================

"       On UNIX the vob prefix for directories is different from WinDoze.
if has("unix")
  let vob_prfx="/vobs/"
else
  let vob_prfx="./"
endif

" Shortcuts for common directories
"cab  vabc    <c-r>=vob_prfx<cr>abc_directory

" ===========================================================================
"                                 Setup Menus
" ===========================================================================
" {{{
" Add Menus if available
if (has("gui_running") && &guioptions !~# "M") ||
  \ &wildmenu

  " These use the mappings defined above to accomplish the same means.
  " It saves on space and makes things easier to maintain.

  " Clearcase menu
  " Hint: Using <Tab> makes alignment easy (Menus can have non-fixed
  "       width fonts, so just spaces are out of the question.
  amenu 60.300 &Clearcase.Check&out<Tab>:ctco
        \ :ctco<cr>
  amenu 60.310 &Clearcase.Check&in<Tab>:ctci
        \ :ctci<cr>
  amenu 60.320 &Clearcase.&Uncheckout<Tab>:ctunco
        \ :ctunco<cr>
  amenu 60.330 &Clearcase.&Make\ Element<Tab>:ctmk
        \ :ctmk<cr>
  amenu 60.400 &Clearcase.-SEP1-        :
  amenu 60.410 &Clearcase.&History<Tab>:cthist
        \ :cthist<cr>
  amenu 60.420 &Clearcase.&Describe<Tab>:ctdesc
        \ :ctdesc<cr>
  amenu 60.430 &Clearcase.&Version\ Tree<Tab>:ctxlsv
        \ :ctxlsv<cr>
  amenu 60.440 &Clearcase.&List\ Current\ Activity<Tab>:ctlsa
        \ :ctlsa<cr>
  amenu 60.450 &Clearcase.&Set\ Current\ Activity<Tab>:ctsta
        \ :ctsta<cr>
  amenu 60.500 &Clearcase.-SEP2-        :
  amenu 60.510 &Clearcase.Di&ff<Tab>:ctdiff
        \ :ctdiff<cr>
  amenu 60.510 &Clearcase.Diff\ this\ with\ &Pred<Tab>:ctpdif
        \ :ctpdif<cr>
  amenu 60.510 &Clearcase.Diff\ this\ with\ &Queried\ Version<Tab>:ctqdif
        \ :ctqdif<cr>
  amenu 60.520 &Clearcase.&Current\ View<Tab>:ctpwv
        \ :ctpwv<cr>
  amenu 60.530 &Clearcase.-SEP3-        :
  amenu 60.540 &Clearcase.List\ Checkouts\ in\ this\ dir<Tab>:ctcoc
        \ :ctcoc<cr>
  amenu 60.550 &Clearcase.List\ Checkouts\ recurse\ dir<Tab>:ctcor
        \ :ctcor<cr>
  amenu 60.560 &Clearcase.List\ Checkouts\ in\ VOB<Tab>:ctcov
        \ :ctcov<cr>
endif
" }}}

" vim:tw=80 nowrap fdm=marker :
