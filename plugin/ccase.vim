" rc file for VIM, clearcase extensions {{{
" Author:               Douglas L. Potts
" Created:              17-Feb-2000
" Last Modified:        11-Aug-2003 08:03
"
" $Id: ccase.vim,v 1.35 2003/08/12 19:34:16 dp Exp $ }}}
"
" Modifications: {{{
" $Log: ccase.vim,v $
" Revision 1.35  2003/08/12 19:34:16  dp
" - Added variable for listing checkouts by anyone, or just 'me'.
" - Added save of comment text into global var so it is accessable across
"   starts and stops of vim.
" - Replaces some echo's with echomsg's so they are saved in vim err list.
" - Moved autocmds around, so buffer-local kemaps aren't lost by the
"   autocmds which automatically refresh the listing upon BufEnter.
" - Added uncheckout functionality into Vim function instead of relying on
"   shell to do it.
" - MakeActiv now prompts for an activity comment.
" - Activity functions no show the activity comment, including the
"   activity list window.
" - For the activity and checkout list windows, open new files below and
"   to the right of the originating list window.
" - Added check for maps of <unique><script> already being there so
"   resourcing the plugin doesn't give errors.
"
" Revision 1.34  2003/04/03 19:48:05  dp
" Cleanup from last checkin, and Guillaume Lafage's
" change for link resolution.
"
" Revision 1.33  2003/04/03 18:12:09  dp
" - Added menu item and function to open the ClearTool Project Explorer
"   (clearprojexp).
" - Put text coloring on for display of the current activity.
" - Added 'Enter' key equivalent buffer-local mappings for the activity and
"   checkout list windows (equivalent operation to that of Double-click
"   '<2-Leftmouse>' in vim-ese).
" - Also fixed problem with initial opening of the 'list' windows where they
"   would have the initial data, and the autocmd would kick in appending the
"   "updated" data, so multiple listing of the same file would occur.
"
" Revision 1.32  2002/10/21 12:22:11  dp
" added "show comment" command to menu and a "cabbrev" ctcmt, and
" changed autocmd for activity list so that if an activity is chosen via a double
" click on the mouse, that the window goes away (I think this is the desired
" behavior).
"
" Revision 1.31  2002/10/21 12:01:25  dp
" fix from Gary Johnson on cleartool describe, used to determine predecessor
" version for ctpdif, escaping missing on space in filename, seen on Windows.
"
" Revision 1.30  2002/09/25 17:06:46  dp
" Added buffer local settings to set the current activity, and update the
" checkout list window on BufEnter.  Also added ability to create an UCM
" activity (mkactiv).  See updates to the documentation (:h ccase-plugin).
"
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
" merged changes from 1.26 to provide a scratch buffer name to CtCmd and the
" string escape from Ingo Karkat (made to 1.25)
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
" DONE:  Work in using this mapping for the results window if window has the
"        list of activities in it. (17-Sep-2002)
" DONE:  If in a listing of checkouts, allow double-click to split-open
"        the file under the cursor. 17-Sep-2002)
" DONE:  Use the following autocmd local to the buffer for the checkouts result
"        buffer, so that when user re-enters the window that it is updated.
"        (17-Sep-2002)
"
" }}}

if exists('g:loaded_ccase') | finish | endif
let g:loaded_ccase = 1

" ===========================================================================
"                           Setup Default Behaviors
" ===========================================================================
"{{{

" If using compatible, get out of here
if &cp
  echohl Error
  echomsg "Cannot load ccase.vim with 'compatible' option set!"
  echohl None
  finish
endif

