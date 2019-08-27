function not_installed() {
  ! pacman -Qs $1 > /dev/null
}

if not_installed yay; then
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm --needed --noprogressbar
  cd ..
  rm -rf yay
fi

function install() {
  if not_installed $1; then
    yay -S $1 --noconfirm --needed --quiet
  else
    echo "$1 package already installed. Skipping..." >&2
  fi
}

install ne

yay -c --noconfirm
