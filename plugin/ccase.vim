" rc file for VIM, clearcase extensions {{{
" Author:               Douglas L. Potts
" Created:              17-Feb-2000
" Last Modified:        13-Aug-2002 09:35
" Version:              1.11
"
" $Id: ccase.vim,v 1.25 2002/08/13 13:39:13 dp Exp $
"
" Modifications:
" $Log: ccase.vim,v $
" Revision 1.25  2002/08/13 13:39:13  dp
" added results buffer capability similar to VTreeExplorer and other recent plugins, eliminates possible naming collisions between multiple users of the plugin on a shared system (ie. Unix/Linux).
"
" Revision 1.24  2002/08/08 20:11:38  dp
" *** empty log message ***
"
" Revision 1.23  2002/04/08 14:52:34  dp
" Added checkout unreserved, menus, mappings, etc.
"
" Revision 1.22  2002/04/05 21:43:02  dp
" Added capability to checkout a file unreserved, either via 'cab' command line,
" or menu.
"
" Revision 1.21  2002/01/18 16:13:48  dp
" *** empty log message ***
"
" Revision 1.20  2002/01/16 18:00:01  dp
" Revised setactivity and lsactivity handling.
"
" Revision 1.19  2002/01/15 15:22:27  dp
" Fixed bug with normal mode mappings, used in conjunction with file checkout
" listings.
"
" Revision 1.16  2002/01/04 20:36:51  dp
" Added echohl for prompts and error messages.
"
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
" TODO:  Find a way to wrap up checkin/checkout operations with the file
"        explorer plugin.
" TODO:  Allow visual selections in results windows to be piped into requested
"        command. (ie on a list of checkouts, select multiple files to check
"        back in).
" DONE:  Intelligently escape quotes in comments inputted, so it doesn't confuse
"        ClearCase when the shell command is run.   (18-Jan-2002)
"
" DONE:  Maybe write up some documentation.     (12-Jan-2002)
"
" }}}

if exists('g:loaded_ccase') | finish |endif
let g:loaded_ccase = 1

" ===========================================================================
"                           Setup Default Behaviors
" ===========================================================================
"{{{

" If using compatible, get out of here
if &cp
  echohl Error
  echo "Cannot load ccase.vim with 'compatible' option set!"
  echohl None
  finish
endif

" TODO:  Work in using this mapping for the results window if window has the
"        list of activities in it.
"nmap <buffer> <2-leftmouse> :call <SNR>22_SetActiv("<c-r>=expand("<cWORD>")<cr>")<cr>
" TODO:  If in a listing of checkouts, allow double-click to split-open
"        the file under the cursor
"nmap <buffer> <2-leftmouse> <c-w>f

" If the *GUI* is running, either use the dialog box or regular prompt
if !exists("g:ccaseUseDialog")
  " If GUI is compiled in, default to use the dialog box
  if has("gui")
    let g:ccaseUseDialog = 1
  else
    " If no GUI compiled in, default to no dialog box
    let g:ccaseUseDialog = 0
  endif
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
"}}}

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
      echohl Question
      echo "Comparing to predecessor..."
      let s:cmp_to_ver = system('cleartool des -s -pre '.a:fname)
      let debug=expand(s:cmp_to_ver)

      echo "Predecessor version: ". debug
      echohl None
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

  " If comment entered, had double quotes in the text,
  " escape them, so the when the:
  " cleartool checkout -c "<comment_text>"
  "
  " is executed by the shell, it doesn't get confused by the extra quotes.
  " Single quotes are OK, since the checkout shell command uses double quotes
  " to surround the comment text.
  let comment = substitute(comment, '"', '\\\0', "g")

  return comment
endfunction " GetComment()

" ===========================================================================
function! s:CtMkelem(filename)
" Make the current file an element of the current directory.
" ===========================================================================
  let elem_basename = fnamemodify(a:filename,":p:h")
  echo "elem_basename: ".elem_basename

  " Is directory checked out?  If no, ask to check it out.
  let isCheckedOut = s:IsCheckedout(elem_basename)
  if isCheckedOut == 0
    echohl Error
    echo "WARNING!  Current directory is not checked out."
    echohl Question
    let checkoutdir = input("Would you like to checkout the current directory (y/n): ")
    while checkoutdir !~ '[Yy]\|[Nn]'
      echo "\n"
      let checkoutdir = input("Input 'y' for yes, or 'n' for no: ")
    endwhile
    echohl None
    
    " No, don't checkout the directory
    if checkoutdir =~ '[Nn]'
      echohl Error
      echo "\nERROR:  Unable to make file an element!\n"
      echohl None
      return
    else " Else, Yes, checkout the directory
      " Checkout the directory
      call s:CtCheckout(elem_basename,"r")

      " Check that directory actually got checked out
      let isCheckedOut = s:IsCheckedout(elem_basename)
      if isCheckedOut == 0
        echohl Error
        echo "\nERROR!  Exitting, unable to checkout directory.\n"
        echohl None
        return
      endif
    endif
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
    echohl Question
    let checkoutdir = 
          \ input("Would you like to checkin the current directory (y/n): ")
    while checkoutdir !~ '[Yy]\|[Nn]'
      echo "\n"
      let checkoutdir = input("Input 'y' for yes, or 'n' for no: ")
    endwhile
    echohl None

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
endfunction " s:CtMkelem()

