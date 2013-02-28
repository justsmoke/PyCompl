" Author: YiFan Zhang (yifan.zhang.work1989@gmail.com)

if v:version < 700
	echoerr "vim 7.0 is required"
	finish
endif

inoremap <buffer> <silent> <Tab> <C-R>=<SID>Compl('Down')<CR>

inoremap <buffer> <silent> <S-Tab> <C-R>=<SID>Compl('Up')<CR>

fun! s:Compl(direction)
	if match(strpart(getline('.'), 0, col('.')-1), '\S') == -1
		return "\<Tab>"
	endif
	if !pumvisible()
		return "\<C-X>\<C-U>"
	else
		if a:direction == 'Up'
			return "\<Up>"
		else
			return "\<Down>"
	endif
endfun

fun! PyCompl(findstart, base)
	if a:findstart
		let s:res = []
		let s:pos = col('.')-1
		let s:line = getline('.')
		while s:pos >= 0 && s:line[s:pos] !~ '\s'
			let s:pos -= 1
		endwhile
		let s:pos += 1
		return s:pos
	else
		call s:MakeDict(a:base)
		return s:res
	endif
endfun

set completefunc=PyCompl

fun! s:MakeDict(base)
python << EOF
import vim

dependDict = {}
moduleList = ['__builtin__']

def origin(dependDict, parts):
	name = parts[0]
	while name in dependDict:
		name = dependDict[name]
		parts.insert(0, name)
	return parts

def dest(moduleList, parts):
	first = parts[0]
	try:
		if first in moduleList:
			mod = __import__(first)
		else:
			mod = __import__('__builtin__')
		for k in range(1, len(parts)-1):
			mod = getattr(mod, parts[k])
		prefix = parts[-1]
		return [word + item[len(prefix):] for item in dir(mod) if item.startswith(prefix)]
	except Exception, e:
		pass
	return ''

def init(l):
	if l.startswith("import "):
		for mod in l.split(' ', 1)[1].split(','):
			moduleList.append(mod.strip())
	if l.startswith("from "):
	  	part = l.split(' ', 3)
	  	if part[2] == 'import':
	  		mod = part[1]
	  		moduleList.append(mod)
	  		if part[3] == '*':
	  			for method in dir(__import__(mod)):
					dependDict[method] = mod
	  		else:
	  			for method in part[3].split(','):
					dependDict[method.strip()] = mod

word = vim.eval("a:base")
for line in vim.current.buffer:
	init(line.strip())
for item in dir(__builtins__):
	dependDict[item] = '__builtin__'
parts = origin(dependDict, word.split('.'))
result = dest(moduleList, parts)
vim.command("let s:res = %s" % str(result))
EOF
endfun
