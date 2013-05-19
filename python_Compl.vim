" Author: YiFan Zhang (zhangyf.work@yahoo.com)

if v:version < 700
	echoerr "vim 7.0 is required"
	finish
endif

if exists("b:did_pyCompl")
	finish
endif
let b:did_pyCompl = 1

inoremap <buffer> <silent> <Tab> <C-R>=<SID>Compl('Down')<CR>
inoremap <buffer> <silent> <S-Tab> <C-R>=<SID>Compl('Up')<CR>

func! s:Compl(direction)
	if match(strpart(getline('.'), 0, col('.')-1), '\S') == -1
		return "\<Tab>"
	endif
	if !pumvisible()
		return "\<C-X>\<C-O>"
	else
		if a:direction == 'Up'
			return "\<Up>"
		else
			return "\<Down>"
	endif
endfunc

func! ftplugin#python_Compl#PyCompl(findstart, base)
	if a:findstart
		let s:res = []
		let s:pos = col('.')-1
		let s:line = getline('.')
		while s:pos >= 0 && s:line[s:pos] !~ '\s'
			let s:pos -= 1
		endwhile
		return s:pos + 1
	else
		call s:MakeDict(a:base)
		return s:res
	endif
endfunc

set omnifunc=ftplugin#python_Compl#PyCompl

func! s:MakeDict(base)
python << EOF
import vim

dependDict = {}
moduleList = []

def origin(dependDict, parts):
	name = parts[0]
	while name in dependDict:
		name = dependDict[name]
		parts.insert(0, name)
	return parts

def dest(moduleList, parts):
	mod = parts[0]
	if mod in moduleList:
		mod = __import__(mod)
	else:
		return []
	for k in range(1, len(parts)-1):
		mod = getattr(mod, parts[k])
	prefix = parts[-1]
	return [word + item[len(prefix):] for item in dir(mod) if item.startswith(prefix)]

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
parts = origin(dependDict, word.split('.'))
result = dest(moduleList, parts)
vim.command("let s:res = %s" % str(result))
EOF
endfunc
