" rc file for VIM, clearcase extensions {{{
" Author:               Douglas L. Potts
" Created:              17-Feb-2000
" Last Modified:        11-Sep-2002 14:58
"
" $Id: ccase.vim,v 1.29 2002/09/11 18:58:29 dp Exp $ }}}
"
" Modifications: {{{
" $Log: ccase.vim,v $
" Revision 1.29  2002/09/11 18:58:29  dp
" Corrected my misuse of 's:vars' as local, when I really was using
" 'l:vars' (local to the function, and the 'l:' not required).
"
" Implemented suggestion by Gary Johnson for the console diff
" function.  When used from a version tree or file browser,
" ccase would only append the version qualifier without
" checking that the filename given didn't already have one.
" Now works for fully qualified ClearCase filename with version
" (ex. filename@@/main/foo/1).
"
" Revision 1.28  2002/08/26 12:35:12  dp
" merged changes from 1.26 to provide a scratch buffer name to CtCmd and the string escape from Ingo Karkat (made to 1.25)
"
" Revision 1.27  2002/08/26 12:24:42  dp
" fixed brackets in bufname problem, as was discovered in version 1.25 on
" vim.sf.net
"
" Revision 1.26  2002/08/14 11:37:59  dp
" modified CtCmd function to take an optional parameter, the name for the
" results window
"
" Revision 1.25  2002/08/13 13:39:13  dp
" added results buffer capability similar to VTreeExplorer and other recent
" plugins, eliminates possible naming collisions between multiple users of the
" plugin on a shared system (ie. Unix/Linux).
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
" DONE:  Revise output capture method to use redir to put shell output into a
"        register, and open an unmodifiable buffer to put it in.
"        - Output is redirected to a temp file, then read into an unmodifiable
"        buffer.
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

" ===========================================================================
function! s:CtConsoleDiff( fname, ask_version )
" Requires: +diff
" Do a diff of the given filename with its cleartool predecessor or user
" specified version,
" ---------------------------------------------------------------------------

  if has("diff")
    let l:splittype = ""
    if g:ccaseDiffVertSplit == 1
      let l:splittype=":vert diffsplit "
    else
      let l:splittype=":diffsplit "
    endif

    " Determine root of the filename.  Necessary when the file we are editting
    " already as an '@@' version qualifier.
    let l:fname_and_ver = system('cleartool des -s -cview '.a:fname)
    let l:fname_and_ver = substitute(l:fname_and_ver, "\n", "", "g")

    if (a:ask_version != 0)
      let l:cmp_to_ver = ""
      let l:prompt_text = "Give version to compare to: "
      
      " While we aren't getting anything, keep prompting
      while (l:cmp_to_ver == "")
        if g:ccaseUseDialog == 1
          let l:cmp_to_ver = inputdialog(l:prompt_text)
        else
          let l:cmp_to_ver = input(l:prompt_text)
        endif
        echo "\n"
      endwhile

      " If they change their mind and want predecessor, allow that
      if l:cmp_to_ver =~ "pred"
        let l:cmp_to_ver = system('cleartool des -s -pre "'.l:fname_and_ver.'"')
      endif
    else
      echohl Question
      echo "Comparing to predecessor..."
      let l:cmp_to_ver = system('cleartool des -s -pre "'.l:fname_and_ver.'"')

      echo "Predecessor version: ". l:cmp_to_ver
      echohl None
    endif

    " Strip the file version information out
    let l:fname = substitute(l:fname_and_ver, "@@[^@]*$", "", "")

    " For the :diffsplit command, enclosing the filename in double quotes does
    " not work. Thus, the filename's spaces are escaped with \.
    " On Windows, this is not necessary; but it only works with escaped spaces
    " on Unix.
    let l:fname_escaped = escape(l:fname, ' ')
    exe l:splittype.l:fname_escaped.'@@'.l:cmp_to_ver
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
  let ischeckedout = system('cleartool describe -short "'.a:filename.'"')

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
  let comment = substitute(comment, '"\|!', '\\\0', "g")

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
    let l:CheckinElem = "-ci"
  else
    let l:CheckinElem = ""
  endif

  " Allow to use the default or no comment
  if comment =~ "-nc" || comment == "" || comment == "."
    exe "!cleartool mkelem ".l:CheckinElem." -nc \"".a:filename.'"'
  else
    exe "!cleartool mkelem ".l:CheckinElem." -c \"".comment."\" \"".a:filename.'"'
  endif

  if g:ccaseAutoLoad == 1
    exe "e! ".'"'a:filename.'"'
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
      let l:tempAutoLoad = g:ccaseAutoLoad
      let g:ccaseAutoLoad = 0

      call s:CtCheckin(elem_basename)

      let g:ccaseAutoLoad = l:tempAutoLoad
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
"
" TODO:  use range availability, a:firstline a:lastline, and a substitute()
" command to build the file list to do in one checkout.  Maybe have option to
" ask if all should be checked out under the same comment or not.  Will have to
" add a vmap down to the section that uses mapleader to call this.  Would have
" to add 'range' to end of function definition.
" - Could also add to CtCheckin
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

  exe "!cleartool co ".reserved_flag." ".comment_flag." \"".a:file.'"'

  if g:ccaseAutoLoad == 1
    exe "e! ".'"'.a:file.'"'
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
    exe "!cleartool ci -nc \"".a:file.'"'
    "DEBUG echo "!cleartool ci -nc ".a:file
  else
    exe "!cleartool ci -c \"".comment."\" \"".a:file.'"'
    "DEBUG echo "!cleartool ci -c \"".comment."\" ".a:file
  endif

  if g:ccaseAutoLoad == 1
    exe "e! ".'"'.a:file.'"'
  endif
