" rc file for VIM, clearcase extensions
" Author:       Douglas L. Potts
" Created:      17-Feb-2000
" Last Edit:    26-Sep-2001 09:31
" Version:      $Revision: 1.7 $
" Modifications:
" 17-Feb-2000 pottsdl   Created from .unixrc mappings
" 09-Mar-2000 pottsdl   Added Clearcase menu definition here.
"                       Made Menus use these mappings for ease of use.
" 09-Mar-2000 pottsdl   Changed so checkout will allow for changes made before
"                       checkout command was given, but still does the e! so
"                       that no warning message come up.
"                       Added ctver to give version.
" 18-Jan-2001 pottsdl   Put this file on my vim macros page.
" 08-Jun-2001 pottsdl   Versioned this script for upload to vim-online.
"
" $Id: ccase.vim,v 1.7 2001/09/07 14:01:32 dp Exp dp $
" $Log: ccase.vim,v $
" Revision 1.7  2001/09/07 14:01:32  dp
" Change $Rev to $Revision
"
" Revision 1.6  2001/09/07 14:01:10  dp
" *** empty log message ***
"
" Revision 1.5  2001/09/07 13:59:24  dp
" Changed how Version is determined
"
" Revision 1.4  2001/09/07 13:56:39  dp
" Removed '-nc' so that user will now be prompted for checkin and checkout
" comments.  Also removed common directory shortcuts since I don't use
" them anyway, but left in example for other users.
"
" -

if !exists("$view") | finish | endif
if $view == "." | finish | endif
if exists('g:Clearcase_loaded') | finish |endif
let g:Clearcase_loaded = 1

" Setup statusline to show current view
set statusline=%<%f%h%m%r%=%{$view}\ %{&ff}\ %l,%c%V\ %P
let def_statusline="%<%f%h%m%r%=%{$view}\ %{&ff}\ %l,%c%V\ %P"

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
cab  ctcor  !cleartool lsco -cview -short -me -recurse > $HOME/tmp/results.txt<cr>:call OpenIfNew('~/tmp/results.txt')<cr>
"     List all my checkouts in the current view (ALL VOBS)
cab  ctcov  !cleartool lsco -avob -cview -short -me > $HOME/tmp/results.txt<cr>:call OpenIfNew('~/tmp/results.txt')<cr>

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
  cab  cttree !cleartool lsvtree -all -merge % > $HOME/tmp/results.txt<CR>:sp ~/tmp/results.txt<CR>
  "     buffer history
  cab  cthist !cleartool lshistory % > $HOME/tmp/results.txt<CR>:sp ~/tmp/results.txt<CR>
  "     xlsvtree on buffer
  cab  ctxlsv !xlsvtree % &<CR>
  "     xdiff with predecessor
  "cab  ctdiff !cleartool xdiff -pred % &<CR>
  cab  ctdiff !cleartool diff -graphical -pred % &<CR>
  "     Give the current viewname
  cab  ctpwv echo "Current view is: "$view
else
  "     buffer text version tree
  cab  cttree !cleartool lsvtree -all -merge % > c:/temp/results.txt<CR>:sp c:/temp/results.txt<CR>
  "     buffer history
  cab  cthist !cleartool lshistory % > c:/temp/results.txt<CR>:sp c:/temp/results.txt<CR>
  "     xlsvtree on buffer
  cab  ctxlsv !start clearvtree.exe %<cr>
  "     xdiff with predecessor
  cab  ctdiff !start cleartool xdiff -pred %<CR>
  "     Give the current viewname
  cab  ctpwv !cleartool pwv
endif

"       For use on a file that has filenames in it:
"       just put the cursor on the filename and use the map sequence.
nmap ,ctci :!cleartool ci -c <C-R>=input("Enter checkout comment: ")<CR>
	\ <c-r>=expand("<cfile>")<cr>
nmap ,ctco :!cleartool co -c <C-R>=input("Enter checkout comment: ")<CR>
	\ <c-r>=expand("<cfile>")<cr>
nmap ,ctun :!cleartool unco -rm <c-r>=expand("<cfile>")<cr>
nmap ,cthist :!cleartool lshistory <c-r>=expand("<cfile>")<cr> > $HOME/tmp/results.txt<cr>:call OpenIfNew('~/tmp/results.txt')<cr>
if has("unix")
  nmap ,ctxl :!xlsvtree <c-r>=expand("<cfile>")<cr> &
else
  nmap ,ctxl :!start clearvtree.exe <c-r>=expand("<cfile>")<cr>
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
  amenu 60.310 &Clearcase.Check&out<Tab>:ctco              :ctco<cr>
  amenu 60.320 &Clearcase.Check&in<Tab>:ctci               :ctci<cr>
  amenu 60.330 &Clearcase.&Uncheckout<Tab>:ctunco          :ctunco<cr>
  amenu 60.340 &Clearcase.-SEP1-        :
  amenu 60.350 &Clearcase.&History<Tab>:cthist             :cthist<cr>
  amenu 60.360 &Clearcase.&Describe<Tab>:ctdesc            :ctdesc<cr>
  amenu 60.370 &Clearcase.&Version\ Tree<Tab>:ctxlsv       :ctxlsv<cr>
  amenu 60.390 &Clearcase.&List\ Current\ Activity<Tab>:ctlsa   :ctlsa<cr>
  amenu 60.400 &Clearcase.&Set\ Current\ Activity<Tab>:ctsta   :ctsta<cr>
  amenu 60.410 &Clearcase.-SEP2-        :
  amenu 60.420 &Clearcase.Di&ff<Tab>:ctdiff                :ctdiff<cr>
  amenu 60.430 &Clearcase.&Current\ View<Tab>:ctpwv        :ctpwv<cr>
  amenu 60.440 &Clearcase.-SEP3-        :
  amenu 60.450 &Clearcase.List\ Checkouts\ in\ this\ dir<Tab>:ctcoc   :ctcoc<cr>
  amenu 60.460 &Clearcase.List\ Checkouts\ recurse\ dir<Tab>:ctcor    :ctcor<cr>
  amenu 60.470 &Clearcase.List\ Checkouts\ in\ VOB<Tab>:ctcov         :ctcov<cr>
endif

" vim:tw=0 nowrap:
