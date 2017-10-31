" autoload/pomo.vim
" Maintainer: Reinaldo Molina <rmolin88@gmail.com>
" Original Author:   Maximilian Nickel <max@inmachina.com>
" License:  MIT License

let s:pomo_id = 0
let s:pomo_name = ''
let s:pomo_status = 0
let s:pomodoro_started_at = -1 
let s:pomos_today = {}
let s:date_fmt = "%a %d %b %Y"
" This fmt seems to work well in unix and win systems
let s:time_fmt = "%H:%M:%S"

let s:pomo_ongoing_icon = "\ue003"
let s:pomo_shortpause_icon = "\ue005"
let s:pomo_longpause_icon = "\ue006"
let s:break_time = 0

function! pomo#notify() abort
	if exists("g:pomodoro_notification_cmd") 
	  call system(g:pomodoro_notification_cmd)
	endif
endfunction

function! pomo#remaining_time() abort
	return (g:pomodoro_time_work * 60 - abs(localtime() - s:pomodoro_started_at)) / 60
endfunction

function! pomo#status() abort
	if s:pomo_status == 0
		return 'Pomodoro inactive'
	elseif s:pomo_status == 1
		return 'Pomodoro ' . s:pomo_name . ' started (remaining: ' . pomo#remaining_time() . ' minutes)'
	elseif s:pomo_status > 1
		return 'Pomodoro ' . 
					\ (s:pomo_status == 2 ? 'short' : 'long') . 
					\ ' break started'
	endif
endfunction

function! pomo#status_bar() abort
	let use_icons = get(g:, 'pomodoro_use_devicons', 0)
	let show_time = get(g:, 'pomodoro_show_time_remaining', 0)
	if s:pomo_status == 0
		return ''
	elseif s:pomo_status == 1
		return (use_icons ? s:pomo_ongoing_icon . ' ' : 'Pomodoro ') .
					\ (empty(s:pomo_name) ? '' : s:pomo_name) .
					\ (use_icons ? '' : 'started ') . 
					\ (show_time ? '(' . pomo#remaining_time() . ' mins)': '')
	elseif s:pomo_status > 1
		if s:pomo_status == 2
			return (use_icons ? s:pomo_shortpause_icon . '('. pomo#remaining_time() . ' mins)' 
						\ : 'Pomodoro on short break')
		else
			return (use_icons ? s:pomo_longpause_icon . '('. pomo#remaining_time() . ' mins)'
						\ : 'Pomodoro on long break')
		endif
	endif
endfunction

function! pomo#stop() abort
	if s:pomo_status > 0
		let s:pomo_status = 0
		let s:pomodoro_started_at = -1
		call timer_stop(s:pomo_id)
	endif
endfunction

function! pomo#start(name) abort
	if s:pomo_status < 1
		let s:pomo_name = a:name
		let s:pomo_id = timer_start(g:pomodoro_time_work * 60 * 1000, function('pomo#rest'))
		let s:pomodoro_started_at = localtime()
		let s:pomo_status = 1 
		echom "Pomodoro Started at: " . strftime(s:date_fmt . " " . s:time_fmt)
		return
	elseif s:pomo_status == 1
		let msg = 'Pomodoro ' . s:pomo_name . ' is active'
	else " s:pomo_status > 1
		let msg = 'Pomodoro ' . s:pomo_name . ' is on break'
	endif
	let ch = confirm(msg, "&Stop\n&Restart\n&Cancel", 3)
	if ch == 1
		call pomo#stop()
	elseif ch == 2
		call pomo#stop()
		call pomo#start(s:pomo_name)
	endif
endfunction

function! pomo#rest(timer) abort
	let msg = "Pomodoro " . s:pomo_name . " ended at " . strftime(s:date_fmt . " " . s:time_fmt) . 
				\ ", duration: " . g:pomodoro_time_work . " minutes"
	call pomo#log(msg)
	let s:pomo_status = 2
	call pomo#notify()

	" Compose msg for break
	let msg = "Great, pomodoro " . s:pomo_name . " is finished!\n"
	let msg_normal_break = "Now, do you want to take a break for " . g:pomodoro_time_slack . " minutes?"
	let msg_reward = "Now would you break for " . g:pomodoro_time_reward . " minutes?"
	let pomos = pomo#get_num_pomos_today()
	if pomos > 0
		let msg .= "Congratulations! You have finished " . pomos . " today\n"
	endif

	if pomos % g:pomodoros_before_reward == 0
		let s:break_time = g:pomodoro_time_reward
		let choice = confirm(msg . msg_reward, "&Yes\n&No\nSkip Break", 1)
	else
		let s:break_time = g:pomodoro_time_slack
		let choice = confirm(msg . msg_normal_break, "&Yes\n&No\nSkip Break", 1)
	endif

	if choice == 1
		let s:pomo_id = timer_start(break * 60 * 1000, 'pomo#restart')
		return
	elseif choice == 2
		let s:pomo_status = 0
		return
	else
		call pomo#stop()
		call pomo#start(s:pomo_name)
	endif
endfunction

function! pomo#restart(timer) abort
	let s:pomo_status = 0
	call pomo#notify()
	let msg = s:break_time . " minutes break is over... Feeling rested?\nWant to start another ". 
				\ s:pomo_name . " pomodoro?"
	let choice = confirm(msg, "&Yes\n&No\n&Change the name", 1)
	if choice == 1
		exec "PomodoroStart " . s:pomo_name
	elseif choice == 2
		let s:pomo_status = 0
	elseif choice == 3
		let s:pomo_name = input("Please enter new pomodoro name: ", s:pomo_name)
		exec "PomodoroStart " . s:pomo_name
	endif
endfunction

function! pomo#log(msg) abort
	if exists("g:pomodoro_log_file")
		call writefile([a:msg], g:pomodoro_log_file, "a")
	endif
endfunction

function! pomo#get_num_pomos_today()
	if !exists("g:pomodoro_log_file")
		return -1 " No logging happening
	endif

	try
		let log = readfile(g:pomodoro_log_file)
	catch
		return -2
	endtry
	if empty(log)
		return -3
	endif

	let num = 0
	let search = strftime(s:date_fmt)
	for line in log
		if line =~# search
			let num += 1
		endif
	endfor
	return num
endfunction

" vim:tw=78:ts=2:sts=2:sw=2:
