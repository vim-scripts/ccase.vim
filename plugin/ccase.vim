" rc file for VIM, clearcase extensions {{{
" Author:               Douglas L. Potts
" Created:              17-Feb-2000
" Last Modified:        01-Oct-2001 15:53
" Version:              1.4 (Vim-Online version)
"
" $Id: ccase.vim,v 1.8 2001/10/01 19:50:01 dp Exp $
" TODO:  Revise output capture method to use redir to put shell output into a
"        register, and open a unmodifiable buffer to put it in.
" TODO:  Add some of my other functions for doing a diff between current file
"        and predecessor using the new diff functionality in Vim 6.0.
"
" Modifications:
" $Log: ccase.vim,v $
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
" }}}

if !exists("$view") | finish | endif
if $view == "." | finish | endif
if exists('g:Clearcase_loaded') | finish |endif
let g:Clearcase_loaded = 1

" Setup statusline to show current view
set statusline=%<%f%h%m%r%=%{$view}\ %{&ff}\ %l,%c%V\ %P
let def_statusline="%<%f%h%m%r%=%{$view}\ %{&ff}\ %l,%c%V\ %P"

" Don't keep around other version control menus (CVS and RCS)
" create dummy entry so no warning message come up if they are already gone.
" DLP - I have cvsmenu.vim and rcs-menu.vim in my plugins directory, only
"       need one Version Control at a time though.
amenu &CVS.dummy echo "dummy"<cr>
aunmenu CVS
amenu &RCS.dummy echo "dummy"<cr>
aunmenu RCS

" If not already found elsewhere.
if !exists("*OpenIfNew")
  " ===========================================================================
  function! OpenIfNew( name )
  " I used the same logic in several functions, checking if the buffer was
  " already around, and then deleting and re-loading it, if it was.
  " ---------------------------------------------------------------------------
    " Find out if we already have a buffer for it
    let buf_no = bufnr(expand(a:name))

    " If there is a diffs.tx buffer, delete it
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
function! s:CtMkelem(filename)
" Make the current file an element of the current directory.
" ===========================================================================
  "let ct_mkelem_basename = expand("%:p:h")
  let elem_basename = fnamemodify(a:filename,":p:h")
  echo "elem_basename: ".elem_basename

  " Is directory checked out?  If no, ask to check it out.
  let isCheckedOut = <SID>IsCheckedout(elem_basename)
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
      execute "!cleartool co ".elem_basename

      " Check that directory actually got checked out
      let isCheckedOut = <SID>IsCheckedout(elem_basename)
      if isCheckedOut == 0
        echo "\nERROR!  Exitting, unable to checkout directory.\n"
        return
      endif
    endif
  "else
  "  echo "\nDEBUG:  Directory already checked out.\n"
  endif

  " Make the file an element, ClearCase will prompt for comment
  execute "!cleartool mkelem -ci ".a:filename

  let checkoutdir = input("Would you like to checkin the current directory (y/n): ")
  while checkoutdir !~ '[Yy]\|[Nn]'
    let checkoutdir = input("Input 'y' for yes, or 'n' for no: ")
  endwhile

  " Check the directory back in, ClearCase will prompt for comment
  if checkoutdir =~ '[Yy]'
    execute "!cleartool ci ".elem_basename
  else
    echo "\nNot checking directory back in."
  endif

  " Check the newly made element in (don't need to, -ci option won't leave
  " file).
  "execute "!cleartool ci %"
endfunction

"     Make current file an element in the vob
cab  ctmk   :call <SID>CtMkelem(expand("%"))<cr>

"     Abbreviate cleartool
cab  ct     !cleartool
"     check-out buffer (w/ edit afterwards to get rid of RO property)
cab  ctco   !cleartool co % <CR>:e!<CR>
"     check-in buffer (w/ edit afterwards to get RO property)
cab  ctci   !cleartool ci % <CR>:e!<cr>
"     uncheckout buffer (w/ edit afterwards to get RO property)
cab  ctunco !cleartool unco % <CR>:e!<cr>
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

"     List current clearcase activity
cab  ctlsa  call <SID>ListActiv()
fun! s:ListActiv()
  exe '!cleartool lsactiv -cact'
