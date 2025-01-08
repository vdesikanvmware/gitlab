**Steps**
1. git clone https://github.com/vdesikanvmware/gitlab.git
2. cd gitlab
3. chmod +x gitlab.sh
4. ./gitlab.sh

# Generating personal access token with this values: glpat-cLL8BbNYWf7hd313X9aX
docker exec -t gitlab gitlab-rails runner "token = User.find_by_username('root').personal_access_tokens.create(scopes: ['api', 'read_api', 'read_user', 'read_repository', 'write_repository', 'sudo', 'admin_mode'], name: 'Automation token', expires_at: 365.days.from_now); token.set_token('glpat-cLL8BbNYWf7hd313X9aX'); token.save!"

echo "glpat-cLL8BbNYWf7hd313X9aX" > /home/kubo/gitlab_personal_access_token

# Sample example on how to to create group via gitlab api using personal access token
curl --request POST --header "PRIVATE-TOKEN: glpat-cLL8BbNYWf7hd313X9aX" \
     --header "Content-Type: application/json" \
     --data '{"path": "test-group", "name": "test-group", "default_branch": "main", "visibility": "public" }' \
     "https://gitlab.tanzu.io:445/api/v4/groups/"