augroup ccase
  au!

  " NOTE:  Put the reload stuff first, otherwise the buffer-local mappings will
  "        be lost.
  "
  " Checkout List window, update listing of checkouts when window is re-entered
  au BufEnter *checkouts_recurse* silent exe
        \ "if exists('b:ccaseUsed') == 1|
        \ bd\|
        \ let s:listStr = '!cleartool lsco -short -cview -recurse' |
        \ if g:ccaseJustMe == 1 |
        \   let s:listStr = s:listStr.' -me' |
        \ endif |
        \ call s:CtCmd(s:listStr, 'checkouts_recurse') |
        \ endif"
  au BufEnter *checkouts_allvobs* silent exe
        \ "if exists('b:ccaseUsed') == 1|
        \ bd\|
        \ let s:listStr = '!cleartool lsco -short -cview -avobs' |
        \ if g:ccaseJustMe == 1 |
        \   let s:listStr = s:listStr.' -me' |
        \ endif |
        \ call s:CtCmd(s:listStr, 'checkouts_allvobs') |
        \ endif"

  " Activity List window mappings
  " Conconction is because I'm listing the activity comments in addition to the
  " activity tags
  au BufNewFile,BufEnter *activity_list* nmap <buffer> <2-leftmouse> :call <SID>CtChangeActiv()<cr><cr>
  au BufNewFile,BufEnter *activity_list* nmap <buffer> <CR>          :call <SID>CtChangeActiv()<cr><cr>

  " Checkout List window mappings
  " - Double-click split-opens file under cursor
  " - Enter on filename split-opens file under cursor
  au BufNewFile,BufRead,BufEnter *checkouts* nmap <buffer> <2-Leftmouse> :call <SID>OpenInNewWin("<c-r>=expand("<cfile>")<cr>")<cr>
  "au BufNewFile *checkouts* nnoremap <buffer> <CR> <c-w>f
  au BufNewFile,BufRead,BufEnter *checkouts* nmap <buffer> <cr> :call <SID>OpenInNewWin("<c-r>=expand("<cfile>")<cr>")<cr>

augroup END

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

" Upon making a new clearcase activity, default behavior is to change the
" current activiy to the newly created activity.
if !exists("g:ccaseSetNewActiv")
  let g:ccaseSetNewActiv = 1    " Default is to set to new activity
endif

" Do checkout listings for only the current user
if !exists("g:ccaseJustMe")
  let g:ccaseJustMe      = 1    " Default is to list for only the current user
endif

" On uncheckouts prompt for what to do
if !exists("g:ccaseAutoRemoveCheckout")
  let g:ccaseAutoRemoveCheckout = 0 " Default is to prompt the user
endif

" Setup statusline to show current view, if your environment sets the
" $view variable when inside a view.
if exists("$view")
  set statusline=%<%f%h%m%r%=%{$view}\ %{&ff}\ %l,%c%V\ %P
endif

" Use a global var here to keep comments across restarts
if !exists("g:ccaseSaveComment")
  let g:ccaseSaveComment = ""
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
    let l:fname_and_ver = system('cleartool des -s -cview "'.a:fname.'"')
    let l:fname_and_ver = substitute(l:fname_and_ver, "\n", "", "g")

    if (a:ask_version != 0)
      let l:cmp_to_ver = ""
      let l:prompt_text = "Give version to compare to: "

      " While we aren't getting anything, keep prompting
      echohl Question
      while (l:cmp_to_ver == "")
        if g:ccaseUseDialog == 1
          let l:cmp_to_ver = inputdialog(l:prompt_text, "", "")
        else
          let l:cmp_to_ver = input(l:prompt_text)
          echo "\n"
        endif
      endwhile
      echohl None

      " Give user a chance to abort: A version will not likely to be a <ESC>
      " character. <ESC> character means user press "Cancel":
      if l:cmp_to_ver == ""
        echohl WarningMsg
        echomsg "CCASE diff operation canceled!"
        echohl None
        return 1
      endif

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
    echomsg "Unable to use console diff function.  Requires +diff compiled in"
    echohl None
    return 2
  endif

  return 0
endfunction " s:CtConsoleDiff

" ===========================================================================
function! s:IsCheckedout( filename )
" Determine if the given filename (could be a directory) is currently
" checked out.
" Return 1 if checked out, 0 otherwise
" ===========================================================================
  let l:ischeckedout = system('cleartool describe -short "'.a:filename.'"')

  if l:ischeckedout =~ "CHECKEDOUT"
    return 1
  endif
  return 0
endfunction " s:IsCheckedout

