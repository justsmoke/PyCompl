" Author: justff

if v:version < 700
	echoerr 'vim 7.0 required'
endif

if exists("b:did_PyCompl")
	finish
endif

let b:did_PyCompl = 1

function Find(direction)
	let b:pos = col('.') - 2
	let b:line = getline('.')
	while b:pos > 0 && b:line[b:pos] =~ '\a'
		let b:pos -= 1
	endwhile
	if b:pos == 0 || b:line[b:pos] != '.'
		return "\<Tab>"
	endif
	if pumvisible()
		if a:direction == 'Down'
			return "\<C-N>"
		else
			return "\<C-P>"
		endif
	else
	 	return "\<C-X>\<C-O>"
	endif
endfunc

function PyComplFunc(findstart, base)
	if a:findstart
		let b:pos = col('.') - 2
		let b:line = getline('.')
		while b:pos > 0 && b:line[b:pos] !~ '\s'
			let b:pos -= 1
		endwhile
		return b:pos
	else
		return MakeDict(a:base)
endfunction

set omnifunc=PyComplFunc

inoremap <buffer><silent> <Tab> <C-R>=Find('Down')<CR>
inoremap <buffer><silent> <S-Tab> <C-R>=Find('Up')<CR>

function MakeDict(base)
python << EOF
import vim

modules = set()
depend_dict = {}

def makeDependecy():
	for line in vim.current.buffer:
		if line.startswith('from'):
			part = line.split(' ', 3)
			if part[0] == 'from' and part[2] == 'import':
				module = part[1]
				modules.add(module.strip())
				for method in part[3].split(','):
					depend_dict[method.strip()] = module
		if line.startswith('import'):
			part = line.split(' ', 1)
			if part[0] == 'import':
				for module in part[1].split(','):
					modules.add(module.strip())

def makeList(prefix):
	part = prefix.split()[-1].split('.')
	mod = part[0]
	while mod in depend_dict:
		tmp = depend_dict[mod]
		if tmp == mod:
			break
		else:
			mod = tmp
	if mod in modules:
		obj  = __import__(mod)
		for i in part[1:-2]:
			obj = getattr(obj, i)
		header = prefix[:-len(part[-1])]
		return [header + entry for entry in dir(obj) if entry.startswith(part[-1])]
	return []

if __name__ == '__main__':
	makeDependecy()
	prefix = vim.eval("a:base").strip()
	res = makeList(prefix)
	vim.command("let b:result_list = " + str(res))
EOF
return b:result_list
endfunction
