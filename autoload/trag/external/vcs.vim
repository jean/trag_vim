" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2014-07-03.
" @Revision:    163


if !exists('g:trag#external#vcs#options_git')
    let g:trag#external#vcs#options_git = {'args': 'grep -Hn -G %s --'}  "{{{2
endif


if !exists('g:trag#external#vcs#supported_kinds')
    let g:trag#external#vcs#supported_kinds = ['identity', 'w', 'todo']   "{{{2
endif


function! trag#external#vcs#IsSupported(kinds) "{{{3
    return trag#IsSupported(g:trag#external#vcs#supported_kinds, a:kinds)
endf


" Currently only git is supported.
function! trag#external#vcs#Run(rx, files) "{{{3
    " TLogVAR a:rx
    if exists('b:trag_support_vcs')
        if empty(b:trag_support_vcs)
            return 0
        else
            let [type, dir, bin] = b:trag_support_vcs
        endif
    else
        let b:trag_support_vcs = []
        let [type, dir] = tlib#vcs#FindVCS(expand('%'))
        if empty(type)
            return 0
        endif
        if !exists('g:trag#external#vcs#options_'. type)
            " echom 'Trag: Unsupported VCS type:' type
            return 0
        endif
        let bin = tlib#vcs#Executable(type)
        " TLogVAR bin
        if empty(bin)
            " echom 'Trag: Unsupported VCS type:' type
            return 0
        endif
        let b:trag_support_vcs = [type, dir, bin]
        " TLogVAR b:trag_support_vcs
    endif
    " TLogVAR type, dir, bin
    let ddir = fnamemodify(dir, ':p:h:h')
    let cd = getcwd()
    " TLogVAR type, dir, ddir, cd
    let gfm = &gfm
    let grepprg = &grepprg
    try
        let opts = g:trag#external#vcs#options_{type}
        " TLogVAR opts
        " TLogVAR exists('*trag#external#vcs#ConvertRx_'. type)
        let convert_rx = get(opts, 'convert_rx', 'trag#external#vcs#ConvertRx_'. type)
        if exists('*'. convert_rx)
            let rx = call(convert_rx, [type, a:rx])
        else
            let rx = a:rx
        endif
        " TLogVAR a:rx, rx
        let cmd = bin .' '. printf(get(opts, 'args', '%s'),
                    \ shellescape(rx, 1))
        let &grepprg = cmd
        " let &gfm = get(opts, 'gfm', '%m')
        let &gfm = get(opts, 'gfm', '%f:%l:%m')
        " TLogVAR &grepprg, &gfm
        let files = copy(a:files)
        let convert_filename = get(opts, 'convert_rx', 'trag#external#vcs#ConvertFilename_'. type)
        if exists('*'. convert_filename)
            let files = map(files, 'call(convert_filename, [type, v:val])')
        endif
        let files = map(files, 'fnameescape(v:val)')
        " TLogVAR files
        exec 'cd!' fnameescape(ddir)
        " TLogVAR getcwd()
        exec 'silent grepadd!' join(files)
        return 1
    finally
        if getcwd() != cd
            exec 'cd!' fnameescape(cd)
        endif
        let &gfm = gfm
        let &grepprg = grepprg
    endtry
    return 0
endf


function! trag#external#vcs#ConvertRx_git(type, rx) "{{{3
    let rx = substitute(a:rx, '\\C', '', 'g')
    " let rx = substitute(a:rx, '\\{-}', '\\+\\?', 'g')
    return rx
endf


function! trag#external#vcs#ConvertFilename_git(type, filename) "{{{3
    return substitute(a:filename, '\\', '/', 'g')
endf

