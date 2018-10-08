#!/bin/sh

test_description="request generated html pages"

. /usr/share/sharness/sharness.sh


get_munin_url() {
    curl --silent --fail "http://localhost/munin/$1"
}


get_mime_type() {
    file --mime-type --brief -
}


configure_apache2_for_strategy() {
    local apache2_conf="/etc/apache2/conf-enabled/munin.conf"

    # remove strategy-specific setting from apache configuration
    sed -i '/^\(Script\)\?Alias \/munin /d' "$apache2_conf"

    if [ "$MUNIN_TEST_CGI_ENABLED" = "1" ]; then
        echo "ScriptAlias /munin /usr/lib/munin/cgi/munin-cgi-html" >>"$apache2_conf"
        a2enmod cgid
        service apache2 restart
    else
        echo "Alias /munin /var/cache/munin/www" >>"$apache2_conf"
        a2dismod cgid
        service apache2 restart
    fi
}


configure_apache2_for_strategy


test_expect_success "main site: mime type" '
  [ "$(get_munin_url "/" | get_mime_type)" = "text/xml" ]
'

test_expect_success "main site: dynamically generated" '
  get_munin_url "/" | grep -q "Auto-generated by Munin"
'

test_expect_success "main site: contains node" '
  get_munin_url "/" | grep -q "localhost.localdomain/index.html"
'

test_expect_success "assets: CSS" '
  get_munin_url "/static/style-new.css" | grep -q "margin-top"
'

test_expect_success "node: html" '
  get_munin_url "/localdomain/localhost.localdomain/" | grep -q "df-day.png"
'

test_expect_success "node: graph" '
  get_munin_url "/localdomain/localhost.localdomain/df-day.png" | get_mime_type "image/png"
'

test_done
