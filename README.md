gitlab支持的CICD LANGUAGE :https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates

查找src目录，并以,分隔
find . -type d -name src | grep -v target | tr '\n' ',' | sed 's/,$//'