endfunction " s:CtCheckin()

" ===========================================================================
fun! s:ListActiv(current_act)
"     List current clearcase activity
" ===========================================================================
  if a:current_act == "current"
    silent let @"=system('cleartool lsactiv -cact -short')
    let l:tmp = substitute(@", "\n", "", "g")
    echo l:tmp
  else " List all actvities
    call s:CtCmd("!cleartool lsactiv -short", "activity list")
    nmap <buffer> <2-Leftmouse> 
          \ :call <SID>SetActiv('<c-r><c-f>')<CR>
  endif
endfun " s:ListActiv
cab  ctlsa  call <SID>ListActiv("")<CR>
cab <silent> ctlsc call <SID>ListActiv("current")

" ===========================================================================
fun! s:SetActiv(activity)
"     Set current activity
" ===========================================================================
  " If NULL activity is passed in, then prompt for it.
  if a:activity == ""
    let l:activity = input("Enter activity code to change to: ")
    echo "\n"
  else
    let l:activity = a:activity
  endif

  if l:activity != ""
    exe "!cleartool setactiv ".l:activity
  else
    echohl Error
    echo "Not changing activity!"
    echohl None
  endif
endfun " s:SetActiv
cab  ctsta call <SID>SetActiv("")

" ===========================================================================
fun! s:CtCmd(cmd_string, ...)
" Execute ClearCase 'cleartool' command, and put the output into a results
" buffer.
"
" cmd_string - clearcase shell command to execute, and capture output for
" ...        - optional scratch buffer name string
" ===========================================================================
  if a:cmd_string != ""
    let tmpFile = tempname()

    " Capture output in a generated temp file
    exe a:cmd_string." > ".tmpFile
    
    let results_name = "ccase_results"

    " If name is passed in, overwrite our setting
    if a:0 > 0 && a:1 != ""
      let results_name = a:1
    endif

    " Now see if a results window is already there
    let results_bufno = bufnr(results_name)
    if results_bufno > 0
      silent exe "bd! ".results_bufno
    endif

    " Open a new results buffer, brackets are added here so that no false
    " positives match in trying to determine results_bufno above.
    silent exe "new [".results_name."]"
    "
    " Read in the output from our command
    silent exe "0r ".tmpFile

    " Setup the buffer to be a "special buffer"
    " thanks to T. Scott Urban here, I modeled my settings here off of his code
    " for VTreeExplorer
    setlocal noswapfile
    setlocal buftype=nofile
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
cab  ctunco !cleartool unco "%" <CR>:e!<cr>
"     Diff buffer with predecessor version
cab  ctpdif call <SID>CtConsoleDiff('<c-r>=expand("%:p")<cr>', 0)<cr>
"     Diff buffer with queried version
cab  ctqdif call <SID>CtConsoleDiff('<c-r>=expand("%:p")<cr>', 1)<cr>
"     describe buffer
cab  ctdesc !cleartool describe "%"
"     give version of buffer
cab  ctver  !cleartool describe -aattr version "%"

"     List my checkouts in the current view and directory
cab  ctcoc  !cleartool lsco -cview -short -me
"     List my checkouts in the current view and directory, and it's sub-dir's
cab  ctcor  call <SID>CtCmd("!cleartool lsco -cview -short -me -recurse")<CR>
"     List all my checkouts in the current view (ALL VOBS)
cab  ctcov  call <SID>CtCmd("!cleartool lsco -avob -cview -short -me",
      \ "checkouts")<CR>

"       These commands don't work the same on UNIX vs. WinDoze
if has("unix")
  "     buffer text version tree
  cab  cttree call <SID>CtCmd("!cleartool lsvtree -all -merge \"".expand("%").'"')<CR>
  "     buffer history
  cab  cthist call <SID>CtCmd("!cleartool lshistory \"".expand("%").'"')<CR>
  "     xlsvtree on buffer
  cab  ctxlsv !xlsvtree "%" &<CR>
  "     xdiff with predecessor
  cab  ctdiff !cleartool diff -graphical -pred "%" &<CR>
  "     Give the current viewname
  cab  ctpwv echohl Question\|echo "Current view is: "$view\|echohl None
else
  "     buffer text version tree
  cab  cttree call <SID>CtCmd("!cleartool lsvtree -all -merge \"".expand("%").'"')<CR>
  "     buffer history
  cab  cthist call <SID>CtCmd("!cleartool lshistory \"".expand("%").'"')<CR>
  "     xlsvtree on buffer
  cab  ctxlsv !start clearvtree.exe "%"<cr>
  "     xdiff with predecessor
  cab  ctdiff !start cleartool diff -graphical -pred "%"<CR>
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
