FROM archlinux/base

RUN pacman -Syyu --noconfirm
RUN pacman -S --noconfirm --needed git zsh which

SHELL ["/bin/zsh", "-c"]

WORKDIR /workdir


# RUN pacman -S --noconfirm --needed \
#     alsa-utils \
#     base-devel \
#     expect \
#     git \
#     htop \
#     mariadb \
#     mpd \
#     ncmpcpp \
#     nginx \
#     nodejs \
#     pacman-contrib \
#     php-fpm \
#     php-intl \
#     timidity++ \
#     unzip \
#     wget \
#     xdebug \
#     yarn \
#     zsh

# RUN timedatectl set-timezone Europe/Warsaw

########################
# YAY
# RUN git clone https://aur.archlinux.org/yay.git \
#     cd yay \
#     makepkg -si --noconfirm --needed --noprogressbar \
#     cd .. \
#     rm -rf yay \
#     yay -S --noconfirm --needed --quiet PACKAGENAME \
#     yay -c --noconfirm

# RUN which git
RUN chsh -s $(which zsh) $USER
# RUN chmod 755 /home/vagrant


########################
# MOTD
# RUN wget -qO /usr/bin/update_motd.sh https://gist.githubusercontent.com/micperr/efe6e415610bd893b3a4ac9882bd9dd4/raw/4c4fe1a24f9f4a1cdb292be9fdace2a0f223a924/motd.sh \
  # chmod 775 /usr/bin/update_motd.sh \
  # sed -e ':motd=/etc/motd: s/^#*/#/' -i /etc/pam.d/system-login
  # sed -e '/pam_motd.so/ s/^#*/#/' -i /etc/pam.d/system-login \
  # printf "\nsession    optional   pam_exec.so   stdout /usr/bin/update_motd.sh\nsession    optional   pam_motd.so   motd=/etc/motd" | tee -a /etc/pam.d/sshd > /dev/null


########################
# ZPREZTO
RUN git clone --quiet --recursive https://github.com/micperr/prezto.git ~/.zprezto
RUN for rcfile in ${ZDOTDIR:-$HOME}/.zprezto/runcoms/^README.md(.N); do; rcfile_dst=${ZDOTDIR:-$HOME}/.${rcfile:t}; if [ ! -f ${rcfile_dst} ]; then; ln -s ${rcfile} ${rcfile_dst}; fi; done
RUN autoload -Uz compinit && compinit
# ADD provision/prezto.sh /workdir/prezto.sh
# RUN chmod +x /workdir/prezto.sh
# RUN /workdir/prezto.sh
