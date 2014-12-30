# bash completion for busted
#

_busted_comp() {
  local opt IFS=' '$'\t'$'\n'
  for opt in $1; do
    case $opt in
      --*=*) printf %s$'\n' "$opt"  ;;
      *.)    printf %s$'\n' "$opt"  ;;
      *)     printf %s$'\n' "$opt " ;;
    esac
  done
}

_busted() {
  COMPREPLY=()
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"

  if [[ "${cur}" == "=" ]]; then
    cur=
  fi
  if [[ "${prev}" == "=" ]]; then
    prev="${COMP_WORDS[COMP_CWORD-2]}"
  fi

  case "${prev}" in
    --lang)
      local langs="ar de en fr ja nl ru th ua zh"
      COMPREPLY=( $(compgen -W "${langs}" -- ${cur}) )
      return 0
      ;;
    -o|--output)
      local outputs="plainTerminal utfTerminal TAP json junit sound"
      local -a toks
      toks=( ${toks[@]-} $(compgen -W "${outputs}" -- ${cur} ) )
      toks=( ${toks[@]-} $(compgen -f -X "!*.lua" -- ${cur} ) )
      toks=( ${toks[@]-} $(compgen -f -X "!*.moon" -- ${cur} ) )
      toks=( ${toks[@]-} $(compgen -d -- ${cur} ) )
      _compopt_o_filenames

      COMPREPLY=( "${COMPREPLY[@]}" "${toks[@]}" )
      return 0
      ;;
    -r|--run)
      local d="."
      local i
      for (( i=1; i < ${#COMP_WORDS[@]}-1; i++ )); do
        case "${COMP_WORDS[i]}" in
          -d|--cwd)
            d="${COMP_WORDS[i+1]}"
            ;;
        esac
      done
      local cfgs=$(lua -e "cfgs=dofile('${d}/.busted')" \
                       -e "for k,_ in pairs(cfgs) do print(k) end" 2> /dev/null)
      COMPREPLY=( $(compgen -W "${cfgs}" -- ${cur}) )
      return 0
      ;;
    --loaders)
      local prefix=${cur%,*}
      local cur_=${cur##*,}
      local loaders="lua moonscript terra"
      local -a toks
      toks=( ${toks[@]-} $(compgen -W "${loaders[@]}" -- ${cur} ) )
      if [[ "${prefix}" != "${cur}" ]]; then
        local mloaders=""
        for l in ${loaders}; do
          if ! [[ "${prefix}," =~ .*,$l,.* || "${prefix}," =~ ^$l,.* ]]; then
            mloaders="${mloaders} $l"
          fi
        done
        toks=( ${toks[@]-} $(compgen -P "${prefix}," -W "${mloaders}" -- ${cur_} ) )
      fi
      compopt -o nospace

      COMPREPLY=( "${COMPREPLY[@]}" "${toks[@]}" )
      return 0
      ;;
    -d|--cwd)
      _filedir -d
      return 0
      ;;
    --helper)
      _filedir
      return 0
      ;;
    -p|--pattern)
      # no completion available
      return 0
      ;;
    -t|--tags|--exclude-tags)
      # no completion available
      return 0
      ;;
    -m|--lpath|--cpath)
      _filedir -d
      return 0
      ;;
    --repeat)
      # no completion available
      return 0
      ;;
    --seed)
      # no completion available
      return 0
      ;;
  esac

  if [[ "${cur}" == -* ]] ; then
    local opts="
      -h --help
      -v --verbose
      --version
      -o --output=
      -p --pattern=
      -d --cwd=
      -t --tags= --exclude-tags=
      -m --lpath= --cpath=
      -r --run=
      --repeat=
      --seed=
      --lang=
      --loaders=
      --helper=
      -c --coverage
      -s --enable-sound
      --randomize --shuffle
      --supress-pending
      --defer-print"
    compopt -o nospace

    local IFS=$'\n'
    COMPREPLY=( $(compgen -W "$(_busted_comp "${opts-}")" -- "${cur}" ))
    return 0
  else
    _filedir
  fi
}

complete -F _busted busted
