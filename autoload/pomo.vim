" autoload/pomo.vim
" Maintainer: Reinaldo Molina <rmolin88@gmail.com>
" Original Author:   Maximilian Nickel <max@inmachina.com>
" License:  MIT License

let s:pomo_id = 0
let s:pomo_name = ''
let s:pomodoro_started = 0
let s:pomodoro_started_at = -1 

function! pomo#notify() abort
	if exists("g:pomodoro_notification_cmd") 
	  call system(g:pomodoro_notification_cmd)
	endif
endfunction

function! pomo#remaining_time() abort
	return (g:pomodoro_time_work * 60 - abs(localtime() - s:pomodoro_started_at)) / 60
endfunction

function! pomo#status() abort
	if s:pomodoro_started == 0
		return "Pomodoro inactive"
	elseif s:pomodoro_started == 1
		return "Pomodoro " . s:pomo_name . " started (remaining: " . pomo#remaining_time() . " minutes)"
	elseif s:pomodoro_started == 2
		return "Pomodoro break started"
	endif
endfunction

function! pomo#status_bar() abort
	if s:pomodoro_started == 0
		return ''
	elseif s:pomodoro_started == 1
		if g:pomodoro_show_time_remaining == 1
			return "Pomodoro " . s:pomo_name . " started (remaining: " . pomo#remaining_time() . " minutes)"
		else
			return "Pomodoro " . s:pomo_name . " active"
		endif
	elseif s:pomodoro_started == 2
		return "Pomodoro on break"
	endif
endfunction

function! pomo#stop() abort
	if s:pomodoro_started > 0
		let s:pomodoro_started = 0
		let s:pomodoro_started_at = -1
		call timer_stop(s:pomo_id)
	endif
endfunction

function! pomo#start(name) abort
	if s:pomodoro_started != 1
		let s:pomo_name = a:name
		let s:pomo_id = timer_start(g:pomodoro_time_work * 60 * 1000, function('pomo#rest'))
		let s:pomodoro_started_at = localtime()
		let s:pomodoro_started = 1 
		echom "Pomodoro Started at: " . strftime('%I:%M:%S %m/%d/%Y')
	endif
endfunction

function! pomo#rest(timer) abort
	let s:pomodoro_started = 2
	call pomo#notify()
	let msg = "Great, pomodoro " . s:pomo_name . " is finished!\nNow, do you want to take a break for " . g:pomodoro_time_slack . " minutes?"
	let choice = confirm(msg, "&Yes\n&No", 1)
	" TODO-[RM]-(Sat Sep 23 2017 16:28): 
	" - Log stuff in a not OS dependent way.
	if exists("g:pomodoro_log_file")
		exe "!echo 'Pomodoro " . s:pomo_name . " ended at " . strftime("%c") . 
					\ ", duration: " . g:pomodoro_time_work . " minutes' >> " . g:pomodoro_log_file
	endif
	if choice == 2
		let s:pomodoro_started = 0
		return
	endif
	let s:pomo_id = timer_start(g:pomodoro_time_slack * 60 * 1000, 'pomo#restart')
endfunction

function! pomo#restart(timer) abort
	let s:pomodoro_started = 0
	call pomo#notify()
	let msg = g:pomodoro_time_slack . " minutes break is over... Feeling rested?\nWant to start another ". s:pomo_name . " pomodoro?"
	let choice = confirm(msg, "&Yes\n&No\n&Change the name", 1)
	if choice == 1
		exec "PomodoroStart " . s:pomo_name
	elseif choice == 2
		let s:pomodoro_started = 0
	elseif choice == 3
		let s:pomo_name = input("Please enter new pomodoro name: ", s:pomo_name)
		exec "PomodoroStart " . s:pomo_name
	endif
endfunction

" vim:tw=78:ts=2:sts=2:sw=2:
