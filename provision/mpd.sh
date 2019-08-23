mpddir=~/.config/mpd
mkdir -p ${mpddir} ${mpddir}/playlists
echo '#{template_mpd_conf}' > ${mpddir}/mpd.conf
touch ${mpddir}/{mpd.db,mpd.log,mpd.pid,mpdstate}
gpasswd --add vagrant audio
amixer set Master unmute && amixer set Master 100%
amixer set PCM unmute && amixer set PCM 100%
systemctl --user start mpd

mkdir ~/.ncmpcpp
echo '#{template_ncmpcpp_conf}' > ~/.ncmpcpp/config
