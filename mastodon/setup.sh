#!/bin/bash

if [ $# -ne 2 ]; then
	echo "Usage: setup.sh [DOMAIN] [EMAIL]"
	exit 1
fi

domain=$1
email=$2

domain_pattern="[a-z0-9-]+(\.[a-z0-9-]+)+"
if [[ !("$domain" =~ $domain_pattern) ]]; then
	echo "Invalid domain: $domain"
	exit 1
fi

email_pattern="[a-z0-9.+-]@[a-z0-9-]+(\.[a-z0-9-]+)+"
if [[ !("$email" =~ $email_pattern) ]]; then
	echo "Invalid mail address: $email"
	exit 1
fi


function setupNginx() {
	local domain=$1
	echo "Configuring Nginx..."
	sed -i".bak" -e "s/example\.com/$domain/g" /etc/nginx/sites-available/mastodon
}

function setupLetsEncrypt() {
	local domain=$1
	local email=$2
	echo "Configuring LetsEncrypt..."
	certbot register --agree-tos --no-eff-email -m $email
	certbot certonly --standalone -d $domain -n
	systemctl start nginx
	
	local renewal_path=/etc/letsencrypt/renewal/$domain.conf
	sed -i".bak" -e "s/^authenticator = standalone/authenticator = webroot/g" $renewal_path
	echo "webroot_path = /home/mastodon/live/public," >> $renewal_path
	echo "[[webroot_map]]" >> $renewal_path
	
	echo '0 0 1 * * root certbot renew --pre-hook "service nginx stop" --post-hook "service nginx start"' > /etc/cron.d/letsencrypt-renew
	systemctl restart cron
	
}

function setupMastodon() {
	local domain=$1
	echo "Configuring Mastodon..."
	
	echo "$domain" > /home/mastodon/.domain
	chown mastodon:mastodon /home/mastodon/.domain
	
	su -l mastodon <<'EOF'
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
export NODE_OPTIONS=--openssl-legacy-provider
domain=`cat /home/mastodon/.domain`

cd live
mastodon_conf_path=/home/mastodon/live/.env.production
cp -p $mastodon_conf_path $mastodon_conf_path.bak

sed -i -e "s/^LOCAL_DOMAIN=.*$/LOCAL_DOMAIN=$domain/g" $mastodon_conf_path

sed -i -e "s/^SECRET_KEY_BASE=.*$//g" $mastodon_conf_path
sed -i -e "s/^OTP_SECRET=.*$//g" $mastodon_conf_path
sed -i -e "s/^VAPID_PRIVATE_KEY=.*$//g" $mastodon_conf_path
sed -i -e "s/^VAPID_PUBLIC_KEY=.*$//g" $mastodon_conf_path
echo "SECRET_KEY_BASE=`RAILS_ENV=production bundle exec rake secret`" >> $mastodon_conf_path
echo "OTP_SECRET=`RAILS_ENV=production bundle exec rake secret`" >> $mastodon_conf_path
RAILS_ENV=production bundle exec rake mastodon:webpush:generate_vapid_key >> $mastodon_conf_path

db_password=`cat /etc/motd | grep "PostgreSQL mastodon user password" | cut -d ":" -f 2 | sed 's/^ *\| *$//'`
sed -i -e "s/^DB_PASS=.*$/DB_PASS=$db_password/g" $mastodon_conf_path

sed -i -e "s/^SMTP_SERVER=.*$/SMTP_SERVER=localhost/g" $mastodon_conf_path
sed -i -e "s/^SMTP_PORT=.*$/SMTP_PORT=25/g" $mastodon_conf_path
sed -i -e "s/^SMTP_AUTH_METHOD=.*$/SMTP_AUTH_METHOD=none/g" $mastodon_conf_path
sed -i -e "s/^SMTP_FROM_ADDRESS=.*$/SMTP_FROM_ADDRESS='Mastodon <notifications@$domain>'/g" $mastodon_conf_path

RAILS_ENV=production bundle exec rails db:setup
RAILS_ENV=production bundle exec rails assets:precompile

EOF
	
	systemctl enable mastodon-sidekiq.service
	systemctl enable mastodon-streaming.service
	systemctl enable mastodon-web.service
	systemctl start mastodon-sidekiq.service
	systemctl start mastodon-streaming.service
	systemctl start mastodon-web.service
}

function setupPostfix() {
	local domain=$1
	local email=$2

	echo "Configuring Postfix..."
	
	echo "postfix postfix/mailname string $domain" | debconf-set-selections
	echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
	apt-get install --assume-yes postfix
	DEBIAN_FRONTEND=noninteractive apt-get install

	echo "root: $email" >> /etc/aliases	
	newaliases
}

setupNginx $domain
setupLetsEncrypt $domain $email
setupMastodon $domain
setupPostfix $domain $email

