compaudit () {
        emulate -L zsh
        setopt extendedglob
        [[ -n $commands[getent] ]] || getent () {
                if [[ $1 = hosts ]]
                then
                        sed 's/#.*//' /etc/$1 | grep -w $2
                elif [[ $2 = <-> ]]
                then
                        grep ":$2:[^:]*$" /etc/$1
                else
                        grep "^$2:" /etc/$1
                fi
        }
        if (( $# ))
        then
                local _compdir=''
        elif (( $#fpath == 0 ))
        then
                print 'compaudit: No directories in $fpath, cannot continue' >&2
                return 1
        else
                set -- $fpath
        fi
        (( $+_i_check )) || {
                local _i_q _i_line _i_file _i_fail=verbose
                local -a _i_files _i_addfiles _i_wdirs _i_wfiles
                local -a -U +h fpath
        }
        fpath=($*)
        (( $+_compdir )) || {
                local _compdir=${fpath[(r)*/$ZSH_VERSION/*]}
                [[ -z $_compdir ]] && _compdir=$fpath[1]
        }
        _i_wdirs=()
        _i_wfiles=()
        _i_files=(${^~fpath:/.}/^([^_]*|*~|*.zwc)(N))
        if [[ -n $_compdir ]]
        then
                if [[ $#_i_files -lt 20 || $_compdir = */Base || -d $_compdir/Base ]]
                then
                        _i_addfiles=()
                        if [[ -d $_compdir/Base/Core ]]
                        then
                                _i_addfiles=(${_compdir}/*/*(/^M))
                        elif [[ -d $_compdir/Base ]]
                        then
                                _i_addfiles=(${_compdir}/*(/^M))
                        fi
                        for _i_line in {1..$#_i_addfiles}
                        do
                                (( $_i_line )) || break
                                _i_file=${_i_addfiles[$_i_line]}
                                [[ -d $_i_file && -z ${fpath[(r)$_i_file]} ]] || _i_addfiles[$_i_line]=
                        done
                        fpath=($fpath $_i_addfiles)
                        _i_files=(${^~fpath:/.}/^([^_]*|*~|*.zwc)(N))
                fi
        fi
        [[ $_i_fail == use ]] && return 0
        local _i_owners="u0u${EUID}"
        local -a _i_exes
        _i_exes=(/proc/$$/exe /proc/$$/object/a.out)
        local _i_exe
        for _i_exe in $_i_exes
        do
                if [[ -e $_i_exe ]]
                then
                        if zmodload -F zsh/stat b:zstat 2> /dev/null
                        then
                                local -A _i_stathash
                                if zstat -H _i_stathash $_i_exe && [[ $_i_stathash[uid] -ne 0 ]]
                                then
                                        _i_owners+="u${_i_stathash[uid]}"
                                fi
                        fi
                        break
                fi
        done
        _i_wdirs=(${^fpath}(N-f:g+w:,-f:o+w:,-^${_i_owners}) ${^fpath:h}(N-f:g+w:,-f:o+w:,-^${_i_owners}))
        if (( $#_i_wdirs ))
        then
                local GROUP GROUPMEM _i_pw _i_gid
                if ((UID == EUID ))
                then
                        getent group $LOGNAME | IFS=: read GROUP _i_pw _i_gid GROUPMEM
                else
                        getent group $EGID | IFS=: read GROUP _i_pw _i_gid GROUPMEM
                fi
                if [[ $GROUP == $LOGNAME && ( -z $GROUPMEM || $GROUPMEM == $LOGNAME ) ]]
                then
                        _i_wdirs=(${^_i_wdirs}(N-f:g+w:^g:${GROUP}:,-f:o+w:,-^${_i_owners}))
                fi
        fi
        if [[ -f /etc/debian_version ]]
        then
                local _i_ulwdirs
                _i_ulwdirs=(${(M)_i_wdirs:#/usr/local/*})
                _i_wdirs=(${_i_wdirs:#/usr/local/*} ${^_i_ulwdirs}(Nf:g+ws:^g:staff:,f:o+w:,^u0))
        fi
        _i_wdirs=($_i_wdirs ${^fpath}.zwc^([^_]*|*~)(N-^${_i_owners}))
        _i_wfiles=(${^fpath}/^([^_]*|*~)(N-^${_i_owners}))
        case "${#_i_wdirs}:${#_i_wfiles}" in
                (0:0) _i_q=  ;;
                (0:*) _i_q=files  ;;
                (*:0) _i_q=directories  ;;
                (*:*) _i_q='directories and files'  ;;
        esac

    _i_explain_path() {
        local p=$1

        # macOS stat format:
        # %u = uid, %g = gid, %p = mode (octal, with file type bits)
        local uid mode
        uid=$(stat -f '%u' -- "$p" 2>/dev/null) || return
        mode=$(stat -f '%p' -- "$p" 2>/dev/null) || return

        local -a reasons=()

        # Mask off file-type bits: 0170000
        (( mode &= 07777 ))

        (( mode & 0020 )) && reasons+=("group-writable")
        (( mode & 0002 )) && reasons+=("world-writable")

        if [[ ! " ${_i_owners} " == *"u${uid}"* ]]; then
            reasons+=("owner=${uid} (not in allowed set ${_i_owners})")
        fi

        if (( ${#reasons} )); then
            print -r -- "  $p:"
            for r in $reasons; do
                print -r -- "    - $r"
            done
        fi
    }



    if [[ -n "$_i_q" ]]
    then
        [[ $_i_fail == verbose ]] && {
            print There are insecure ${_i_q}: >&2
            for p in $_i_wdirs $_i_wfiles; do
                _i_explain_path "$p" >&2
            done
        }
        return 1
    fi


}