" ===========================================================================
function! s:GetComment(text)
" Prompt use for checkin/checkout comment. The last entered comment will be
" the default. User enter comment will be recorded in a global vim variable
" (g:ccaseSaveComment) so that it will persist across vim starts and stops.
" s:comment, the return value of this function is:
"   0 - If user want to abort the opertion.
"   1 - If user enter a valid comment.
" ===========================================================================
  echohl Question
  if has("gui_running") &&
        \ exists("g:ccaseUseDialog") &&
        \ g:ccaseUseDialog == 1
    let l:comment = inputdialog(a:text, g:ccaseSaveComment, "")
  else
    let l:comment = input(a:text, g:ccaseSaveComment)
    echo "\n"
  endif
  echohl None

  " If the entered comment is a <ESC>, inform the caller to abort operation.
  " It should be impossible for one to use a <ESC> character as checkin /
  " checkout comment, so we're safe here:
  if l:comment == ""
    return 1
  else
    " Save this comment
    " If comment entered, had double quotes in the text,
    " escape them, so the when the:
    " cleartool checkout -c "<comment_text>"
    "
    " is executed by the shell, it doesn't get confused by the extra quotes.
    " Single quotes are OK, since the checkout shell command uses double quotes
    " to surround the comment text.
    let s:comment = substitute(l:comment, '"\|!', '\\\0', "g")
    " Save the unescaped text
    let g:ccaseSaveComment = l:comment
  endif

  return 0
endfunction " s:GetComment

" ===========================================================================
function! s:CtMkelem(filename)
" Make the current file an element of the current directory.
" ===========================================================================
  let l:retVal = 0
  let l:elem_basename = fnamemodify(a:filename,":p:h")
  echo "elem_basename: ".l:elem_basename

  " Is directory checked out?  If no, ask to check it out.
  let l:isCheckedOut = s:IsCheckedout(elem_basename)
  if l:isCheckedOut == 0
    echohl WarningMsg
    echo "WARNING!  Current directory is not checked out."
    echohl Question
    let l:checkoutdir =
          \ input("Would you like to checkout the current directory (y/n): ")
    while l:checkoutdir !~ '[Yy]\|[Nn]'
      echo "\n"
      let l:checkoutdir = input("Input 'y' for yes, or 'n' for no: ")
    endwhile
    echohl None

    " No, don't checkout the directory
    if l:checkoutdir =~ '[Nn]'
      echohl Error
      echomsg "\nERROR:  Unable to make file an element!\n"
      echohl None
      return 1
    else " Else, Yes, checkout the directory
      " Checkout the directory
      if s:CtCheckout(elem_basename,"r") == 0
        " Check that directory actually got checked out
        let l:isCheckedOut = s:IsCheckedout(elem_basename)
        if l:isCheckedOut == 0
          echohl Error
          echomsg "\nERROR!  Exitting, unable to checkout directory.\n"
          echohl None
          return 1
        endif
      else
        echohl Error
        echomsg "Canceling make elem operation too!"
        echohl None
        return 1
      endif
    endif
  endif

  let l:comment = ""
  if g:ccaseNoComment == 0
    " Make the file an element, ClearCase will prompt for comment
    if s:GetComment('Enter element creation comment: ') == 0
      let l:comment = s:comment
    else
      echohl WarningMsg
      echomsg "Make element canceled!"
      echohl None

      return 1
    endif
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
    let l:checkoutdir =
          \ input("Would you like to checkin the current directory (y/n): ")
    while l:checkoutdir !~ '[Yy]\|[Nn]'
      echo "\n"
      let l:checkoutdir = input("Input 'y' for yes, or 'n' for no: ")
    endwhile
    echohl None

    " Check the directory back in, ClearCase will prompt for comment
    if checkoutdir =~ '[Yy]'
      " Don't reload the directory upon checking it back in
      let l:tempAutoLoad = g:ccaseAutoLoad
      let g:ccaseAutoLoad = 0

      if s:CtCheckin(elem_basename) == 1
        let l:retVal = 1
        echohl WarningMsg
        echomsg "Checkin canceled!"
        echohl None
      endif

      let g:ccaseAutoLoad = l:tempAutoLoad
    else
      echo "\nNot checking directory back in."
    endif
  else
      echo "\nNot checking directory back in."
  endif
  return l:retVal
endfunction " s:CtMkelem

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
  if a:file == ""
    let l:file = resolve (expand("%:p"))
  else
    let l:file = resolve (a:file)
  endif

  let l:comment = ""
  if g:ccaseNoComment == 0
    if s:GetComment("Enter checkout comment: ") == 0
      let l:comment = s:comment
    else
      echohl WarningMsg
      echomsg "Checkout canceled!"
      echohl None
      return 1
    endif
  endif

  " Default is checkout reserved, if specified unreserved, then put in
  " appropriate switch
  if a:reserved == "u"
    let l:reserved_flag = "-unreserved"
  else
    let l:reserved_flag = ""
  endif

  " Allow to use the default or no comment
  if l:comment =~ "-nc" || l:comment == "" || l:comment == "."
    let l:comment_flag = "-nc"
  else
    let l:comment_flag = "-c \"".l:comment."\""
  endif

  exe "!cleartool co ".l:reserved_flag." ".l:comment_flag." \"".l:file.'"'

  if g:ccaseAutoLoad == 1
    if &modified == 1
      echohl WarningMsg
      echo "ccase: File modified before checkout, not doing autoload"
      echo "       to prevent losing changes."
      echohl None
    else
      exe "e! ".'"'.l:file.'"'
    endif
  endif
endfunction " s:CtCheckout

" ===========================================================================
function! s:CtCheckin(file)
" Function to perform a clearcase checkin for the current file
" ===========================================================================
  if a:file == ""
    let l:file = resolve (expand("%:p"))
  else
    let l:file = resolve (a:file)
  endif

  let l:comment = ""
  if g:ccaseNoComment == 0
    if s:GetComment("Enter checkin comment: ") == 0
      let l:comment = s:comment
    else
      echohl WarningMsg
      echomsg "Checkout canceled!"
      echohl None
      return 1
    endif
  endif

  " Allow to use the default or no comment
  if l:comment =~ "-nc" || l:comment == "" || l:comment == "."
    exe "!cleartool ci -nc \"".l:file.'"'
  else
    exe "!cleartool ci -c \"".l:comment."\" \"".l:file.'"'
  endif

  if g:ccaseAutoLoad == 1
    exe "e! ".'"'.l:file.'"'
  endif
endfunction " s:CtCheckin

" ===========================================================================
function! s:CtUncheckout(file)
"       Function to perform a clearcase uncheckout
" ===========================================================================

  if a:file == ""
    let l:file = resolve (expand("%:p"))
  else
    let l:file = resolve (a:file)
  endif

  if g:ccaseAutoRemoveCheckout == 1
    exe "!cleartool unco -rm \"".l:file.'"'
  else
    exe "!cleartool unco \"".l:file.'"'
  endif

  if g:ccaseAutoLoad == 1
    exe "e! ".'"'.l:file.'"'
  endif
endfunction " s:CtUncheckout

" ===========================================================================
fun! s:MakeActiv()
"     Create a clearcase activity
" ===========================================================================
  echohl Question
  let l:new_activity = input ("Enter new activity tag: ")
  echo "\n"
  echohl None

  let l:comment = ""
  if s:GetComment("Enter activity comment: ") == 0
    let l:comment = s:comment
  else
    echohl WarningMsg
    echomsg "Make Activity canceled!"
    echohl None
    return 1
  endif

  if l:new_activity != ""
    if g:ccaseSetNewActiv == 0
      let l:set_activity = "-nset"
    else
      let l:set_activity = ""
    endif

    " Allow to use the default or no comment
    if l:comment =~ "-nc" || l:comment == "" || l:comment == "."
      exe "!cleartool mkactiv ".l:set_activity." -nc ".l:new_activity
    else
      exe "!cleartool mkactiv ".l:set_activity." -c \"".l:comment."\" ".
            \ l:new_activity
    endif
  else
    echohl Error
    echomsg "No activity tag entered.  Command aborted."
    echohl None
  endif
endfun " s:MakeActiv
cab  ctmka  call <SID>MakeActiv()

" ===========================================================================
fun! s:ListActiv(current_act)
"     List current clearcase activity
" ===========================================================================
  if a:current_act == "current"
    silent let @"=system("cleartool lsactiv -cact -fmt \'\%n\t\%c\'")
    let l:tmp = substitute(@", "\n", "", "g")
    echohl Question
    echo l:tmp
    echohl None
  else " List all actvities
    call s:CtCmd("!cleartool lsactiv -fmt \'\\%n\t\\%c\'", "activity_list")
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
    echomsg "Not changing activity!"
    echohl None
  endif
endfun " s:SetActiv
cab  ctsta call <SID>SetActiv("")

" ===========================================================================
fun! s:OpenProjExp()
"     Function to open the UCM ClearCase Project Explorer.  Mainly checks
"     that executable is there and runs it if it is, otherwise it echoes an
"     error saying that you don't have it.
" ===========================================================================
  if executable('clearprojexp')
    silent exe "!clearprojexp &"
  else
    echohl Error
    echomsg "The ClearCase UCM Project Explorer executable does not exist"
    " Purposely left next line off of the 'echomsg'
    echo "or is not in your path."
    echohl None
  endif
endfun " s:OpenProjExp
cab ctexp call <SID>OpenProjExp()

" ===========================================================================
fun! s:CtMeStr()
" Return the string '-me' if the ccaseJustMe variable exists and is set.
" Used for checkout listings to limit checkouts to just the current user, or to
" any user with checkouts in the current view.
" ===========================================================================
  if g:ccaseJustMe == 1
    return '"-me"'
  else
    return '""'
  endif
  return '""'
endfun " s:CtMeStr

" ===========================================================================
fun! s:CtCmd(cmd_string, ...)
" Execute ClearCase 'cleartool' command, and put the output into a results
" buffer.
"
" cmd_string - clearcase shell command to execute, and capture output for
" ...        - optional scratch buffer name string
" ===========================================================================
  if a:cmd_string != ""
    let l:tmpFile = tempname()

    " Capture output in a generated temp file
    exe a:cmd_string." > ".l:tmpFile

    let l:results_name = "ccase_results"

    " If name is passed in, overwrite our setting
    if a:0 > 0 && a:1 != ""
      let l:results_name = a:1
    endif

    " Now see if a results window is already there
    let l:results_bufno = bufnr(l:results_name)
    if l:results_bufno > 0
      exe "bw! ".l:results_bufno
    endif

    " Open a new results buffer, brackets are added here so that no false
    " positives match in trying to determine results_bufno above.
    " silent exe "topleft new [".results_name."]"
    exe "topleft new [".l:results_name."]"

    setlocal modifiable
    " Read in the output from our command
    " silent exe "0r ".l:tmpFile
    exe "0r ".l:tmpFile

    " Setup the buffer to be a "special buffer"
    " thanks to T. Scott Urban here, I modeled my settings here off of his code
    " for VTreeExplorer
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal bufhidden=delete " d
    let      b:ccaseUsed=1    " Keep from loading data twice the first time
    setlocal nomodifiable

    " Get rid of temp file
    if has('unix')
      silent exe "!rm ".l:tmpFile
    else
      silent exe "!del ".l:tmpFile
    endif

  endif
endfun " s:CtCmd

" ===========================================================================
fu! s:CtChangeActiv()
" Do the operations for a change in activity from the [activity_list] buffer
" ===========================================================================
  let l:activity = substitute(getline("."), '^\(\S\+\)\s.*$', '\1', '')
  call s:SetActiv(l:activity)
  bd
endfun " s:CtChangeActiv

" ===========================================================================
function! s:OpenInNewWin(filename)
" Since checkouts buffer and activity buffer are opened at topleft, we want
" to open new files as bottomright.  This function will do that, while saving
" user settings, and restoring those settings after opening the new window.
" ===========================================================================
  let l:saveSplitBelow = &splitbelow
  let l:saveSplitRight = &splitright

  set splitbelow
  set splitright
  exe "split "a:filename

  let &splitbelow = l:saveSplitBelow
  let &splitright = l:saveSplitRight
endfun " s:OpenInNewWin

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
" cab  ctco   call <SID>CtCheckout('<c-r>=expand("%:p")<cr>', "r")
cab  ctco   call <SID>CtCheckout('', "r")
"     check-out buffer (...) unreserved
" cab  ctcou  call <SID>CtCheckout('<c-r>=expand("%:p")<cr>', "u")
cab  ctcou  call <SID>CtCheckout('', "u")
"     check-in buffer (w/ edit afterwards to get RO property)
" cab  ctci   call <SID>CtCheckin('<c-r>=expand("%:p")<cr>')
cab  ctci   call <SID>CtCheckin('')
"     uncheckout buffer (w/ edit afterwards to get RO property)
" cab  ctunco call <SID>CtUncheckout('<c-r>=expand("%:p")<cr>')
cab  ctunco call <SID>CtUncheckout('')
"     Diff buffer with predecessor version
cab  ctpdif call <SID>CtConsoleDiff('<c-r>=expand("%:p")<cr>', 0)<cr>
"     Diff buffer with queried version
cab  ctqdif call <SID>CtConsoleDiff('<c-r>=expand("%:p")<cr>', 1)<cr>
"     describe buffer
cab  ctdesc !cleartool describe "%"
"     give version of buffer
cab  ctver  !cleartool describe -aattr version "%"

"     List my checkouts in the current view and directory
cab  ctcoc  !cleartool lsco -cview -short <c-r>=<SID>CtMeStr()<cr>
"     List my checkouts in the current view and directory, and it's sub-dir's
cab  ctcor  call <SID>CtCmd("!cleartool lsco -short -cview ".<c-r>=<SID>CtMeStr()<cr>." -recurse",
      \ "checkouts_recurse")<CR>
"     List all my checkouts in the current view (ALL VOBS)
cab  ctcov  call <SID>CtCmd("!cleartool lsco -short -cview ".<c-r>=<SID>CtMeStr()<cr>." -avob",
      \ "checkouts_allvobs")<CR>
cab  ctcmt  !cleartool describe -fmt "Comment:\n'\%c'" %

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
  nmap <unique> <Leader>ctco <Plug>CleartoolCO
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
if !hasmapto('<Plug>CleartoolCI')
  map <unique> <script> <Plug>CleartoolCI
        \ :call <SID>CtCheckin('<c-r>=expand("<cfile>")<cr>')<cr>
endif

if !hasmapto('<Plug>CleartoolCO')
  map <unique> <script> <Plug>CleartoolCO
        \ :call <SID>CtCheckout('<c-r>=expand("<cfile>", "r")<cr>')<cr>
endif

if !hasmapto('<Plug>CleartoolCOUnres')
  map <unique> <script> <Plug>CleartoolCOUnres
        \ :call <SID>CtCheckout('<c-r>=expand("<cfile>", "u")<cr>')<cr>
endif

if !hasmapto('<Plug>CleartoolUnCheckout')
  map <unique> <script> <Plug>CleartoolUnCheckout
        \ :!cleartool unco -rm <c-r>=expand("<cfile>")<cr>
endif

if !hasmapto('<Plug>CleartoolListHistory')
  map <unique> <script> <Plug>CleartoolListHistory
        \ :call <SID>CtCmd("!cleartool lshistory ".expand("<cfile>"))<cr>
endif

if !hasmapto('<Plug>CleartoolConsolePredDiff')
  map <unique> <script> <Plug>CleartoolConsolePredDiff
        \ :call <SID>CtConsoleDiff('<c-r>=expand("<cfile>")<cr>', 0)<cr>
endif

if !hasmapto('<Plug>CleartoolConsoleQueryDiff')
  map <unique> <script> <Plug>CleartoolConsoleQueryDiff
        \ :call <SID>CtConsoleDiff('<c-r>=expand("<cfile>")<cr>', 1)<cr>
endif

if !hasmapto('<Plug>CleartoolSetActiv')
  map <unique> <script> <Plug>CleartoolSetActiv
        \ :call <SID>SetActiv('<c-r>=expand("<cfile>")<cr>')<cr>
endif

if !hasmapto('<Plug>CleartoolSetActiv')
  if has("unix")
    map <unique> <script> <Plug>CleartoolGraphVerTree
          \ :!xlsvtree <c-r>=expand("<cfile>")<cr> &
  else
    map <unique> <script> <Plug>CleartoolGraphVerTree
          \ :!start clearvtree.exe <c-r>=expand("<cfile>")<cr>
  endif
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
  amenu 60.421 &Clearcase.&Show\ Comment<Tab>:ctcmt
        \ :ctcmt<cr>
  amenu 60.430 &Clearcase.&Version\ Tree<Tab>:ctxlsv
        \ :ctxlsv<cr>
  amenu 60.435 &Clearcase.-SEP4-        :
  amenu 60.440 &Clearcase.&List\ Current\ Activity<Tab>:ctlsc
        \ :ctlsc<cr>
  amenu 60.450 &Clearcase.&List\ Activities<Tab>:ctlsa
        \ :ctlsa<cr>
  amenu 60.460 &Clearcase.&Set\ Current\ Activity<Tab>:ctsta
        \ :ctsta<cr>
  amenu 60.470 &Clearcase.&Create\ New\ Activity<Tab>:ctmka
        \ :ctmka<cr>
  amenu 60.480 &Clearcase.&Open\ Clearprojexp :call <SID>OpenProjExp()<cr>
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
  amenu 60.600 &Clearcase.-SEP5-        :
  amenu 60.600 &Clearcase.&Help<Tab>:h\ ccase :h ccase<cr>
endif
" }}}

" vim:tw=80 nowrap fdm=marker :