" ===========================================================================
function! s:CtCheckout(file, reserved)
" Function to perform a clearcase checkout for the current file
" ===========================================================================
  let comment = ""
  if g:ccaseNoComment == 0
    echohl Question
    let comment = s:GetComment("Enter checkout comment: ")
    echohl None
  endif

  " Default is checkout reserved, if specified unreserved, then put in
  " appropriate switch
  if a:reserved == "u"
    let reserved_flag = "-unreserved"
  else
    let reserved_flag = ""
  endif

  " Allow to use the default or no comment
  if comment =~ "-nc" || comment == "" || comment == "."
    let comment_flag = "-nc"
  else
    let comment_flag = "-c \"".comment."\""
  endif

  exe "!cleartool co ".reserved_flag." ".comment_flag." ".a:file

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
    echohl Question
    let comment = s:GetComment("Enter checkin comment: ")
    echohl None
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
fun! s:ListActiv(current_act)
"     List current clearcase activity
" ===========================================================================
  if a:current_act == "current"
    "silent exe '!cleartool lsactiv -cact'
    let @"=system('cleartool lsactiv -cact -short')
    let s:tmp = substitute(@", "\n", "", "g")
    echo s:tmp
  else
    let tmpFile = tempname()
    exe '!cleartool lsactiv -short > '.tmpFile
    " id: unique "string" id
    " split:
    "     0 -- don't split
    "     1 -- split horizontally
    "     2 -- split vertically
    " clear: if the buffer should be cleared, if it
    "        already exists (usually set to 1)
    exe 'sp '.tmpFile
    " call ScratchBuffer(1, 1, 1)
    " exe '0r '.tmpFile
    " exe '!rm -f '.tmpFile
  endif
endfun " s:ListActiv
cab  ctlsa  call <SID>ListActiv("")<CR>
cab  ctlsc  call <SID>ListActiv("current")

" ===========================================================================
fun! s:SetActiv(activity)
"     Set current activity
" ===========================================================================
  " If NULL activity is passed in, then prompt for it.
  if a:activity == ""
    let s:activity = input("Enter activity code to change to: ")
    echo "\n"
  else
    let s:activity = a:activity
  endif

  if s:activity != ""
    exe "!cleartool setactiv ".s:activity
  else
    echohl Error
    echo "Not changing activity!"
    echohl None
  endif
endfun " s:SetActiv
cab  ctsta call <SID>SetActiv("")

" ===========================================================================
fun! s:CtCmd(cmd_string)
" Execute ClearCase 'cleartool' command, and put the output into a results
" buffer.
" ===========================================================================
  if a:cmd_string != ""
    let tmpFile = tempname()

    " Capture output in a generated temp file
    exe a:cmd_string." > ".tmpFile
    
    " Now see if a results window is already there
    if bufnr("[ccase_results]") > 0
      silent exe "bd! [ccase_results]"
    endif

    " Open a new results buffer
    silent exe "new [ccase_results]"
    "
    " Read in the output from our command
    silent exe "0r ".tmpFile

    " Setup the buffer to be a "special buffer"
    " thanks to T. Scott Urban here, I modeled my settings here off of his code
    " for VTreeExplorer
    setlocal noswapfile
    setlocal buftype=nowrite
    setlocal bufhidden=delete " d
    setlocal nomodifiable

    " Get rid of temp file
    if has('unix')
      silent exe "!rm ".tmpFile
    else
      silent exe "!del ".tmpFile
    endif
  endif
endfun " s:CtCmd

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
cab  ctco   call <SID>CtCheckout('<c-r>=expand("%:p")<cr>', "r")
"     check-out buffer (...) unreserved
cab  ctcou  call <SID>CtCheckout('<c-r>=expand("%:p")<cr>', "u")
"     check-in buffer (w/ edit afterwards to get RO property)
cab  ctci   call <SID>CtCheckin('<c-r>=expand("%:p")<cr>')
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
cab  ctcor  call <SID>CtCmd("!cleartool lsco -cview -short -me -recurse")<CR>
"     List all my checkouts in the current view (ALL VOBS)
cab  ctcov  call <SID>CtCmd("!cleartool lsco -avob -cview -short -me")

"       These commands don't work the same on UNIX vs. WinDoze
if has("unix")
  "     buffer text version tree
  cab  cttree call <SID>CtCmd("!cleartool lsvtree -all -merge ".expand("%"))<CR>
  "     buffer history
  cab  cthist call <SID>CtCmd("!cleartool lshistory ".expand("%"))<CR>
  "     xlsvtree on buffer
  cab  ctxlsv !xlsvtree % &<CR>
  "     xdiff with predecessor
  cab  ctdiff !cleartool diff -graphical -pred % &<CR>
  "     Give the current viewname
  cab  ctpwv echohl Question\|echo "Current view is: "$view\|echohl None
else
  "     buffer text version tree
  cab  cttree call <SID>CtCmd("!cleartool lsvtree -all -merge ".expand("%"))<CR>
  "     buffer history
  cab  cthist call <SID>CtCmd("!cleartool lshistory ".expand("%"))<CR>
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
  nmap <unique> <Leader>ctcor <Plug>CleartoolCO
endif
if !hasmapto('<Plug>CleartoolCOUnres')
  nmap <unique> <Leader>ctcou <Plug>CleartoolCOUnres
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
if !hasmapto('<Plug>CleartoolSetActiv')
  nmap <unique> <Leader>ctsta <Plug>CleartoolSetActiv
endif

" ===========================================================================
" Global Maps:
"       For use on a file that has filenames in it:
"       just put the cursor on the filename and use the map sequence.
" ===========================================================================
map <unique> <script> <Plug>CleartoolCI
      \ :call <SID>CtCheckin('<c-r>=expand("<cfile>")<cr>')<cr>

map <unique> <script> <Plug>CleartoolCO
      \ :call <SID>CtCheckout('<c-r>=expand("<cfile>", "r")<cr>')<cr>

map <unique> <script> <Plug>CleartoolCOUnres
      \ :call <SID>CtCheckout('<c-r>=expand("<cfile>", "u")<cr>')<cr>

map <unique> <script> <Plug>CleartoolUnCheckout
      \ :!cleartool unco -rm <c-r>=expand("<cfile>")<cr>

map <unique> <script> <Plug>CleartoolListHistory
      \ :call <SID>CtCmd("!cleartool lshistory ".expand("<cfile>"))<cr>

map <unique> <script> <Plug>CleartoolConsolePredDiff
      \ :call <SID>CtConsoleDiff('<c-r>=expand("<cfile>")<cr>', 0)<cr>

map <unique> <script> <Plug>CleartoolConsoleQueryDiff
      \ :call <SID>CtConsoleDiff('<c-r>=expand("<cfile>")<cr>', 1)<cr>

map <unique> <script> <Plug>CleartoolSetActiv
      \ :call <SID>SetActiv('<c-r>=expand("<cfile>")<cr>')<cr>

if has("unix")
  map <unique> <script> <Plug>CleartoolGraphVerTree 
        \ :!xlsvtree <c-r>=expand("<cfile>")<cr> &
else
  map <unique> <script> <Plug>CleartoolGraphVerTree 
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
  amenu 60.300 &Clearcase.Check&out\ (Reserved)<Tab>:ctco
        \ :ctco<cr>
  amenu 60.310 &Clearcase.Check&out\ Unreserved<Tab>:ctcou
        \ :ctcou<cr>
  amenu 60.320 &Clearcase.Check&in<Tab>:ctci
        \ :ctci<cr>
  amenu 60.330 &Clearcase.&Uncheckout<Tab>:ctunco
        \ :ctunco<cr>
  amenu 60.340 &Clearcase.&Make\ Element<Tab>:ctmk
        \ :ctmk<cr>
  amenu 60.400 &Clearcase.-SEP1-        :
  amenu 60.410 &Clearcase.&History<Tab>:cthist
        \ :cthist<cr>
  amenu 60.420 &Clearcase.&Describe<Tab>:ctdesc
        \ :ctdesc<cr>
  amenu 60.430 &Clearcase.&Version\ Tree<Tab>:ctxlsv
        \ :ctxlsv<cr>
  amenu 60.440 &Clearcase.&List\ Current\ Activity<Tab>:ctlsc
        \ :ctlsc<cr>
  amenu 60.450 &Clearcase.&List\ Activities<Tab>:ctlsa
        \ :ctlsa<cr>
  amenu 60.460 &Clearcase.&Set\ Current\ Activity<Tab>:ctsta
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
