# echo 'export PATH="$HOME/.rbenv/bin:$HOME/.gem/ruby/2.5.0/bin:$PATH"' >> ~/.zshrc
# rbenv init

# Patched hack to install Ruby 2.2.3 which is incompatible with openssl 1.1
# curl -fsSL https://gist.githubusercontent.com/micperr/3d84ccecafd40afe95a3af8687f29b90/raw/ | PKG_CONFIG_PATH=/usr/lib/openssl-1.0/pkgconfig rbenv install --patch 2.2.3
