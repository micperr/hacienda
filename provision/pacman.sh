  pacman -Syyu --noconfirm
  # pacman-key --init
  # pacman -Sy --noconfirm archlinux-keyring
  pacman -S --noconfirm --needed \
  alsa-utils \
  base-devel \
  expect \
  git \
  htop \
  mariadb \
  mpd \
  ncmpcpp \
  nginx \
  nodejs \
  pacman-contrib \
  php-fpm \
  php-intl \
  timidity++ \
  unzip \
  wget \
  xdebug \
  zsh

if ! pacman -Qs yay > /dev/null ; then
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm --needed
  cd ..
  rm -rf yay

  yay -S ne
fi
