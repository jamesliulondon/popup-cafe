#!/bin/bash

# user is 'root'

/bin/echo 'yes' | /opt/gitlab/bin/gitlab-rake gitlab:setup RAILS_ENV=production

/opt/gitlab/bin/gitlab-rails console production <<EOF
user = User.where(id: 1).first
user.password = 'secret_password'
user.password_confirmation = 'secret_password'
user.save!
EOF

