Vim-Pomodoro
============

vim-pomodoro is a [(Neo)Vim](http://www.vim.org) plugin for the [Pomodoro time management technique](http://www.pomodorotechnique.com/).  This is a fork that mitigate some issues with the original plugin.

It requires the `timers` feature.

Usage
-----
The usage of vim-pomodoro is simple. `:PomodoroStart [pomodoro_name]` starts a new pomodoro. 
The parameter `pomodoro_name` is optional. After a pomodoro has ended, a confirmation dialog will 
remind you to take a break. When the break has ended, another dialog will ask you if you want 
to start a new pomodoro. Furthermore, the remaining time of a pomodoro can be displayed in the 
statusline of vim.

If you do not want vim-pomodoro to use popup windows but text dialogs inside Vim, add 
`set guioptions+=c` to your `~/.gvimrc`. Please note that this will *globally* disable 
popup notification windows in Vim.

Also, in addition to the default notifications inside vim, vim-pomodoro allows you to add 
further external notifications, such as sounds, system-notification popups etc.

Configuration
-------------
Add the following options to your `~/.vimrc` to configure vim-pomodoro 

	" Duration of a pomodoro in minutes (default: 25)
	let g:pomodoro_time_work = 25

	" Duration of a break in minutes (default: 5)
	let g:pomodoro_time_slack = 5 

	" Log completed pomodoros, 0 = False, 1 = True (default: 0)
	let g:pomodoro_do_log = 0 

	" Path to the pomodoro log file (default: /tmp/pomodoro.log)
	let g:pomodoro_log_file = "/tmp/pomodoro.log" 

To display the remaining time of a pomodoro in your statusline, add 

	set statusline=%#ErrorMsg#%{pomo#status_bar()}%#StatusLine# 

to your `~/.vimrc` 

### Bells and Whistles

Notifications outside vim can be enabled through the option `g:pomodoro_notification_cmd`. 
For instance, to play a sound file after each completed pomodoro or break, add something like 

	let g:pomodoro_notification_cmd = "mpg123 -q ~/.vim/pomodoro-notification.mp3"

to your `~/.vimrc`. System-wide notifications can, for instance, be done via zenity and 
the option

	let g:pomodoro_notification_cmd = 'zenity --notification --text="Pomodoro finished"''

Installation
------------
The recommended installation method is via [vim-plug](https://github.com/junegunn/vim-plug). 
Add:

	Plug 'tricktux/pomodoro.vim'
