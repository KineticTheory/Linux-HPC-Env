#!/bin/bash

shopt -s extglob

__expand_tilde_by_ref ()
{
    if [[ ${!1} == \~* ]]; then
        if [[ ${!1} == */* ]]; then
            eval $1="${!1/%\/*}"/'${!1#*/}';
        else
            eval $1="${!1}";
        fi;
    fi
}
__get_cword_at_cursor_by_ref ()
{
    local cword words=();
    __reassemble_comp_words_by_ref "$1" words cword;
    local i cur index=$COMP_POINT lead=${COMP_LINE:0:$COMP_POINT};
    if [[ $index -gt 0 && ( -n $lead && -n ${lead//[[:space:]]} ) ]]; then
        cur=$COMP_LINE;
        for ((i = 0; i <= cword; ++i ))
        do
            while [[ ${#cur} -ge ${#words[i]} && "${cur:0:${#words[i]}}" != "${words[i]}" ]]; do
                cur="${cur:1}";
                ((index--));
            done;
            if [[ $i -lt $cword ]]; then
                local old_size=${#cur};
                cur="${cur#"${words[i]}"}";
                local new_size=${#cur};
                index=$(( index - old_size + new_size ));
            fi;
        done;
        [[ -n $cur && ! -n ${cur//[[:space:]]} ]] && cur=;
        [[ $index -lt 0 ]] && index=0;
    fi;
    local "$2" "$3" "$4" && _upvars -a${#words[@]} $2 "${words[@]}" -v $3 "$cword" -v $4 "${cur:0:$index}"
}
__git_eread ()
{
    local f="$1";
    shift;
    test -r "$f" && read "$@" < "$f"
}
__git_ps1 ()
{
    local exit=$?;
    local pcmode=no;
    local detached=no;
    local ps1pc_start='\u@\h:\w ';
    local ps1pc_end='\$ ';
    local printf_format=' (%s)';
    case "$#" in
        2 | 3)
            pcmode=yes;
            ps1pc_start="$1";
            ps1pc_end="$2";
            printf_format="${3:-$printf_format}";
            PS1="$ps1pc_start$ps1pc_end"
        ;;
        0 | 1)
            printf_format="${1:-$printf_format}"
        ;;
        *)
            return $exit
        ;;
    esac;
    local ps1_expanded=yes;
    [ -z "$ZSH_VERSION" ] || [[ -o PROMPT_SUBST ]] || ps1_expanded=no;
    [ -z "$BASH_VERSION" ] || shopt -q promptvars || ps1_expanded=no;
    local repo_info rev_parse_exit_code;
    repo_info="$(git rev-parse --git-dir --is-inside-git-dir 		--is-bare-repository --is-inside-work-tree 		--short HEAD 2>/dev/null)";
    rev_parse_exit_code="$?";
    if [ -z "$repo_info" ]; then
        return $exit;
    fi;
    local short_sha;
    if [ "$rev_parse_exit_code" = "0" ]; then
        short_sha="${repo_info##*
}";
        repo_info="${repo_info%
*}";
    fi;
    local inside_worktree="${repo_info##*
}";
    repo_info="${repo_info%
*}";
    local bare_repo="${repo_info##*
}";
    repo_info="${repo_info%
*}";
    local inside_gitdir="${repo_info##*
}";
    local g="${repo_info%
*}";
    if [ "true" = "$inside_worktree" ] && [ -n "${GIT_PS1_HIDE_IF_PWD_IGNORED-}" ] && [ "$(git config --bool bash.hideIfPwdIgnored)" != "false" ] && git check-ignore -q .; then
        return $exit;
    fi;
    local r="";
    local b="";
    local step="";
    local total="";
    if [ -d "$g/rebase-merge" ]; then
        __git_eread "$g/rebase-merge/head-name" b;
        __git_eread "$g/rebase-merge/msgnum" step;
        __git_eread "$g/rebase-merge/end" total;
        if [ -f "$g/rebase-merge/interactive" ]; then
            r="|REBASE-i";
        else
            r="|REBASE-m";
        fi;
    else
        if [ -d "$g/rebase-apply" ]; then
            __git_eread "$g/rebase-apply/next" step;
            __git_eread "$g/rebase-apply/last" total;
            if [ -f "$g/rebase-apply/rebasing" ]; then
                __git_eread "$g/rebase-apply/head-name" b;
                r="|REBASE";
            else
                if [ -f "$g/rebase-apply/applying" ]; then
                    r="|AM";
                else
                    r="|AM/REBASE";
                fi;
            fi;
        else
            if [ -f "$g/MERGE_HEAD" ]; then
                r="|MERGING";
            else
                if [ -f "$g/CHERRY_PICK_HEAD" ]; then
                    r="|CHERRY-PICKING";
                else
                    if [ -f "$g/REVERT_HEAD" ]; then
                        r="|REVERTING";
                    else
                        if [ -f "$g/BISECT_LOG" ]; then
                            r="|BISECTING";
                        fi;
                    fi;
                fi;
            fi;
        fi;
        if [ -n "$b" ]; then
            :;
        else
            if [ -h "$g/HEAD" ]; then
                b="$(git symbolic-ref HEAD 2>/dev/null)";
            else
                local head="";
                if ! __git_eread "$g/HEAD" head; then
                    return $exit;
                fi;
                b="${head#ref: }";
                if [ "$head" = "$b" ]; then
                    detached=yes;
                    b="$(
				case "${GIT_PS1_DESCRIBE_STYLE-}" in
				(contains)
					git describe --contains HEAD ;;
				(branch)
					git describe --contains --all HEAD ;;
				(describe)
					git describe HEAD ;;
				(* | default)
					git describe --tags --exact-match HEAD ;;
				esac 2>/dev/null)" || b="$short_sha...";
                    b="($b)";
                fi;
            fi;
        fi;
    fi;
    if [ -n "$step" ] && [ -n "$total" ]; then
        r="$r $step/$total";
    fi;
    local w="";
    local i="";
    local s="";
    local u="";
    local c="";
    local p="";
    if [ "true" = "$inside_gitdir" ]; then
        if [ "true" = "$bare_repo" ]; then
            c="BARE:";
        else
            b="GIT_DIR!";
        fi;
    else
        if [ "true" = "$inside_worktree" ]; then
            if [ -n "${GIT_PS1_SHOWDIRTYSTATE-}" ] && [ "$(git config --bool bash.showDirtyState)" != "false" ]; then
                git diff --no-ext-diff --quiet || w="*";
                git diff --no-ext-diff --cached --quiet || i="+";
                if [ -z "$short_sha" ] && [ -z "$i" ]; then
                    i="#";
                fi;
            fi;
            if [ -n "${GIT_PS1_SHOWSTASHSTATE-}" ] && git rev-parse --verify --quiet refs/stash > /dev/null; then
                s="$";
            fi;
            if [ -n "${GIT_PS1_SHOWUNTRACKEDFILES-}" ] && [ "$(git config --bool bash.showUntrackedFiles)" != "false" ] && git ls-files --others --exclude-standard --directory --no-empty-directory --error-unmatch -- ':/*' > /dev/null 2> /dev/null; then
                u="%${ZSH_VERSION+%}";
            fi;
            if [ -n "${GIT_PS1_SHOWUPSTREAM-}" ]; then
                __git_ps1_show_upstream;
            fi;
        fi;
    fi;
    local z="${GIT_PS1_STATESEPARATOR-" "}";
    if [ $pcmode = yes ] && [ -n "${GIT_PS1_SHOWCOLORHINTS-}" ]; then
        __git_ps1_colorize_gitstring;
    fi;
    b=${b##refs/heads/};
    if [ $pcmode = yes ] && [ $ps1_expanded = yes ]; then
        __git_ps1_branch_name=$b;
        b="\${__git_ps1_branch_name}";
    fi;
    local f="$w$i$s$u";
    local gitstring="$c$b${f:+$z$f}$r$p";
    if [ $pcmode = yes ]; then
        if [ "${__git_printf_supports_v-}" != yes ]; then
            gitstring=$(printf -- "$printf_format" "$gitstring");
        else
            printf -v gitstring -- "$printf_format" "$gitstring";
        fi;
        PS1="$ps1pc_start$gitstring$ps1pc_end";
    else
        printf -- "$printf_format" "$gitstring";
    fi;
    return $exit
}
__git_ps1_colorize_gitstring ()
{
    if [[ -n ${ZSH_VERSION-} ]]; then
        local c_red='%F{red}';
        local c_green='%F{green}';
        local c_lblue='%F{blue}';
        local c_clear='%f';
    else
        local c_red='\[\e[31m\]';
        local c_green='\[\e[32m\]';
        local c_lblue='\[\e[1;34m\]';
        local c_clear='\[\e[0m\]';
    fi;
    local bad_color=$c_red;
    local ok_color=$c_green;
    local flags_color="$c_lblue";
    local branch_color="";
    if [ $detached = no ]; then
        branch_color="$ok_color";
    else
        branch_color="$bad_color";
    fi;
    c="$branch_color$c";
    z="$c_clear$z";
    if [ "$w" = "*" ]; then
        w="$bad_color$w";
    fi;
    if [ -n "$i" ]; then
        i="$ok_color$i";
    fi;
    if [ -n "$s" ]; then
        s="$flags_color$s";
    fi;
    if [ -n "$u" ]; then
        u="$bad_color$u";
    fi;
    r="$c_clear$r"
}
__git_ps1_show_upstream ()
{
    local key value;
    local svn_remote svn_url_pattern count n;
    local upstream=git legacy="" verbose="" name="";
    svn_remote=();
    local output="$(git config -z --get-regexp '^(svn-remote\..*\.url|bash\.showupstream)$' 2>/dev/null | tr '\0\n' '\n ')";
    while read -r key value; do
        case "$key" in
            bash.showupstream)
                GIT_PS1_SHOWUPSTREAM="$value";
                if [[ -z "${GIT_PS1_SHOWUPSTREAM}" ]]; then
                    p="";
                    return;
                fi
            ;;
            svn-remote.*.url)
                svn_remote[$((${#svn_remote[@]} + 1))]="$value";
                svn_url_pattern="$svn_url_pattern\\|$value";
                upstream=svn+git
            ;;
        esac;
    done <<< "$output";
    for option in ${GIT_PS1_SHOWUPSTREAM};
    do
        case "$option" in
            git | svn)
                upstream="$option"
            ;;
            verbose)
                verbose=1
            ;;
            legacy)
                legacy=1
            ;;
            name)
                name=1
            ;;
        esac;
    done;
    case "$upstream" in
        git)
            upstream="@{upstream}"
        ;;
        svn*)
            local -a svn_upstream;
            svn_upstream=($(git log --first-parent -1 					--grep="^git-svn-id: \(${svn_url_pattern#??}\)" 2>/dev/null));
            if [[ 0 -ne ${#svn_upstream[@]} ]]; then
                svn_upstream=${svn_upstream[${#svn_upstream[@]} - 2]};
                svn_upstream=${svn_upstream%@*};
                local n_stop="${#svn_remote[@]}";
                for ((n=1; n <= n_stop; n++))
                do
                    svn_upstream=${svn_upstream#${svn_remote[$n]}};
                done;
                if [[ -z "$svn_upstream" ]]; then
                    upstream=${GIT_SVN_ID:-git-svn};
                else
                    upstream=${svn_upstream#/};
                fi;
            else
                if [[ "svn+git" = "$upstream" ]]; then
                    upstream="@{upstream}";
                fi;
            fi
        ;;
    esac;
    if [[ -z "$legacy" ]]; then
        count="$(git rev-list --count --left-right 				"$upstream"...HEAD 2>/dev/null)";
    else
        local commits;
        if commits="$(git rev-list --left-right "$upstream"...HEAD 2>/dev/null)"; then
            local commit behind=0 ahead=0;
            for commit in $commits;
            do
                case "$commit" in
                    "<"*)
                        ((behind++))
                    ;;
                    *)
                        ((ahead++))
                    ;;
                esac;
            done;
            count="$behind	$ahead";
        else
            count="";
        fi;
    fi;
    if [[ -z "$verbose" ]]; then
        case "$count" in
            "")
                p=""
            ;;
            "0	0")
                p="="
            ;;
            "0	"*)
                p=">"
            ;;
            *"	0")
                p="<"
            ;;
            *)
                p="<>"
            ;;
        esac;
    else
        case "$count" in
            "")
                p=""
            ;;
            "0	0")
                p=" u="
            ;;
            "0	"*)
                p=" u+${count#0	}"
            ;;
            *"	0")
                p=" u-${count%	0}"
            ;;
            *)
                p=" u+${count#*	}-${count%	*}"
            ;;
        esac;
        if [[ -n "$count" && -n "$name" ]]; then
            __git_ps1_upstream_name=$(git rev-parse 				--abbrev-ref "$upstream" 2>/dev/null);
            if [ $pcmode = yes ] && [ $ps1_expanded = yes ]; then
                p="$p \${__git_ps1_upstream_name}";
            else
                p="$p ${__git_ps1_upstream_name}";
                unset __git_ps1_upstream_name;
            fi;
        fi;
    fi
}
__ltrim_colon_completions ()
{
    if [[ "$1" == *:* && "$COMP_WORDBREAKS" == *:* ]]; then
        local colon_word=${1%"${1##*:}"};
        local i=${#COMPREPLY[*]};
        while [[ $((--i)) -ge 0 ]]; do
            COMPREPLY[$i]=${COMPREPLY[$i]#"$colon_word"};
        done;
    fi
}
__parse_options ()
{
    local option option2 i IFS='
,/|';
    option=;
    for i in $1;
    do
        case $i in
            ---*)
                break
            ;;
            --?*)
                option=$i;
                break
            ;;
            -?*)
                [[ -n $option ]] || option=$i
            ;;
            *)
                break
            ;;
        esac;
    done;
    [[ -n $option ]] || return 0;
    IFS='
';
    if [[ $option =~ (\[((no|dont)-?)\]). ]]; then
        option2=${option/"${BASH_REMATCH[1]}"/};
        option2=${option2%%[<{().[]*};
        printf '%s\n' "${option2/=*/=}";
        option=${option/"${BASH_REMATCH[1]}"/"${BASH_REMATCH[2]}"};
    fi;
    option=${option%%[<{().[]*};
    printf '%s\n' "${option/=*/=}"
}
__reassemble_comp_words_by_ref ()
{
    local exclude i j line ref;
    if [[ -n $1 ]]; then
        exclude="${1//[^$COMP_WORDBREAKS]}";
    fi;
    eval $3=$COMP_CWORD;
    if [[ -n $exclude ]]; then
        line=$COMP_LINE;
        for ((i=0, j=0; i < ${#COMP_WORDS[@]}; i++, j++))
        do
            while [[ $i -gt 0 && ${COMP_WORDS[$i]} == +([$exclude]) ]]; do
                [[ $line != [' 	']* ]] && (( j >= 2 )) && ((j--));
                ref="$2[$j]";
                eval $2[$j]=\${!ref}\${COMP_WORDS[i]};
                [[ $i == $COMP_CWORD ]] && eval $3=$j;
                line=${line#*"${COMP_WORDS[$i]}"};
                [[ $line == [' 	']* ]] && ((j++));
                (( $i < ${#COMP_WORDS[@]} - 1)) && ((i++)) || break 2;
            done;
            ref="$2[$j]";
            eval $2[$j]=\${!ref}\${COMP_WORDS[i]};
            line=${line#*"${COMP_WORDS[i]}"};
            [[ $i == $COMP_CWORD ]] && eval $3=$j;
        done;
        [[ $i == $COMP_CWORD ]] && eval $3=$j;
    else
        eval $2=\( \"\${COMP_WORDS[@]}\" \);
    fi
}
_allowed_groups ()
{
    if _complete_as_root; then
        local IFS='
';
        COMPREPLY=($( compgen -g -- "$1" ));
    else
        local IFS='
 ';
        COMPREPLY=($( compgen -W             "$( id -Gn 2>/dev/null || groups 2>/dev/null )" -- "$1" ));
    fi
}
_allowed_users ()
{
    if _complete_as_root; then
        local IFS='
';
        COMPREPLY=($( compgen -u -- "${1:-$cur}" ));
    else
        local IFS='
 ';
        COMPREPLY=($( compgen -W             "$( id -un 2>/dev/null || whoami 2>/dev/null )" -- "${1:-$cur}" ));
    fi
}
_apport-bug ()
{
    local cur dashoptions prev param;
    COMPREPLY=();
    cur=`_get_cword`;
    prev=${COMP_WORDS[COMP_CWORD-1]};
    dashoptions='-h --help --save -v --version --tag -w --window';
    case "$prev" in
        ubuntu-bug | apport-bug)
            case "$cur" in
                -*)
                    COMPREPLY=($( compgen -W "$dashoptions" -- $cur ))
                ;;
                *)
                    _apport_parameterless
                ;;
            esac
        ;;
        --save)
            COMPREPLY=($( compgen -o default -G "$cur*" ))
        ;;
        -w | --window)
            dashoptions="--save --tag";
            COMPREPLY=($( compgen -W "$dashoptions" -- $cur ))
        ;;
        -h | --help | -v | --version | --tag)
            return 0
        ;;
        *)
            dashoptions="--tag";
            if ! [[ "${COMP_WORDS[*]}" =~ .*--save.* ]]; then
                dashoptions="--save $dashoptions";
            fi;
            if ! [[ "${COMP_WORDS[*]}" =~ .*--window.* || "${COMP_WORDS[*]}" =~ .*\ -w\ .* ]]; then
                dashoptions="-w --window $dashoptions";
            fi;
            case "$cur" in
                -*)
                    COMPREPLY=($( compgen -W "$dashoptions" -- $cur ))
                ;;
                *)
                    _apport_parameterless
                ;;
            esac
        ;;
    esac
}
_apport-cli ()
{
    local cur dashoptions prev param;
    COMPREPLY=();
    cur=`_get_cword`;
    prev=${COMP_WORDS[COMP_CWORD-1]};
    dashoptions='-h --help -f --file-bug -u --update-bug -s --symptom \
                 -c --crash-file --save -v --version --tag -w --window';
    case "$prev" in
        apport-cli)
            case "$cur" in
                -*)
                    COMPREPLY=($( compgen -W "$dashoptions" -- $cur ))
                ;;
                *)
                    _apport_parameterless
                ;;
            esac
        ;;
        -f | --file-bug)
            param="-P --pid -p --package -s --symptom";
            COMPREPLY=($( compgen -W "$param $(_apport_symptoms)" -- $cur))
        ;;
        -s | --symptom)
            COMPREPLY=($( compgen -W "$(_apport_symptoms)" -- $cur))
        ;;
        --save)
            COMPREPLY=($( compgen -o default -G "$cur*" ))
        ;;
        -c | --crash-file)
            COMPREPLY=($( compgen -G "${cur}*.apport"
                       compgen -G "${cur}*.crash" ))
        ;;
        -w | --window)
            dashoptions="--save --tag";
            COMPREPLY=($( compgen -W "$dashoptions" -- $cur ))
        ;;
        -h | --help | -v | --version | --tag)
            return 0
        ;;
        *)
            dashoptions='--tag';
            if ! [[ "${COMP_WORDS[*]}" =~ .*--save.* ]]; then
                dashoptions="--save $dashoptions";
            fi;
            if ! [[ "${COMP_WORDS[*]}" =~ .*--window.* || "${COMP_WORDS[*]}" =~ .*\ -w\ .* ]]; then
                dashoptions="-w --window $dashoptions";
            fi;
            if ! [[ "${COMP_WORDS[*]}" =~ .*--symptom.* || "${COMP_WORDS[*]}" =~ .*\ -s\ .* ]]; then
                dashoptions="-s --symptom $dashoptions";
            fi;
            if ! [[ "${COMP_WORDS[*]}" =~ .*--update.* || "${COMP_WORDS[*]}" =~ .*\ -u\ .* ]]; then
                dashoptions="-u --update $dashoptions";
            fi;
            if ! [[ "${COMP_WORDS[*]}" =~ .*--file-bug.* || "${COMP_WORDS[*]}" =~ .*\ -f\ .* ]]; then
                dashoptions="-f --file-bug $dashoptions";
            fi;
            if ! [[ "${COMP_WORDS[*]}" =~ .*--crash-file.* || "${COMP_WORDS[*]}" =~ .*\ -c\ .* ]]; then
                dashoptions="-c --crash-file $dashoptions";
            fi;
            case "$cur" in
                -*)
                    COMPREPLY=($( compgen -W "$dashoptions" -- $cur ))
                ;;
                *)
                    _apport_parameterless
                ;;
            esac
        ;;
    esac
}
_apport-collect ()
{
    local cur prev;
    COMPREPLY=();
    cur=`_get_cword`;
    prev=${COMP_WORDS[COMP_CWORD-1]};
    case "$prev" in
        apport-collect)
            COMPREPLY=($( compgen -W "-p --package --tag" -- $cur))
        ;;
        -p | --package)
            COMPREPLY=($( apt-cache pkgnames $cur 2> /dev/null ))
        ;;
        --tag)
            return 0
        ;;
        *)
            if [[ "${COMP_WORDS[*]}" =~ .*\ -p.* || "${COMP_WORDS[*]}" =~ .*--package.* ]]; then
                COMPREPLY=($( compgen -W "--tag" -- $cur));
            else
                COMPREPLY=($( compgen -W "-p --package --tag" -- $cur));
            fi
        ;;
    esac
}
_apport-unpack ()
{
    local cur prev;
    COMPREPLY=();
    cur=`_get_cword`;
    prev=${COMP_WORDS[COMP_CWORD-1]};
    case "$prev" in
        apport-unpack)
            COMPREPLY=($( compgen -G "${cur}*.apport"
                       compgen -G "${cur}*.crash" ))
        ;;
    esac
}
_apport_parameterless ()
{
    local param;
    param="$dashoptions            $( apt-cache pkgnames $cur 2> /dev/null )            $( command ps axo pid | sed 1d )            $( _apport_symptoms )            $( compgen -G "${cur}*" )";
    COMPREPLY=($( compgen -W "$param" -- $cur))
}
_apport_symptoms ()
{
    local syms;
    if [ -r /usr/share/apport/symptoms ]; then
        for FILE in $(ls /usr/share/apport/symptoms);
        do
            if [[ ! "$FILE" =~ ^_.* && -n $(egrep "^def run\s*\(.*\):" /usr/share/apport/symptoms/$FILE) ]]; then
                syms="$syms ${FILE%.py}";
            fi;
        done;
    fi;
    echo $syms
}
_available_interfaces ()
{
    local cmd PATH=$PATH:/sbin;
    if [[ ${1:-} == -w ]]; then
        cmd="iwconfig";
    else
        if [[ ${1:-} == -a ]]; then
            cmd="{ ifconfig || ip link show up; }";
        else
            cmd="{ ifconfig -a || ip link show; }";
        fi;
    fi;
    COMPREPLY=($( eval $cmd 2>/dev/null | awk         '/^[^ \t]/ { if ($1 ~ /^[0-9]+:/) { print $2 } else { print $1 } }' ));
    COMPREPLY=($( compgen -W '${COMPREPLY[@]/%[[:punct:]]/}' -- "$cur" ))
}
_cd ()
{
    local cur prev words cword;
    _init_completion || return;
    local IFS='
' i j k;
    compopt -o filenames;
    if [[ -z "${CDPATH:-}" || "$cur" == ?(.)?(.)/* ]]; then
        _filedir -d;
        return 0;
    fi;
    local -r mark_dirs=$(_rl_enabled mark-directories && echo y);
    local -r mark_symdirs=$(_rl_enabled mark-symlinked-directories && echo y);
    for i in ${CDPATH//:/'
'};
    do
        k="${#COMPREPLY[@]}";
        for j in $( compgen -d $i/$cur );
        do
            if [[ ( -n $mark_symdirs && -h $j || -n $mark_dirs && ! -h $j ) && ! -d ${j#$i/} ]]; then
                j+="/";
            fi;
            COMPREPLY[k++]=${j#$i/};
        done;
    done;
    _filedir -d;
    if [[ ${#COMPREPLY[@]} -eq 1 ]]; then
        i=${COMPREPLY[0]};
        if [[ "$i" == "$cur" && $i != "*/" ]]; then
            COMPREPLY[0]="${i}/";
        fi;
    fi;
    return 0
}
_cd_devices ()
{
    COMPREPLY+=($( compgen -f -d -X "!*/?([amrs])cd*" -- "${cur:-/dev/}" ))
}
_command ()
{
    local offset i;
    offset=1;
    for ((i=1; i <= COMP_CWORD; i++ ))
    do
        if [[ "${COMP_WORDS[i]}" != -* ]]; then
            offset=$i;
            break;
        fi;
    done;
    _command_offset $offset
}
_command_offset ()
{
    local word_offset=$1 i j;
    for ((i=0; i < $word_offset; i++ ))
    do
        for ((j=0; j <= ${#COMP_LINE}; j++ ))
        do
            [[ "$COMP_LINE" == "${COMP_WORDS[i]}"* ]] && break;
            COMP_LINE=${COMP_LINE:1};
            ((COMP_POINT--));
        done;
        COMP_LINE=${COMP_LINE#"${COMP_WORDS[i]}"};
        ((COMP_POINT-=${#COMP_WORDS[i]}));
    done;
    for ((i=0; i <= COMP_CWORD - $word_offset; i++ ))
    do
        COMP_WORDS[i]=${COMP_WORDS[i+$word_offset]};
    done;
    for ((i; i <= COMP_CWORD; i++ ))
    do
        unset COMP_WORDS[i];
    done;
    ((COMP_CWORD -= $word_offset));
    COMPREPLY=();
    local cur;
    _get_comp_words_by_ref cur;
    if [[ $COMP_CWORD -eq 0 ]]; then
        local IFS='
';
        compopt -o filenames;
        COMPREPLY=($( compgen -d -c -- "$cur" ));
    else
        local cmd=${COMP_WORDS[0]} compcmd=${COMP_WORDS[0]};
        local cspec=$( complete -p $cmd 2>/dev/null );
        if [[ ! -n $cspec && $cmd == */* ]]; then
            cspec=$( complete -p ${cmd##*/} 2>/dev/null );
            [[ -n $cspec ]] && compcmd=${cmd##*/};
        fi;
        if [[ ! -n $cspec ]]; then
            compcmd=${cmd##*/};
            _completion_loader $compcmd;
            cspec=$( complete -p $compcmd 2>/dev/null );
        fi;
        if [[ -n $cspec ]]; then
            if [[ ${cspec#* -F } != $cspec ]]; then
                local func=${cspec#*-F };
                func=${func%% *};
                if [[ ${#COMP_WORDS[@]} -ge 2 ]]; then
                    $func $cmd "${COMP_WORDS[${#COMP_WORDS[@]}-1]}" "${COMP_WORDS[${#COMP_WORDS[@]}-2]}";
                else
                    $func $cmd "${COMP_WORDS[${#COMP_WORDS[@]}-1]}";
                fi;
                local opt;
                while [[ $cspec == *" -o "* ]]; do
                    cspec=${cspec#*-o };
                    opt=${cspec%% *};
                    compopt -o $opt;
                    cspec=${cspec#$opt};
                done;
            else
                cspec=${cspec#complete};
                cspec=${cspec%%$compcmd};
                COMPREPLY=($( eval compgen "$cspec" -- '$cur' ));
            fi;
        else
            if [[ ${#COMPREPLY[@]} -eq 0 ]]; then
                _minimal;
            fi;
        fi;
    fi
}
_complete_as_root ()
{
    [[ $EUID -eq 0 || -n ${root_command:-} ]]
}
_completion_loader ()
{
    local compfile=./completions;
    [[ $BASH_SOURCE == */* ]] && compfile="${BASH_SOURCE%/*}/completions";
    compfile+="/${1##*/}";
    [[ -f "$compfile" ]] && . "$compfile" &> /dev/null && return 124;
    complete -F _minimal "$1" && return 124
}
_configured_interfaces ()
{
    if [[ -f /etc/debian_version ]]; then
        COMPREPLY=($( compgen -W "$( sed -ne 's|^iface \([^ ]\{1,\}\).*$|\1|p'            /etc/network/interfaces )" -- "$cur" ));
    else
        if [[ -f /etc/SuSE-release ]]; then
            COMPREPLY=($( compgen -W "$( printf '%s\n'             /etc/sysconfig/network/ifcfg-* |             sed -ne 's|.*ifcfg-\(.*\)|\1|p' )" -- "$cur" ));
        else
            if [[ -f /etc/pld-release ]]; then
                COMPREPLY=($( compgen -W "$( command ls -B             /etc/sysconfig/interfaces |             sed -ne 's|.*ifcfg-\(.*\)|\1|p' )" -- "$cur" ));
            else
                COMPREPLY=($( compgen -W "$( printf '%s\n'             /etc/sysconfig/network-scripts/ifcfg-* |             sed -ne 's|.*ifcfg-\(.*\)|\1|p' )" -- "$cur" ));
            fi;
        fi;
    fi
}
_count_args ()
{
    local i cword words;
    __reassemble_comp_words_by_ref "$1" words cword;
    args=1;
    for i in "${words[@]:1:cword-1}";
    do
        [[ "$i" != -* ]] && args=$(($args+1));
    done
}
_cryptdisks ()
{
    local tf;
    tf=${TABFILE-"/etc/crypttab"};
    COMPREPLY=($(egrep -v "^[[:space:]]*(#|$)" "${tf}" | egrep -o "^${COMP_WORDS[COMP_CWORD]}[^[:space:]]*"));
    return 0
}
_desktop_file_validate ()
{
    COMPRELY=();
    cur=${COMP_WORDS[COMP_CWORD]};
    _filedir '@(desktop)'
}
_dvd_devices ()
{
    COMPREPLY+=($( compgen -f -d -X "!*/?(r)dvd*" -- "${cur:-/dev/}" ))
}
_expand ()
{
    if [[ "$cur" == \~*/* ]]; then
        eval cur=$cur 2> /dev/null;
    else
        if [[ "$cur" == \~* ]]; then
            cur=${cur#\~};
            COMPREPLY=($( compgen -P '~' -u "$cur" ));
            [[ ${#COMPREPLY[@]} -eq 1 ]] && eval COMPREPLY[0]=${COMPREPLY[0]};
            return ${#COMPREPLY[@]};
        fi;
    fi
}
_filedir ()
{
    local i IFS='
' xspec;
    _tilde "$cur" || return 0;
    local -a toks;
    local quoted x tmp;
    _quote_readline_by_ref "$cur" quoted;
    x=$( compgen -d -- "$quoted" ) && while read -r tmp; do
        toks+=("$tmp");
    done <<< "$x";
    if [[ "$1" != -d ]]; then
        xspec=${1:+"!*.@($1|${1^^})"};
        x=$( compgen -f -X "$xspec" -- $quoted ) && while read -r tmp; do
            toks+=("$tmp");
        done <<< "$x";
    fi;
    [[ -n ${COMP_FILEDIR_FALLBACK:-} && -n "$1" && "$1" != -d && ${#toks[@]} -lt 1 ]] && x=$( compgen -f -- $quoted ) && while read -r tmp; do
        toks+=("$tmp");
    done <<< "$x";
    if [[ ${#toks[@]} -ne 0 ]]; then
        compopt -o filenames 2> /dev/null;
        COMPREPLY+=("${toks[@]}");
    fi
}
_filedir_xspec ()
{
    local cur prev words cword;
    _init_completion || return;
    _tilde "$cur" || return 0;
    local IFS='
' xspec=${_xspecs[${1##*/}]} tmp;
    local -a toks;
    toks=($(
        compgen -d -- "$(quote_readline "$cur")" | {
        while read -r tmp; do
            printf '%s\n' $tmp
        done
        }
        ));
    eval xspec="${xspec}";
    local matchop=!;
    if [[ $xspec == !* ]]; then
        xspec=${xspec#!};
        matchop=@;
    fi;
    xspec="$matchop($xspec|${xspec^^})";
    toks+=($(
        eval compgen -f -X "!$xspec" -- "\$(quote_readline "\$cur")" | {
        while read -r tmp; do
            [[ -n $tmp ]] && printf '%s\n' $tmp
        done
        }
        ));
    if [[ ${#toks[@]} -ne 0 ]]; then
        compopt -o filenames;
        COMPREPLY=("${toks[@]}");
    fi
}
_fstypes ()
{
    local fss;
    if [[ -e /proc/filesystems ]]; then
        fss="$( cut -d'	' -f2 /proc/filesystems )
             $( awk '! /\*/ { print $NF }' /etc/filesystems 2>/dev/null )";
    else
        fss="$( awk '/^[ \t]*[^#]/ { print $3 }' /etc/fstab 2>/dev/null )
             $( awk '/^[ \t]*[^#]/ { print $3 }' /etc/mnttab 2>/dev/null )
             $( awk '/^[ \t]*[^#]/ { print $4 }' /etc/vfstab 2>/dev/null )
             $( awk '{ print $1 }' /etc/dfs/fstypes 2>/dev/null )
             $( [[ -d /etc/fs ]] && command ls /etc/fs )";
    fi;
    [[ -n $fss ]] && COMPREPLY+=($( compgen -W "$fss" -- "$cur" ))
}
_function ()
{
    local cur prev words cword;
    _init_completion || return;
    if [[ $1 == @(declare|typeset) ]]; then
        if [[ $prev == -f ]]; then
            COMPREPLY=($( compgen -A function -- "$cur" ));
        else
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($( compgen -W '$( _parse_usage "$1" )' -- "$cur" ));
            fi;
        fi;
    else
        if [[ $cword -eq 1 ]]; then
            COMPREPLY=($( compgen -A function -- "$cur" ));
        else
            COMPREPLY=("() $( type -- ${words[1]} | sed -e 1,2d )");
        fi;
    fi
}
_get_comp_words_by_ref ()
{
    local exclude flag i OPTIND=1;
    local cur cword words=();
    local upargs=() upvars=() vcur vcword vprev vwords;
    while getopts "c:i:n:p:w:" flag "$@"; do
        case $flag in
            c)
                vcur=$OPTARG
            ;;
            i)
                vcword=$OPTARG
            ;;
            n)
                exclude=$OPTARG
            ;;
            p)
                vprev=$OPTARG
            ;;
            w)
                vwords=$OPTARG
            ;;
        esac;
    done;
    while [[ $# -ge $OPTIND ]]; do
        case ${!OPTIND} in
            cur)
                vcur=cur
            ;;
            prev)
                vprev=prev
            ;;
            cword)
                vcword=cword
            ;;
            words)
                vwords=words
            ;;
            *)
                echo "bash: $FUNCNAME(): \`${!OPTIND}': unknown argument" 1>&2;
                return 1
            ;;
        esac;
        let "OPTIND += 1";
    done;
    __get_cword_at_cursor_by_ref "$exclude" words cword cur;
    [[ -n $vcur ]] && {
        upvars+=("$vcur");
        upargs+=(-v $vcur "$cur")
    };
    [[ -n $vcword ]] && {
        upvars+=("$vcword");
        upargs+=(-v $vcword "$cword")
    };
    [[ -n $vprev && $cword -ge 1 ]] && {
        upvars+=("$vprev");
        upargs+=(-v $vprev "${words[cword - 1]}")
    };
    [[ -n $vwords ]] && {
        upvars+=("$vwords");
        upargs+=(-a${#words[@]} $vwords "${words[@]}")
    };
    (( ${#upvars[@]} )) && local "${upvars[@]}" && _upvars "${upargs[@]}"
}
_get_cword ()
{
    local LC_CTYPE=C;
    local cword words;
    __reassemble_comp_words_by_ref "$1" words cword;
    if [[ -n ${2//[^0-9]/} ]]; then
        printf "%s" "${words[cword-$2]}";
    else
        if [[ "${#words[cword]}" -eq 0 || "$COMP_POINT" == "${#COMP_LINE}" ]]; then
            printf "%s" "${words[cword]}";
        else
            local i;
            local cur="$COMP_LINE";
            local index="$COMP_POINT";
            for ((i = 0; i <= cword; ++i ))
            do
                while [[ "${#cur}" -ge ${#words[i]} && "${cur:0:${#words[i]}}" != "${words[i]}" ]]; do
                    cur="${cur:1}";
                    ((index--));
                done;
                if [[ "$i" -lt "$cword" ]]; then
                    local old_size="${#cur}";
                    cur="${cur#${words[i]}}";
                    local new_size="${#cur}";
                    index=$(( index - old_size + new_size ));
                fi;
            done;
            if [[ "${words[cword]:0:${#cur}}" != "$cur" ]]; then
                printf "%s" "${words[cword]}";
            else
                printf "%s" "${cur:0:$index}";
            fi;
        fi;
    fi
}
_get_first_arg ()
{
    local i;
    arg=;
    for ((i=1; i < COMP_CWORD; i++ ))
    do
        if [[ "${COMP_WORDS[i]}" != -* ]]; then
            arg=${COMP_WORDS[i]};
            break;
        fi;
    done
}
_get_pword ()
{
    if [[ $COMP_CWORD -ge 1 ]]; then
        _get_cword "${@:-}" 1;
    fi
}
_gids ()
{
    if type getent &> /dev/null; then
        COMPREPLY=($( compgen -W '$( getent group | cut -d: -f3 )'             -- "$cur" ));
    else
        if type perl &> /dev/null; then
            COMPREPLY=($( compgen -W '$( perl -e '"'"'while (($gid) = (getgrent)[2]) { print $gid . "\n" }'"'"' )' -- "$cur" ));
        else
            COMPREPLY=($( compgen -W '$( cut -d: -f3 /etc/group )' -- "$cur" ));
        fi;
    fi
}
_have ()
{
    PATH=$PATH:/usr/sbin:/sbin:/usr/local/sbin type $1 &> /dev/null
}
_init_completion ()
{
    local exclude= flag outx errx inx OPTIND=1;
    while getopts "n:e:o:i:s" flag "$@"; do
        case $flag in
            n)
                exclude+=$OPTARG
            ;;
            e)
                errx=$OPTARG
            ;;
            o)
                outx=$OPTARG
            ;;
            i)
                inx=$OPTARG
            ;;
            s)
                split=false;
                exclude+==
            ;;
        esac;
    done;
    COMPREPLY=();
    local redir="@(?([0-9])<|?([0-9&])>?(>)|>&)";
    _get_comp_words_by_ref -n "$exclude<>&" cur prev words cword;
    _variables && return 1;
    if [[ $cur == $redir* || $prev == $redir ]]; then
        local xspec;
        case $cur in
            2'>'*)
                xspec=$errx
            ;;
            *'>'*)
                xspec=$outx
            ;;
            *'<'*)
                xspec=$inx
            ;;
            *)
                case $prev in
                    2'>'*)
                        xspec=$errx
                    ;;
                    *'>'*)
                        xspec=$outx
                    ;;
                    *'<'*)
                        xspec=$inx
                    ;;
                esac
            ;;
        esac;
        cur="${cur##$redir}";
        _filedir $xspec;
        return 1;
    fi;
    local i skip;
    for ((i=1; i < ${#words[@]}; 1))
    do
        if [[ ${words[i]} == $redir* ]]; then
            [[ ${words[i]} == $redir ]] && skip=2 || skip=1;
            words=("${words[@]:0:i}" "${words[@]:i+skip}");
            [[ $i -le $cword ]] && cword=$(( cword - skip ));
        else
            i=$(( ++i ));
        fi;
    done;
    [[ $cword -le 0 ]] && return 1;
    prev=${words[cword-1]};
    [[ -n ${split-} ]] && _split_longopt && split=true;
    return 0
}
_installed_modules ()
{
    COMPREPLY=($( compgen -W "$( PATH="$PATH:/sbin" lsmod |         awk '{if (NR != 1) print $1}' )" -- "$1" ))
}
_ip_addresses ()
{
    local PATH=$PATH:/sbin;
    COMPREPLY+=($( compgen -W         "$( { LC_ALL=C ifconfig -a || ip addr show; } 2>/dev/null |
            sed -ne 's/.*addr:\([^[:space:]]*\).*/\1/p'                 -ne 's|.*inet[[:space:]]\{1,\}\([^[:space:]/]*\).*|\1|p' )"         -- "$cur" ))
}
_kernel_versions ()
{
    COMPREPLY=($( compgen -W '$( command ls /lib/modules )' -- "$cur" ))
}
_known_hosts ()
{
    local cur prev words cword;
    _init_completion -n : || return;
    local options;
    [[ "$1" == -a || "$2" == -a ]] && options=-a;
    [[ "$1" == -c || "$2" == -c ]] && options+=" -c";
    _known_hosts_real $options -- "$cur"
}
_known_hosts_real ()
{
    local configfile flag prefix;
    local cur curd awkcur user suffix aliases i host;
    local -a kh khd config;
    local OPTIND=1;
    while getopts "acF:p:" flag "$@"; do
        case $flag in
            a)
                aliases='yes'
            ;;
            c)
                suffix=':'
            ;;
            F)
                configfile=$OPTARG
            ;;
            p)
                prefix=$OPTARG
            ;;
        esac;
    done;
    [[ $# -lt $OPTIND ]] && echo "error: $FUNCNAME: missing mandatory argument CWORD";
    cur=${!OPTIND};
    let "OPTIND += 1";
    [[ $# -ge $OPTIND ]] && echo "error: $FUNCNAME("$@"): unprocessed arguments:" $(while [[ $# -ge $OPTIND ]]; do printf '%s\n' ${!OPTIND}; shift; done);
    [[ $cur == *@* ]] && user=${cur%@*}@ && cur=${cur#*@};
    kh=();
    if [[ -n $configfile ]]; then
        [[ -r $configfile ]] && config+=("$configfile");
    else
        for i in /etc/ssh/ssh_config ~/.ssh/config ~/.ssh2/config;
        do
            [[ -r $i ]] && config+=("$i");
        done;
    fi;
    if [[ ${#config[@]} -gt 0 ]]; then
        local OIFS=$IFS IFS='
' j;
        local -a tmpkh;
        tmpkh=($( awk 'sub("^[ \t]*([Gg][Ll][Oo][Bb][Aa][Ll]|[Uu][Ss][Ee][Rr])[Kk][Nn][Oo][Ww][Nn][Hh][Oo][Ss][Tt][Ss][Ff][Ii][Ll][Ee][ \t]+", "") { print $0 }' "${config[@]}" | sort -u ));
        IFS=$OIFS;
        for i in "${tmpkh[@]}";
        do
            while [[ $i =~ ^([^\"]*)\"([^\"]*)\"(.*)$ ]]; do
                i=${BASH_REMATCH[1]}${BASH_REMATCH[3]};
                j=${BASH_REMATCH[2]};
                __expand_tilde_by_ref j;
                [[ -r $j ]] && kh+=("$j");
            done;
            for j in $i;
            do
                __expand_tilde_by_ref j;
                [[ -r $j ]] && kh+=("$j");
            done;
        done;
    fi;
    if [[ -z $configfile ]]; then
        for i in /etc/ssh/ssh_known_hosts /etc/ssh/ssh_known_hosts2 /etc/known_hosts /etc/known_hosts2 ~/.ssh/known_hosts ~/.ssh/known_hosts2;
        do
            [[ -r $i ]] && kh+=("$i");
        done;
        for i in /etc/ssh2/knownhosts ~/.ssh2/hostkeys;
        do
            [[ -d $i ]] && khd+=("$i"/*pub);
        done;
    fi;
    if [[ ${#kh[@]} -gt 0 || ${#khd[@]} -gt 0 ]]; then
        awkcur=${cur//\//\\\/};
        awkcur=${awkcur//\./\\\.};
        curd=$awkcur;
        if [[ "$awkcur" == [0-9]*[.:]* ]]; then
            awkcur="^$awkcur[.:]*";
        else
            if [[ "$awkcur" == [0-9]* ]]; then
                awkcur="^$awkcur.*[.:]";
            else
                if [[ -z $awkcur ]]; then
                    awkcur="[a-z.:]";
                else
                    awkcur="^$awkcur";
                fi;
            fi;
        fi;
        if [[ ${#kh[@]} -gt 0 ]]; then
            COMPREPLY+=($( awk 'BEGIN {FS=","}
            /^\s*[^|\#]/ {
            sub("^@[^ ]+ +", ""); \
            sub(" .*$", ""); \
            for (i=1; i<=NF; ++i) { \
            sub("^\\[", "", $i); sub("\\](:[0-9]+)?$", "", $i); \
            if ($i !~ /[*?]/ && $i ~ /'"$awkcur"'/) {print $i} \
            }}' "${kh[@]}" 2>/dev/null ));
        fi;
        if [[ ${#khd[@]} -gt 0 ]]; then
            for i in "${khd[@]}";
            do
                if [[ "$i" == *key_22_$curd*.pub && -r "$i" ]]; then
                    host=${i/#*key_22_/};
                    host=${host/%.pub/};
                    COMPREPLY+=($host);
                fi;
            done;
        fi;
        for ((i=0; i < ${#COMPREPLY[@]}; i++ ))
        do
            COMPREPLY[i]=$prefix$user${COMPREPLY[i]}$suffix;
        done;
    fi;
    if [[ ${#config[@]} -gt 0 && -n "$aliases" ]]; then
        local hosts=$( sed -ne 's/^[ \t]*[Hh][Oo][Ss][Tt]\([Nn][Aa][Mm][Ee]\)\{0,1\}['"$'\t '"']\{1,\}\([^#*?]*\)\(#.*\)\{0,1\}$/\2/p' "${config[@]}" );
        COMPREPLY+=($( compgen -P "$prefix$user"             -S "$suffix" -W "$hosts" -- "$cur" ));
    fi;
    COMPREPLY+=($( compgen -W         "$( ruptime 2>/dev/null | awk '!/^ruptime:/ { print $1 }' )"         -- "$cur" ));
    if [[ -n ${COMP_KNOWN_HOSTS_WITH_HOSTFILE-1} ]]; then
        COMPREPLY+=($( compgen -A hostname -P "$prefix$user" -S "$suffix" -- "$cur" ));
    fi;
    __ltrim_colon_completions "$prefix$user$cur";
    return 0
}
_longopt ()
{
    local cur prev words cword split;
    _init_completion -s || return;
    case "${prev,,}" in
        --help | --usage | --version)
            return 0
        ;;
        --*dir*)
            _filedir -d;
            return 0
        ;;
        --*file* | --*path*)
            _filedir;
            return 0
        ;;
        --+([-a-z0-9_]) )
            local argtype=$( $1 --help 2>&1 | sed -ne                 "s|.*$prev\[\{0,1\}=[<[]\{0,1\}\([-A-Za-z0-9_]\{1,\}\).*|\1|p" );
            case ${argtype,,} in
                *dir*)
                    _filedir -d;
                    return 0
                ;;
                *file* | *path*)
                    _filedir;
                    return 0
                ;;
            esac
        ;;
    esac;
    $split && return 0;
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($( compgen -W "$( $1 --help 2>&1 |             sed -ne 's/.*\(--[-A-Za-z0-9]\{1,\}=\{0,1\}\).*/\1/p' | sort -u )"             -- "$cur" ));
        [[ $COMPREPLY == *= ]] && compopt -o nospace;
    else
        if [[ "$1" == @(mk|rm)dir ]]; then
            _filedir -d;
        else
            _filedir;
        fi;
    fi
}
_mac_addresses ()
{
    local re='\([A-Fa-f0-9]\{2\}:\)\{5\}[A-Fa-f0-9]\{2\}';
    local PATH="$PATH:/sbin:/usr/sbin";
    COMPREPLY+=($(         { LC_ALL=C ifconfig -a || ip link show; } 2>/dev/null | sed -ne         "s/.*[[:space:]]HWaddr[[:space:]]\{1,\}\($re\)[[:space:]].*/\1/p" -ne         "s/.*[[:space:]]HWaddr[[:space:]]\{1,\}\($re\)[[:space:]]*$/\1/p" -ne         "s|.*[[:space:]]\(link/\)\{0,1\}ether[[:space:]]\{1,\}\($re\)[[:space:]].*|\2|p" -ne         "s|.*[[:space:]]\(link/\)\{0,1\}ether[[:space:]]\{1,\}\($re\)[[:space:]]*$|\2|p"
        ));
    COMPREPLY+=($( { arp -an || ip neigh show; } 2>/dev/null | sed -ne         "s/.*[[:space:]]\($re\)[[:space:]].*/\1/p" -ne         "s/.*[[:space:]]\($re\)[[:space:]]*$/\1/p" ));
    COMPREPLY+=($( sed -ne         "s/^[[:space:]]*\($re\)[[:space:]].*/\1/p" /etc/ethers 2>/dev/null ));
    COMPREPLY=($( compgen -W '${COMPREPLY[@]}' -- "$cur" ));
    __ltrim_colon_completions "$cur"
}
_minimal ()
{
    local cur prev words cword split;
    _init_completion -s || return;
    $split && return;
    _filedir
}
_ml ()
{
    local cur="${2}" prev="${3}" cmds opts found;
    COMPREPLY=();
    cmds="add avail delete help keyword list load purge rm restore         save sl show spider swap unload unuse update use whatis";
    opts="-d -D -h -q -t -v -w -s --style --expert --quiet --help         --quiet --terse --version --default --Verbose --width -r --regexp --mt";
    case "${prev}" in
        rm | remove | unload | switch | swap)
            COMPREPLY=($(compgen -W "$(_module_loaded_modules)" -- "${cur}"))
        ;;
        restore)
            COMPREPLY=($(compgen -W "$(_module_savelist)" -- "${cur}"))
        ;;
        spider)
            COMPREPLY=($(compgen -W "$(_module_spider)" -- "${cur}"))
        ;;
        unuse)
            COMPREPLY=($(IFS=: compgen -W "${MODULEPATH}" -- "${cur}"))
        ;;
        use | *-a*)
            _module_dir "${cur}"
        ;;
        help | show | whatis)
            COMPREPLY=($(compgen -W "$(_module_avail)" -- "${cur}"))
        ;;
        *)
            case "${cur}" in
                -*)
                    if [ ${COMP_CWORD} -eq 1 ]; then
                        COMPREPLY=($(compgen -W "${opts} $(_module_loaded_modules_negated)" -- "${cur}"));
                    else
                        COMPREPLY=($(compgen -W "        $(_module_loaded_modules_negated)" -- "${cur}"));
                    fi
                ;;
                *)
                    if [ ${COMP_CWORD} -eq 1 ]; then
                        case "${cur}" in
                            ls)
                                COMPREPLY='list'
                            ;;
                            sw*)
                                COMPREPLY='swap'
                            ;;
                            *)
                                COMPREPLY=($(compgen -W "${cmds} $(_module_avail)" -- "${cur}"))
                            ;;
                        esac;
                    else
                        if [[ ${COMP_WORDS[COMP_CWORD-2]} == sw* ]]; then
                            COMPREPLY=($(compgen -W "$(_module_not_yet_loaded)" -- "${cur}"));
                        else
                            for ((i = COMP_CWORD - 1; i > 0; i--))
                            do
                                case ${COMP_WORDS[$i]} in
                                    show | whatis)
                                        COMPREPLY=($(compgen -W "$(_module_avail)" -- "${cur}"));
                                        found=1;
                                        break
                                    ;;
                                    rm | remove | unload)
                                        COMPREPLY=($(compgen -W "$(_module_loaded_modules)" -- "${cur}"));
                                        found=1;
                                        break
                                    ;;
                                    spider)
                                        COMPREPLY=($(compgen -W "$(_module_spider)" -- "${cur}"));
                                        found=1;
                                        break
                                    ;;
                                esac;
                            done;
                            if [ -z "${found}" ]; then
                                COMPREPLY=($(compgen -W "$(_module_avail)" -- "${cur}"));
                            fi;
                        fi;
                    fi
                ;;
            esac
        ;;
    esac
}
_module ()
{
    local cur="${2}" prev="${3}" cmds opts;
    COMPREPLY=();
    cmds="add avail delete help keyword list load purge rm restore         save show spider swap unload unuse update use whatis";
    opts="-d -D -h -q -t -v -w -s --style --expert --quiet --help         --quiet --terse --version --default --width -r --regexp --mt";
    case "${prev}" in
        add | load | try-load)
            COMPREPLY=($(compgen -W "$(_module_not_yet_loaded)" -- "${cur}"))
        ;;
        rm | remove | unload | switch | swap)
            COMPREPLY=($(compgen -W "$(_module_loaded_modules)" -- "${cur}"))
        ;;
        restore)
            COMPREPLY=($(compgen -W "$(_module_savelist)" -- "${cur}"))
        ;;
        spider)
            COMPREPLY=($(compgen -W "$(_module_spider)" -- "${cur}"))
        ;;
        unuse)
            COMPREPLY=($(IFS=: compgen -W "${MODULEPATH}" -- "${cur}"))
        ;;
        use | *-a*)
            _module_dir "${cur}"
        ;;
        help | show | whatis)
            COMPREPLY=($(compgen -W "$(_module_avail)" -- "${cur}"))
        ;;
        collection | cc | mcc)
            COMPREPLY=($(compgen -W "$(_module_mcc)" -- "${cur}"))
        ;;
        *)
            if [ ${COMP_CWORD} -gt 2 ]; then
                _module_long_arg_list "${cur}";
            else
                case "${cur}" in
                    ls)
                        COMPREPLY='list'
                    ;;
                    sw*)
                        COMPREPLY='swap'
                    ;;
                    -*)
                        COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
                    ;;
                    *)
                        COMPREPLY=($(compgen -W "${cmds}" -- "${cur}"))
                    ;;
                esac;
            fi
        ;;
    esac
}
_module_avail ()
{
    /home/kt/spack/opt/spack/linux-ubuntu16-x86_64/gcc-5.4.0/lmod-7.4.11-5ua5lwneglqkfxk5oxhvjffifohj6qs4/lmod/lmod/libexec/lmod bash --no_redirect -t -q avail 2>&1 > /dev/null | sed ' /:$/d; s/(@.*)//g; s#/*$##g;'
}
_module_dir ()
{
    local cur="${1}" pattern i;
    if [[ "${cur:0:1}" == '$' ]]; then
        pattern='^\$[[:alnum:]_]+\/$';
        if [[ ${cur} =~ ${pattern} ]]; then
            eval COMPREPLY[0]="${cur}";
        else
            COMPREPLY=($( compgen -v -P '$' -- "${cur:1}" ));
            local -a FILTEREDCOMPREPLY;
            for ((i=0; i < ${#COMPREPLY[@]}; i++))
            do
                pattern='^\$[[:alnum:]_]+$';
                if [[ ${COMPREPLY[$i]} =~ ${pattern} ]]; then
                    eval local env_val="${COMPREPLY[$i]}";
                    if [ -d "${env_val}" ]; then
                        FILTEREDCOMPREPLY+=(${COMPREPLY[$i]});
                    fi;
                fi;
            done;
            COMPREPLY=(${FILTEREDCOMPREPLY[@]});
        fi;
    else
        if [[ "${cur:0:1}" == '~' ]]; then
            if [[ "${cur}" != "${cur//\/}" ]]; then
                eval COMPREPLY[0]="${cur%%\/*}"/'${cur#*\/}';
            else
                eval COMPREPLY[0]="~";
            fi;
        else
            COMPREPLY=($(compgen -d -- "${cur}"));
        fi;
    fi;
    if [[ ${#COMPREPLY[@]} -eq 1 ]]; then
        pattern='\/$';
        if [[ -d "${COMPREPLY[0]}" && ! "${COMPREPLY[0]}" =~ ${pattern} ]]; then
            COMPREPLY[0]="${COMPREPLY[0]}/";
        fi;
        compopt -o nospace;
    fi
}
_module_loaded_modules ()
{
    /home/kt/spack/opt/spack/linux-ubuntu16-x86_64/gcc-5.4.0/lmod-7.4.11-5ua5lwneglqkfxk5oxhvjffifohj6qs4/lmod/lmod/libexec/lmod bash -q -t --no_redirect list 2>&1 > /dev/null | sed ' /^ *$/d; /:$/d; s#/*$##g;'
}
_module_loaded_modules_negated ()
{
    /home/kt/spack/opt/spack/linux-ubuntu16-x86_64/gcc-5.4.0/lmod-7.4.11-5ua5lwneglqkfxk5oxhvjffifohj6qs4/lmod/lmod/libexec/lmod bash -q -t --no_redirect list 2>&1 > /dev/null | sed ' /^ *$/d; /:$/d; s#/*$##g; s|^|-|g;'
}
_module_long_arg_list ()
{
    local cur="${1}" i;
    if [[ ${COMP_WORDS[COMP_CWORD-2]} == sw* ]]; then
        COMPREPLY=($(compgen -W "$(_module_not_yet_loaded)" -- "${cur}"));
        return;
    fi;
    for ((i = COMP_CWORD - 1; i > 0; i--))
    do
        case ${COMP_WORDS[${i}]} in
            add | load)
                COMPREPLY=($(compgen -W "$(_module_not_yet_loaded)" -- "${cur}"));
                break
            ;;
            rm | remove | unload | switch | swap)
                COMPREPLY=($(compgen -W "$(_module_loaded_modules)" -- "${cur}"));
                break
            ;;
        esac;
    done
}
_module_mcc ()
{
    /home/kt/spack/opt/spack/linux-ubuntu16-x86_64/gcc-5.4.0/lmod-7.4.11-5ua5lwneglqkfxk5oxhvjffifohj6qs4/lmod/lmod/libexec/lmod bash -q -t --no_redirect collection 2>&1 > /dev/null
}
_module_not_yet_loaded ()
{
    comm -23 <(_module_avail|sort) <(_module_loaded_modules|sort)
}
_module_savelist ()
{
    /home/kt/spack/opt/spack/linux-ubuntu16-x86_64/gcc-5.4.0/lmod-7.4.11-5ua5lwneglqkfxk5oxhvjffifohj6qs4/lmod/lmod/libexec/lmod bash -q -t --no_redirect savelist 2>&1 > /dev/null
}
_module_spider ()
{
    /home/kt/spack/opt/spack/linux-ubuntu16-x86_64/gcc-5.4.0/lmod-7.4.11-5ua5lwneglqkfxk5oxhvjffifohj6qs4/lmod/lmod/libexec/lmod bash -q -t --no_redirect spider 2>&1 > /dev/null
}
_modules ()
{
    local modpath;
    modpath=/lib/modules/$1;
    COMPREPLY=($( compgen -W "$( command ls -RL $modpath 2>/dev/null |         sed -ne 's/^\(.*\)\.k\{0,1\}o\(\.[gx]z\)\{0,1\}$/\1/p' )" -- "$cur" ))
}
_ncpus ()
{
    local var=NPROCESSORS_ONLN;
    [[ $OSTYPE == *linux* ]] && var=_$var;
    local n=$( getconf $var 2>/dev/null );
    printf %s ${n:-1}
}
_parse_help ()
{
    eval local cmd=$( quote "$1" );
    local line;
    {
        case $cmd in
            -)
                cat
            ;;
            *)
                LC_ALL=C "$( dequote "$cmd" )" ${2:---help} 2>&1
            ;;
        esac
    } | while read -r line; do
        [[ $line == *([ '	'])-* ]] || continue;
        while [[ $line =~ ((^|[^-])-[A-Za-z0-9?][[:space:]]+)\[?[A-Z0-9]+\]? ]]; do
            line=${line/"${BASH_REMATCH[0]}"/"${BASH_REMATCH[1]}"};
        done;
        __parse_options "${line// or /, }";
    done
}
_parse_usage ()
{
    eval local cmd=$( quote "$1" );
    local line match option i char;
    {
        case $cmd in
            -)
                cat
            ;;
            *)
                LC_ALL=C "$( dequote "$cmd" )" ${2:---usage} 2>&1
            ;;
        esac
    } | while read -r line; do
        while [[ $line =~ \[[[:space:]]*(-[^]]+)[[:space:]]*\] ]]; do
            match=${BASH_REMATCH[0]};
            option=${BASH_REMATCH[1]};
            case $option in
                -?(\[)+([a-zA-Z0-9?]))
                    for ((i=1; i < ${#option}; i++ ))
                    do
                        char=${option:i:1};
                        [[ $char != '[' ]] && printf '%s\n' -$char;
                    done
                ;;
                *)
                    __parse_options "$option"
                ;;
            esac;
            line=${line#*"$match"};
        done;
    done
}
_pci_ids ()
{
    COMPREPLY+=($( compgen -W         "$( PATH="$PATH:/sbin" lspci -n | awk '{print $3}')" -- "$cur" ))
}
_pgids ()
{
    COMPREPLY=($( compgen -W '$( command ps axo pgid= )' -- "$cur" ))
}
_pids ()
{
    COMPREPLY=($( compgen -W '$( command ps axo pid= )' -- "$cur" ))
}
_pnames ()
{
    COMPREPLY=($( compgen -X '<defunct>' -W '$( command ps axo command= | \
        sed -e "s/ .*//" -e "s:.*/::" -e "s/:$//" -e "s/^[[(-]//" \
            -e "s/[])]$//" | sort -u )' -- "$cur" ))
}
_quote_readline_by_ref ()
{
    if [ -z "$1" ]; then
        printf -v $2 %s "$1";
    else
        if [[ $1 == \'* ]]; then
            printf -v $2 %s "${1:1}";
        else
            if [[ $1 == \~* ]]; then
                printf -v $2 \~%q "${1:1}";
            else
                printf -v $2 %q "$1";
            fi;
        fi;
    fi;
    [[ ${!2} == *\\* ]] && printf -v $2 %s "${1//\\\\/\\}";
    [[ ${!2} == \$* ]] && eval $2=${!2}
}
_realcommand ()
{
    type -P "$1" > /dev/null && {
        if type -p realpath > /dev/null; then
            realpath "$(type -P "$1")";
        else
            if type -p greadlink > /dev/null; then
                greadlink -f "$(type -P "$1")";
            else
                if type -p readlink > /dev/null; then
                    readlink -f "$(type -P "$1")";
                else
                    type -P "$1";
                fi;
            fi;
        fi
    }
}
_rl_enabled ()
{
    [[ "$( bind -v )" = *$1+([[:space:]])on* ]]
}
_root_command ()
{
    local PATH=$PATH:/sbin:/usr/sbin:/usr/local/sbin;
    local root_command=$1;
    _command
}
_service ()
{
    local cur prev words cword;
    _init_completion || return;
    [[ $cword -gt 2 ]] && return 0;
    if [[ $cword -eq 1 && $prev == ?(*/)service ]]; then
        _services;
        [[ -e /etc/mandrake-release ]] && _xinetd_services;
    else
        local sysvdirs;
        _sysvdirs;
        COMPREPLY=($( compgen -W '`sed -e "y/|/ /" \
            -ne "s/^.*\(U\|msg_u\)sage.*{\(.*\)}.*$/\2/p" \
            ${sysvdirs[0]}/${prev##*/} 2>/dev/null` start stop' -- "$cur" ));
    fi
}
_services ()
{
    local sysvdirs;
    _sysvdirs;
    local restore_nullglob=$(shopt -p nullglob);
    shopt -s nullglob;
    COMPREPLY=($( printf '%s\n' ${sysvdirs[0]}/!($_backup_glob|functions) ));
    $restore_nullglob;
    COMPREPLY+=($( systemctl list-units --full --all 2>/dev/null |         awk '$1 ~ /\.service$/ { sub("\\.service$", "", $1); print $1 }' ));
    COMPREPLY=($( compgen -W '${COMPREPLY[@]#${sysvdirs[0]}/}' -- "$cur" ))
}
_shells ()
{
    local shell rest;
    while read -r shell rest; do
        [[ $shell == /* && $shell == "$cur"* ]] && COMPREPLY+=($shell);
    done 2> /dev/null < /etc/shells
}
_signals ()
{
    local -a sigs=($( compgen -P "$1" -A signal "SIG${cur#$1}" ));
    COMPREPLY+=("${sigs[@]/#${1}SIG/${1}}")
}
_split_longopt ()
{
    if [[ "$cur" == --?*=* ]]; then
        prev="${cur%%?(\\)=*}";
        cur="${cur#*=}";
        return 0;
    fi;
    return 1
}
_sysvdirs ()
{
    sysvdirs=();
    [[ -d /etc/rc.d/init.d ]] && sysvdirs+=(/etc/rc.d/init.d);
    [[ -d /etc/init.d ]] && sysvdirs+=(/etc/init.d);
    [[ -f /etc/slackware-version ]] && sysvdirs=(/etc/rc.d)
}
_terms ()
{
    COMPREPLY+=($( compgen -W         "$( sed -ne 's/^\([^[:space:]#|]\{2,\}\)|.*/\1/p' /etc/termcap             2>/dev/null )" -- "$cur" ));
    COMPREPLY+=($( compgen -W "$( { toe -a 2>/dev/null || toe 2>/dev/null; }         | awk '{ print $1 }' | sort -u )" -- "$cur" ))
}
_tilde ()
{
    local result=0;
    if [[ $1 == \~* && $1 != */* ]]; then
        COMPREPLY=($( compgen -P '~' -u "${1#\~}" ));
        result=${#COMPREPLY[@]};
        [[ $result -gt 0 ]] && compopt -o filenames 2> /dev/null;
    fi;
    return $result
}
_uids ()
{
    if type getent &> /dev/null; then
        COMPREPLY=($( compgen -W '$( getent passwd | cut -d: -f3 )' -- "$cur" ));
    else
        if type perl &> /dev/null; then
            COMPREPLY=($( compgen -W '$( perl -e '"'"'while (($uid) = (getpwent)[2]) { print $uid . "\n" }'"'"' )' -- "$cur" ));
        else
            COMPREPLY=($( compgen -W '$( cut -d: -f3 /etc/passwd )' -- "$cur" ));
        fi;
    fi
}
_upvar ()
{
    if unset -v "$1"; then
        if (( $# == 2 )); then
            eval $1=\"\$2\";
        else
            eval $1=\(\"\${@:2}\"\);
        fi;
    fi
}
_upvars ()
{
    if ! (( $# )); then
        echo "${FUNCNAME[0]}: usage: ${FUNCNAME[0]} [-v varname" "value] | [-aN varname [value ...]] ..." 1>&2;
        return 2;
    fi;
    while (( $# )); do
        case $1 in
            -a*)
                [[ -n ${1#-a} ]] || {
                    echo "bash: ${FUNCNAME[0]}: \`$1': missing" "number specifier" 1>&2;
                    return 1
                };
                printf %d "${1#-a}" &> /dev/null || {
                    echo "bash:" "${FUNCNAME[0]}: \`$1': invalid number specifier" 1>&2;
                    return 1
                };
                [[ -n "$2" ]] && unset -v "$2" && eval $2=\(\"\${@:3:${1#-a}}\"\) && shift $((${1#-a} + 2)) || {
                    echo "bash: ${FUNCNAME[0]}:" "\`$1${2+ }$2': missing argument(s)" 1>&2;
                    return 1
                }
            ;;
            -v)
                [[ -n "$2" ]] && unset -v "$2" && eval $2=\"\$3\" && shift 3 || {
                    echo "bash: ${FUNCNAME[0]}: $1: missing" "argument(s)" 1>&2;
                    return 1
                }
            ;;
            *)
                echo "bash: ${FUNCNAME[0]}: $1: invalid option" 1>&2;
                return 1
            ;;
        esac;
    done
}
_usb_ids ()
{
    COMPREPLY+=($( compgen -W         "$( PATH="$PATH:/sbin" lsusb | awk '{print $6}' )" -- "$cur" ))
}
_user_at_host ()
{
    local cur prev words cword;
    _init_completion -n : || return;
    if [[ $cur == *@* ]]; then
        _known_hosts_real "$cur";
    else
        COMPREPLY=($( compgen -u -- "$cur" ));
    fi;
    return 0
}
_usergroup ()
{
    if [[ $cur = *\\\\* || $cur = *:*:* ]]; then
        return;
    else
        if [[ $cur = *\\:* ]]; then
            local prefix;
            prefix=${cur%%*([^:])};
            prefix=${prefix//\\};
            local mycur="${cur#*[:]}";
            if [[ $1 == -u ]]; then
                _allowed_groups "$mycur";
            else
                local IFS='
';
                COMPREPLY=($( compgen -g -- "$mycur" ));
            fi;
            COMPREPLY=($( compgen -P "$prefix" -W "${COMPREPLY[@]}" ));
        else
            if [[ $cur = *:* ]]; then
                local mycur="${cur#*:}";
                if [[ $1 == -u ]]; then
                    _allowed_groups "$mycur";
                else
                    local IFS='
';
                    COMPREPLY=($( compgen -g -- "$mycur" ));
                fi;
            else
                if [[ $1 == -u ]]; then
                    _allowed_users "$cur";
                else
                    local IFS='
';
                    COMPREPLY=($( compgen -u -- "$cur" ));
                fi;
            fi;
        fi;
    fi
}
_userland ()
{
    local userland=$( uname -s );
    [[ $userland == @(Linux|GNU/*) ]] && userland=GNU;
    [[ $userland == $1 ]]
}
_variables ()
{
    if [[ $cur =~ ^(\$\{?)([A-Za-z0-9_]*)$ ]]; then
        [[ $cur == *{* ]] && local suffix=} || local suffix=;
        COMPREPLY+=($( compgen -P ${BASH_REMATCH[1]} -S "$suffix" -v --             "${BASH_REMATCH[2]}" ));
        return 0;
    fi;
    return 1
}
_xfunc ()
{
    set -- "$@";
    local srcfile=$1;
    shift;
    declare -F $1 &> /dev/null || {
        local compdir=./completions;
        [[ $BASH_SOURCE == */* ]] && compdir="${BASH_SOURCE%/*}/completions";
        . "$compdir/$srcfile"
    };
    "$@"
}
_xinetd_services ()
{
    local xinetddir=/etc/xinetd.d;
    if [[ -d $xinetddir ]]; then
        local restore_nullglob=$(shopt -p nullglob);
        shopt -s nullglob;
        local -a svcs=($( printf '%s\n' $xinetddir/!($_backup_glob) ));
        $restore_nullglob;
        COMPREPLY+=($( compgen -W '${svcs[@]#$xinetddir/}' -- "$cur" ));
    fi
}
clearMT ()
{
    eval $($LMOD_DIR/clearMT_cmd bash)
}
command_not_found_handle ()
{
    if [ -x /usr/lib/command-not-found ]; then
        /usr/lib/command-not-found -- "$1";
        return $?;
    else
        if [ -x /usr/share/command-not-found/command-not-found ]; then
            /usr/share/command-not-found/command-not-found -- "$1";
            return $?;
        else
            printf "%s: command not found\n" "$1" 1>&2;
            return 127;
        fi;
    fi
}
dequote ()
{
    eval printf %s "$1" 2> /dev/null
}
ml ()
{
    eval $($LMOD_DIR/ml_cmd "$@")
}
declare -fx ml
module ()
{
    eval $($LMOD_CMD bash "$@") && eval $(${LMOD_SETTARG_CMD:-:} -s sh)
}
declare -fx module
quote ()
{
    local quoted=${1//\'/\'\\\'\'};
    printf "'%s'" "$quoted"
}
quote_readline ()
{
    local quoted;
    _quote_readline_by_ref "$1" ret;
    printf %s "$ret"
}

# function ps1_loc
# {
#   # the current directory
#   newPWD=$(echo ${PWD} | sed -e "s%$HOME%~%")
#   echo $newPWD

#   local oldIFS=$IFS
#   IFS=:

#   # scratch directories --> "#"
#   local scratchdirs=/scratch:/lustre/ttscratch1:/lustre/scratch[123]/yellow
#   if [[ $1 ]]; then scratchdirs=$1; fi

#   for dir in $scratchdirs; do
#     echo "$dir"
#     if ! [[ `cat $newPWD | grep -c $dir/$USER` == 0 ]]; then
#       echo "#"
#       return;
#     fi
#   done

#   # /usr/project directories -> "@"
#   local devdirs=/usr/projects/jayenne/devs
#   if [[ $2 ]]; then scratchdirs=$2; fi

#   for dir in $devdirs; do
#     echo "$dir"
#     if ! [[ `cat $newPWD | grep -c $dir/$USER` == 0 ]]; then
#       echo "@"
#       return;
#     fi
#   done

#   IFS=$oldIFS

#   # default
#   echo "%"
# }


npwd_found=`declare -f npwd | wc -l`
git_ps1_found=`declare -f __git_ps1 | wc -l`
if [[ ${npwd_found} == 0 || ${git_ps1_found} == 0 ]]; then
  export PS1="\[\033]0;$TITLEPREFIX:${PWD//[^[:ascii:]]/?}\007\]\n\[\033[32m\]\u@\h \[\033[35m\]$MSYSTEM \[\033[33m\]\w\[\033[36m\]`__git_ps1`\[\033[0m\]\n$"
else
  export PS1="\[\033]0;\$TITLEPREFIX:\${PWD//[^[:ascii:]]/?}\007\]\n\[\033[32m\]\h\[\033[35m\]\$MSYSTEM \[\033[33m\]\$(npwd)\[\033[36m\]\$(__git_ps1)\[\033[0m\]\n% "
fi