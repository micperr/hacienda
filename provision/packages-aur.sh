if ! pacman -Qs yay > /dev/null ; then
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm --needed
  cd ..
  rm -rf yay
fi

yay -S ne
