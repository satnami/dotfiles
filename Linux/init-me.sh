#!/usr/bin/env bash

sudo apt-get update
sudo apt-get upgrade

#unity yakk
sudo apt-get install unity ubuntu-desktop unity-tweak-tool unity-scope-home

#virtualbox
apt-get install -y virtualbox

#vagrant
apt-get install -y vagrant

#git
sudo apt-get install -y build-essential libssl-dev libcurl4-gnutls-dev libexpat1-dev gettext unzip
sudo apt-get install -y git

#node
curl -sL https://deb.nodesource.com/setup_7.x | sudo bash -
sudo apt-get install -y nodejs
sudo apt-get install -y build-essential


#ruby
sudo apt-get install -y git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libffi-dev

git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
exec $SHELL

git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
exec $SHELL

git clone https://github.com/rbenv/rbenv-default-gems.git $(rbenv root)/plugins/rbenv-default-gems
echo -e "bundler\n\n# Misc\nlolcat\nterminal-notifier\n\n# UML\nrailroad\nrailroady\njekyll\n\n# Code smell & analyzer\nreek\nrubocop\n\n# Development\nyaml-lint\naescrypt\nhttparty\npuma 3.10.0\n\n# Framework\nrake\nthin\nforeman\nsinatra\nrails\n" >> $(rbenv root)/default-gems
exec $SHELL

rbenv install 2.3.1
rbenv global 2.3.1
rbenv rehash
