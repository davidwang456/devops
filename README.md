gitlab支持的CICD LANGUAGE :https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates

查找src目录，并以,分隔
find . -type d -name src | grep -v target | tr '\n' ',' | sed 's/,$//'

find . -type d -name src | grep -v target | sed 's#/src$##' | tr '\n' ',' | sed 's/,$//'



find . -type d -name src | grep -v target | awk '{sub("/src$", ""); print}' | tr '\n' ',' | sed 's/,$//'


Tigers@183
a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
cc5e8a8531646d3eb5df6299a52a2ec75deba4a12522f484f74a1ed6c18d1a99