endfun

"     Set current activity
fun! s:SetActiv()
  let activity = input("Enter activity code to change to:")
  if activity != ""
    exe "!cleartool setactiv ".activity
  endif
endfun
cab  ctsta call <SID>SetActiv()<cr>

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

" Public Interface:
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

" Global Maps:
"       For use on a file that has filenames in it:
"       just put the cursor on the filename and use the map sequence.
nmap <unique> <script> <Plug>CleartoolCI
      \ :!cleartool ci -c <C-R>=input("Enter checkout comment: ")<CR>
      \ <c-r>=expand("<cfile>")<cr>
nmap <unique> <script> <Plug>CleartoolCO
      \ :!cleartool co -c <C-R>=input("Enter checkout comment: ")<CR>
      \ <c-r>=expand("<cfile>")<cr>
nmap <unique> <script> <Plug>CleartoolUnCheckout
      \ :!cleartool unco -rm <c-r>=expand("<cfile>")<cr>
nmap <unique> <script> <Plug>CleartoolListHistory
      \ :!cleartool lshistory <c-r>=expand("<cfile>")<cr>
      \ > $HOME/tmp/results.txt<cr>:call OpenIfNew('~/tmp/results.txt')<cr>
if has("unix")
  nmap <unique> <script> <Plug>CleartoolGraphVerTree 
        \ :!xlsvtree <c-r>=expand("<cfile>")<cr> &
else
  nmap <unique> <script> <Plug>CleartoolGraphVerTree 
        \ :!start clearvtree.exe <c-r>=expand("<cfile>")<cr>
endif

"       On UNIX the vob prefix for directories is different from WinDoze.
if has("unix")
  let vob_prfx="/vobs/"
else
  let vob_prfx="./"
endif

" Shortcuts for common directories
"cab  vabc    <c-r>=vob_prfx<cr>abc_directory

" Add Menus if available
if (has("gui_running") && &guioptions !~# "M") ||
  \ &wildmenu

  " These use the mappings defined above to accomplish the same means.
  " It saves on space and makes things easier to maintain.

  " Clearcase menu
  " Hint: Using <Tab> makes alignment easy (Menus can have non-fixed
  "       width fonts, so just spaces are out of the question.
  amenu 60.300 &Clearcase.Check&out<Tab>:ctco              :ctco<cr>
  amenu 60.310 &Clearcase.Check&in<Tab>:ctci               :ctci<cr>
  amenu 60.320 &Clearcase.&Uncheckout<Tab>:ctunco          :ctunco<cr>
  amenu 60.330 &Clearcase.&Make\ Element<Tab>:ctmk         :ctmk<cr>
  amenu 60.400 &Clearcase.-SEP1-        :
  amenu 60.410 &Clearcase.&History<Tab>:cthist             :cthist<cr>
  amenu 60.420 &Clearcase.&Describe<Tab>:ctdesc            :ctdesc<cr>
  amenu 60.430 &Clearcase.&Version\ Tree<Tab>:ctxlsv       :ctxlsv<cr>
  amenu 60.440 &Clearcase.&List\ Current\ Activity<Tab>:ctlsa   :ctlsa<cr>
  amenu 60.450 &Clearcase.&Set\ Current\ Activity<Tab>:ctsta   :ctsta<cr>
  amenu 60.500 &Clearcase.-SEP2-        :
  amenu 60.510 &Clearcase.Di&ff<Tab>:ctdiff                :ctdiff<cr>
  amenu 60.520 &Clearcase.&Current\ View<Tab>:ctpwv        :ctpwv<cr>
  amenu 60.530 &Clearcase.-SEP3-        :
  amenu 60.540 &Clearcase.List\ Checkouts\ in\ this\ dir<Tab>:ctcoc   :ctcoc<cr>
  amenu 60.550 &Clearcase.List\ Checkouts\ recurse\ dir<Tab>:ctcor    :ctcor<cr>
  amenu 60.560 &Clearcase.List\ Checkouts\ in\ VOB<Tab>:ctcov         :ctcov<cr>
endif

" vim:tw=80 nowrap fdm=marker :
