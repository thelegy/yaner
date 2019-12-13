print_info() {
  print -P "%B%F{blue}$1%b%f" >&2
}

print_warning() {
  print -P "%B%F{yellow}$1%b%f" >&2
}

print_error() {
  print -P "%B%F{red}$1%b%f" >&2
}
