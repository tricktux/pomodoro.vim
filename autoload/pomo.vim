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
	if exists('g:pomodoro_notification_cmd')
	  if exists('*jobstart')
			call jobstart(g:pomodoro_notification_cmd)
		" Sun Jan 20 2019 13:07 Stopped working in vim 
		" elseif exists('*job_start')
			" call job_start(g:pomodoro_notification_cmd)
		else
			call system(g:pomodoro_notification_cmd)
		endif
	endif
endfunction

function! pomo#remaining_time() abort
	if s:pomo_status == 1
		return (g:pomodoro_time_work * 60 - abs(localtime() - s:pomodoro_started_at)) / 60
	elseif s:pomo_status > 1
		return (s:break_time * 60 - abs(localtime() - s:pomodoro_started_at)) / 60
	endif
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
	let l:use_icons = get(g:, 'pomodoro_use_devicons', 0)
	let l:show_time = get(g:, 'pomodoro_show_time_remaining', 0)
	if s:pomo_status == 0
		return ''
	elseif s:pomo_status == 1
		return (l:use_icons ? s:pomo_ongoing_icon . ' ' : '') .
					\ (empty(s:pomo_name) ? '' : s:pomo_name) .
					\ (l:use_icons ? '' : '') .
					\ (l:show_time ? ' (' . pomo#remaining_time() . ' m)': '')
	elseif s:pomo_status > 1
		if s:pomo_status == 2
			return (l:use_icons ? s:pomo_shortpause_icon . '('. pomo#remaining_time() . ' m)'
						\ : 'short break')
		else
			return (l:use_icons ? s:pomo_longpause_icon . '('. pomo#remaining_time() . ' m)'
						\ : 'long break')
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
		echom 'Pomodoro Started at: ' . strftime(s:date_fmt . ' ' . s:time_fmt)
		return
	elseif s:pomo_status == 1
		let l:msg = 'Pomodoro ' . s:pomo_name . ' is active'
	else " s:pomo_status > 1
		let l:msg = 'Pomodoro ' . s:pomo_name . ' is on break'
	endif

	let ch = confirm(l:msg, "&Stop\n&Restart\n&Cancel", 3)
	if ch == 1
		call pomo#stop()
	elseif ch == 2
		call pomo#stop()
		call pomo#start(s:pomo_name)
	endif
endfunction

function! pomo#rest(timer) abort
	let l:msg = 'Pomodoro ' . s:pomo_name . ' ended at ' . strftime(s:date_fmt . ' ' . s:time_fmt) .
				\ ', duration: ' . g:pomodoro_time_work . ' minutes'
	call pomo#log(l:msg)
	let s:pomo_status = 2
	call pomo#notify()

	" Compose msg for break
	let l:msg = 'Great, pomodoro ' . s:pomo_name . " is finished!\n"
	let l:msg_normal_break = 'Now, how would you like to take a break for ' . g:pomodoro_time_slack . ' minutes?'
	let l:msg_reward = 'Now would you break for ' . g:pomodoro_time_reward . ' minutes?'
	let l:pomos = pomo#get_num_pomos_today()
	if l:pomos > 0
		let l:msg .= 'Congratulations! You have finished ' . l:pomos . " today\n"
	endif

	if l:pomos % g:pomodoros_before_reward == 0
		let s:break_time = g:pomodoro_time_reward
		let choice = confirm(l:msg . l:msg_reward, "&Yes\n&No\nSkip Break", 1)
	else
		let s:break_time = g:pomodoro_time_slack
		let choice = confirm(l:msg . l:msg_normal_break, "&Yes\n&No\nSkip Break", 1)
	endif

	if choice == 1
		if s:break_time == g:pomodoro_time_reward
			let s:pomo_status = 3
		endif
		let s:pomodoro_started_at = localtime()
		let s:pomo_id = timer_start(s:break_time * 60 * 1000, 'pomo#restart')
	elseif choice == 2
		call pomo#stop()
	else
		call pomo#stop()
		call pomo#start(s:pomo_name)
	endif
endfunction

function! pomo#restart(timer) abort
	let s:pomo_status = 0
	call pomo#notify()
	let msg = s:break_time . " minutes break is over... Feeling rested?\nWant to start another ".
				\ s:pomo_name . ' pomodoro?'
	let choice = confirm(msg, "&Yes\n&No\n&Change the name", 1)
	if choice == 1
		exec 'PomodoroStart ' . s:pomo_name
	elseif choice == 2
		let s:pomo_status = 0
	elseif choice == 3
		let s:pomo_name = input('Please enter new pomodoro name: ', s:pomo_name)
		exec 'PomodoroStart ' . s:pomo_name
	endif
endfunction

function! pomo#log(msg) abort
	if exists('g:pomodoro_log_file')
		call writefile([a:msg], g:pomodoro_log_file, "a")
	endif
endfunction

function! pomo#get_num_pomos_today() abort
	if !exists('g:pomodoro_log_file')
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
