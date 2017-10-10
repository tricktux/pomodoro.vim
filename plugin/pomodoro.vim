" plugin/pomodoro.vim
" Maintainer: Reinaldo Molina <rmolin88@gmail.com>
" Original Author:   Maximilian Nickel <max@inmachina.com>
" License:  MIT License 
"
" Vim plugin for the Pomodoro time management technique. 
"
" Commands:
" 	:PomodoroStart [name] - Start a new pomodoro. [name] is optional.
" 	:PomodoroStatus       - Display status of Pomodoro
"
" Configuration: 
" 	g:pomodoro_time_work 	-	Duration of a pomodoro 
" 	g:pomodoro_time_slack 	- 	Duration of a break 
" 	g:pomodoro_log_file 	- 	Path to log file

if exists("g:loaded_pomodoro")
  finish
endif

if !has('timers')
	echo 'Vim/Neovim doesnt not have support for timers. Ergo plugin will not work'
	finish
endif

let g:loaded_pomodoro = 1

if !exists('g:pomodoro_show_time_remaining')
	let g:pomodoro_show_time_remaining = 1 
endif

if !exists('g:pomodoro_time_work')
  let g:pomodoro_time_work = 25
endif

if !exists('g:pomodoro_time_slack')
  let g:pomodoro_time_slack = 5
endif

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=? PomodoroStart call pomo#start(<q-args>)
command! PomodoroStatus echo pomo#status()
command! PomodoroStop call pomo#stop()

" vim:tw=78:ts=2:sts=2:sw=2:
