" rc file for VIM, clearcase extensions
" Author:       Douglas L. Potts
" Created:      17-Feb-2000
" Last Edit:    08-Jun-2001 09:45
" Version:      1.0
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
" -

if $view == "." | finish | endif
if exists('g:Clearcase_loaded') | finish |endif
let g:Clearcase_loaded = 1

"     check-out buffer (w/ edit afterwards to get rid of RO property)
cab  ctco !cleartool co -nc % <CR>:e!<CR>
"     check-in buffer (w/ edit afterwards to get RO property)
cab  ctci !cleartool ci -nc % <CR>:e!<cr>
"     uncheckout buffer (w/ edit afterwards to get RO property)
cab  ctunco !cleartool unco % <CR>:e!<cr>
"     describe buffer
cab  ctdesc !cleartool describe %
"     give version of buffer
cab  ctver  !cleartool describe -aattr version %

"     List my checkouts in the current view and directory
cab  ctcoc !cleartool lsco -cview -short -me
"     List my checkouts in the current view and directory, and it's sub-dir's
cab  ctcor !cleartool lsco -cview -short -me -recurse > $HOME/tmp/results.txt<cr>:call OpenIfNew('~/tmp/results.txt')<cr>
"     List all my checkouts in the current view (ALL VOBS)
cab  ctcov !cleartool lsco -avob -cview -short -me > $HOME/tmp/results.txt<cr>:call OpenIfNew('~/tmp/results.txt')<cr>

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
nmap ,ctci :!cleartool ci -nc   <c-r>=expand("<cfile>")<cr>
nmap ,ctco :!cleartool ci -no   <c-r>=expand("<cfile>")<cr>
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
cab  vsys    <c-r>=vob_prfx<cr>system

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
  amenu 60.340 &Clearcase.&History<Tab>:cthist             :cthist<cr>
  amenu 60.350 &Clearcase.&Describe<Tab>:ctdesc            :ctdesc<cr>
  amenu 60.360 &Clearcase.&Version\ Tree<Tab>:ctxlsv       :ctxlsv<cr>
  amenu 60.370 &Clearcase.Di&ff<Tab>:ctdiff                :ctdiff<cr>
  amenu 60.380 &Clearcase.&Current\ View<Tab>:ctpwv        :ctpwv<cr>
  amenu 60.390 &Clearcase.List\ Checkouts\ in\ this\ dir<Tab>:ctcoc   :ctcoc<cr>
  amenu 60.400 &Clearcase.List\ Checkouts\ recurse\ dir<Tab>:ctcor    :ctcor<cr>
  amenu 60.410 &Clearcase.List\ Checkouts\ in\ VOB<Tab>:ctcov         :ctcov<cr>
endif

" vim:tw=0 nowrap:
