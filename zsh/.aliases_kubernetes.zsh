alias k="kubectl"

# --- kubeconfig management: one file per cluster in ~/.kube/configs/*.yaml --------
# kcfg               pick a kubeconfig for THIS shell (fzf, preview: server / identity)
# kcfg <name>        use ~/.kube/configs/<name>.yaml in this shell
# kcfg -r            back to the default kubeconfig in this shell
# kcfg -d [<name>]   set the default for new shells (~/.kube/config -> symlink)
# kcfg -l            list all kubeconfigs (name, context, server, identity)
# kcfg-add <file> [<name>]   review and import a kubeconfig (chmod 600)
# Switching only changes $KUBECONFIG of the current shell - other terminals are not affected.
export KCFG_DIR="$HOME/.kube/configs"

_kcfg_pick() {
  local prompt=${1:-kubeconfig}
  kcfg-info --list | fzf --delimiter=$'\t' --with-nth=2 --header-lines=1 --no-multi \
    --layout=reverse --height=80% --prompt="$prompt> " \
    --header='* active  D default  P production  ! warnings  (Enter select, Esc cancel)' \
    --preview='kcfg-info --show {1}' --preview-window=down,40%,border-top | cut -f1
}

_kcfg_resolve() {
  if [[ -n $1 ]]; then
    local f=$KCFG_DIR/$1.yaml
    [[ -f $f ]] || f=$KCFG_DIR/$1.yml
    [[ -f $f ]] || f=$KCFG_DIR/$1
    [[ -f $f ]] || { print -u2 "kcfg: no such kubeconfig: $1 (see kcfg -l)"; return 1 }
    print -r -- $f
  else
    local f=$(_kcfg_pick "$2")
    [[ -n $f ]] || return 1
    print -r -- $f
  fi
}

# production = a word "prod"/"prd"/"production" (not "nonprod", "non-prod", "preprod")
_kcfg_is_prod() {
  local -a words=(${(s: :)${${(L)1}//[^a-z0-9]/ }})
  local i
  for (( i = 1; i <= $#words; i++ )); do
    [[ ${words[i]} == (prod|prd|production) && ${words[i-1]:-} != non ]] && return 0
  done
  return 1
}

_kcfg_summary() {
  local ctx=$(kubectl config current-context 2>/dev/null)
  local srv=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null)
  local ns=$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
  local file=${KUBECONFIG:-$HOME/.kube/config (default)}
  print -P "%F{cyan}kubeconfig%f ${file/#$HOME/~}"
  print -P "%F{cyan}context%f    ${ctx:-<none>}  %F{cyan}ns%f ${ns:-default}"
  print -P "%F{cyan}server%f     ${srv:-?}"
  _kcfg_is_prod "$ctx" || _kcfg_is_prod "${KUBECONFIG:t:r}" && print -P "%F{red}%B⚠ PRODUCTION%b%f"
  return 0
}

kcfg() {
  local file
  case $1 in
    -h|--help)
      sed -n '/^# --- kubeconfig management/,/^export KCFG_DIR/p' ~/.aliases_kubernetes.zsh | sed '$d'
      ;;
    -l|--list)
      kcfg-info --table
      ;;
    -r|--reset)
      unset KUBECONFIG
      _kcfg_summary
      ;;
    -d|--default)
      if [[ -e $HOME/.kube/config && ! -L $HOME/.kube/config ]]; then
        print -u2 "kcfg: ~/.kube/config is a regular file - move it into $KCFG_DIR first"
        return 1
      fi
      file=$(_kcfg_resolve "$2" "default") || return 1
      ln -sfn -- "$file" "$HOME/.kube/config"
      print "default for new shells: ${file:t:r}"
      ;;
    -*)
      print -u2 "kcfg: unknown option $1 (kcfg -h)"
      return 2
      ;;
    *)
      file=$(_kcfg_resolve "$1") || return 1
      export KUBECONFIG=$file
      _kcfg_summary
      ;;
  esac
}

kcfg-add() {
  local src=$1 name=$2
  if [[ -z $src || ! -f $src ]]; then
    print -u2 "usage: kcfg-add <kubeconfig-file> [<name>]"
    return 2
  fi
  name=${name:-${${src:t}%.*}}
  local dst=$KCFG_DIR/$name.yaml
  if [[ -e $dst ]]; then
    print -u2 "kcfg-add: $dst already exists - pick another name: kcfg-add $src <name>"
    return 1
  fi
  print -P "%F{yellow}Review before importing (exec plugins run a command on every kubectl call):%f\n"
  kcfg-info --show "$src" || return 1
  print
  read -q "?Import as ${dst/#$HOME/~}? [y/N] " || { print; return 1 }
  print
  mkdir -p -m 700 -- $KCFG_DIR
  (umask 077 && cp -- "$src" "$dst") && chmod 600 -- "$dst"
  print "added: kcfg $name"
}

_kcfg_names() {
  local -a names
  names=(${${${(f)"$(command ls -1 -- $KCFG_DIR 2>/dev/null)"}%.yaml}%.yml})
  _describe 'kubeconfig' names
}
compdef _kcfg_names kcfg 2>/dev/null
