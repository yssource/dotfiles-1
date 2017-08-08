#!/bin/bash

# source me in your script or .bashrc/.zshrc if wanna use cecho
# source '/path/to/functions.sh'

export LC_ALL="zh_CN.UTF-8"
export LC_TIME="zh_CN.UTF-8"
export LESSCHARSET=utf-8

# hh
export HH_CONFIG=hicolor         # get more colors
shopt -s histappend              # append new history items to .bash_history
# export HISTCONTROL=ignorespace   # leading space hides commands from history
export HISTFILESIZE=10000        # increase history file size (default is 500)
export HISTSIZE=${HISTFILESIZE}  # increase history size (default is 500)
export PROMPT_COMMAND="history -a; history -n; ${PROMPT_COMMAND}"   # mem/file sync
# if this is interactive shell, then bind hh to Ctrl-r (for Vi mode check doc)
if [[ $- =~ .*i.* ]]; then bind '"\C-r": "\C-a hh \C-j"'; fi

# ntfy
#eval "$(ntfy shell-integration)"

# {{ extract & compress

# function Extract for common file formats
function extract {
 if [ -z "$1" ]; then
    # display usage if no parameters given
    echo "Usage: extract <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
 else
    if [ -f "$1" ] ; then
        local nameInLowerCase=`echo "$1" | awk '{print tolower($0)}'`
        case "$nameInLowerCase" in
          *.tar.bz2)   tar xvjf ./"$1"    ;;
          *.tar.gz)    tar xvzf ./"$1"    ;;
          *.tar.xz)    tar xvJf ./"$1"    ;;
          *.lzma)      unlzma ./"$1"      ;;
          *.bz2)       bunzip2 ./"$1"     ;;
          *.rar)       unrar x -ad ./"$1" ;;
          *.gz)        gunzip ./"$1"      ;;
          *.tar)       tar xvf ./"$1"     ;;
          *.tbz2)      tar xvjf ./"$1"    ;;
          *.tgz)       tar xvzf ./"$1"    ;;
          *.zip)       unzip ./"$1"       ;;
          *.Z)         uncompress ./"$1"  ;;
          *.7z)        7z x ./"$1"        ;;
          *.xz)        unxz ./"$1"        ;;
          *.exe)       cabextract ./"$1"  ;;
          *)           echo "extract: '$1' - unknown archive method" ;;
        esac
    else
        echo "'$1' - file does not exist"
    fi
fi
}

# easy compress - archive wrapper
function compress () {
    if [ -n "$1" ] ; then
        FILE=$1
        case $FILE in
            *.tar) shift && tar cf $FILE $* ;;
            *.tar.bz2) shift && tar cjf $FILE $* ;;
            *.tar.gz) shift && tar czf $FILE $* ;;
            *.tgz) shift && tar czf $FILE $* ;;
            *.zip) shift && zip $FILE $* ;;
            *.rar) shift && rar $FILE $* ;;
        esac
    else
        echo "usage: compress <foo.tar.gz> ./foo ./bar"
    fi
}
# }}

# Speed up SSH X11 Forwarding
function sshx()
{
    ssh -X -C -c blowfish-cbc,arcfour $@
}

# build ssh tunnel
function ssht()
{
    ssh -qTnNfD 7070 $@
}

function bye () {
    sudo shutdown -h now
}

# {{ gpg
encrypt () { gpg -ac --no-options "$1"; }
decrypt () { gpg --no-options "$1"; }
# }}

# Print working file.
#
#     henrik@Henrik ~/.dotfiles[master]$ pwf ackrc
#     /Users/henrik/.dotfiles/ackrc
function pwf {
    echo "$PWD/$1"
}

# Create directory and cd to it.
#
#     henrik@Nyx /tmp$ mcd foo/bar/baz
#     henrik@Nyx /tmp/foo/bar/baz$
function mcd {
    mkdir -p "$1" && cd "$1"
}

# SSH to the given machine and add your id_rsa.pub or id_dsa.pub to authorized_keys.
#
#     henrik@Nyx ~$ sshkey hyper
#     Password:
#     sshkey done.
function sshkey {
    ssh $1 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys" < ~/.ssh/id_?sa.pub  # '?sa' is a glob, not a typo!
    echo "sshkey done."
}

# Create a data URI from a file and copy it to the pasteboard
datauri() {
    local mimeType=$(file -b --mime-type "$1")
    if [[ $mimeType == text/* ]]; then
        mimeType="${mimeType};charset=utf-8"
    fi
    printf "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')" | pbcopy | printf "=> data URI copied to pasteboard.\n"
}

# percol
# ps aux | percol | awk '{ print $2 }' | xargs kill
function ppgrep() {
    if [[ $1 == "" ]]; then
        PERCOL=percol
    else
        PERCOL="percol --query $1"
    fi
    ps aux | eval $PERCOL | awk '{ print $2 }'
}

function ppkill() {
    if [[ $1 =~ "^-" ]]; then
        QUERY=""            # options only
    else
        QUERY=$1            # with a query
        [[ $# > 0 ]] && shift
    fi
    ppgrep $QUERY | xargs kill $*
}

function myip() # get IP adresses
{
    myip=`w3m http://ipecho.net/plain`
    echo "${myip}"
}

function ii()   # get current host related info
{
    echo -e "\nYou are logged on $HOST"
    echo -e "\nAdditionnal information:$NC " ; uname -a
    echo -e "\nUsers logged on:$NC " ; w -h
    echo -e "\nCurrent date :$NC " ; date
    echo -e "\nMachine stats :$NC " ; uptime
    echo -e "\nMemory stats :$NC " ; free
    # my_ip 2>&- ;
    echo -e "\nLocal IP Address :$NC" ; myip
    echo
}

# finds directory sizes and lists them for the current directory
dirsize ()
{
    du -shx * .[a-zA-Z0-9_]* 2> /dev/null | \
        egrep '^ *[0-9.]*[MG]' | sort -n > /tmp/list
    egrep '^ *[0-9.]*M' /tmp/list
    egrep '^ *[0-9.]*G' /tmp/list
    rm -rf /tmp/list
}

# xclip has some problem with my emacs, so I use xsel for everything

function gclip() {
    if [ $OS_NAME == CYGWIN ]; then
        getclip $@;
    elif [ $OS_NAME == Darwin ]; then
        pbpaste $@;
    else
        if [ -x /usr/bin/xsel ]; then
            xsel -ob $@;
        else
            if [ -x /usr/bin/xclip ]; then
                xclip -o $@;
            else
                echo "Neither xsel or xclip is installed!"
            fi
        fi
    fi
}

function pclip() {
    if [ $OS_NAME == CYGWIN ]; then
        putclip $@;
    elif [ $OS_NAME == Darwin ]; then
        pbcopy $@;
    else
        if [ -x /usr/bin/xsel ]; then
            xsel -ib $@;
        else
            if [ -x /usr/bin/xclip ]; then
                xclip -selection c $@;
            else
                echo "Neither xsel or xclip is installed!"
            fi
        fi
    fi
}

function h () {
    # reverse history, pick up one line, remove new line characters and put it into clipboard
    if [ -z "$1" ]; then
        history | sed '1!G;h;$!d' | ~/bin/cli/percol | sed -n 's/^ *[0-9][0-9]* *\(.*\)$/\1/p'| tr -d '\n' | pclip
    else
        history | grep "$1" | sed '1!G;h;$!d' | ~/bin/cli/percol | sed -n 's/^ *[0-9][0-9]* *\(.*\)$/\1/p'| tr -d '\n' | pclip
    fi
}

function history_top_10 ()
{
    history | awk '{CMD[$2]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' \
        | grep -v "./" | column -c3 -s " " -t | sort -nr | nl | head -n10
}

function xtitle ()
{
    case "$TERM" in
        *term | rxvt)
            echo -n -e "\033]0;$*\007" ;;
        *)
        ;;
    esac
}

function big() {
    # find files and sort by size, full path is printed
    find -name "$*" -type f -printf "`pwd`%P %s\n"|sort -k2,2n
}

function pdf {
    if [ -f '/usr/bin/evince' ];then
        evince $@
    fi
}

proxy() {
    if [[ "${http_proxy:-NOTSET}" != "NOTSET" ]]; then
        unset http_proxy && unset https_proxy;
        echo "No proxy.";
    else
        export http_proxy=http://localhost:18080 && https_proxy=http://localhost:18080;
        echo "proxy = $http_proxy";
    fi;
}

# 在Emacs中阅读这些man page
pps_man() {
    emacsclient -t -e "(woman \"$1\")"
}
alias m=pps_man

###############################################################################
# Java
###############################################################################

switchJavaNetProxy() {
    [ -z "$JAVA_OPTS_BEFORE_NET_PROXY"] && {
        export JAVA_OPTS_BEFORE_NET_PROXY="$JAVA_OPTS"
        export JAVA_OPTS="$JAVA_OPTS -DproxySet=true -DsocksProxyHost=127.0.0.1 -DsocksProxyPort=7070"
        echo "turn ON java net proxy!"
    }|| {
        export JAVA_OPTS="$JAVA_OPTS_BEFORE_NET_PROXY"
        unset JAVA_OPTS_BEFORE_NET_PROXY
        echo "turn off java net proxy!"
    }
}