# MPD
mpddir=~/.config/mpd
mkdir -p ${mpddir} ${mpddir}/playlists
cp /vagrant/provision/templates/mpd.conf ${mpddir}/mpd.conf
touch ${mpddir}/{mpd.db,mpd.log,mpd.pid,mpdstate}
sudo gpasswd --add vagrant audio
sudo amixer set Master unmute && sudo amixer set PCM unmute
sudo amixer set Master 100%   && sudo amixer set PCM 100%

# NCMPCPP
mkdir -p ~/.ncmpcpp
cp /vagrant/provision/templates/ncmpcpp.conf ~/.ncmpcpp/config
