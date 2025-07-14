gitlab支持的CICD LANGUAGE :https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates

查找src目录，并以,分隔
find . -type d -name src | grep -v target | tr '\n' ',' | sed 's/,$//'

find . -type d -name src | grep -v target | sed 's#/src$##' | tr '\n' ',' | sed 's/,$//'



find . -type d -name src | grep -v target | awk '{sub("/src$", ""); print}' | tr '\n' ',' | sed 's/,$//'


明文密码：Tigers@183
盐值：a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
加密算法：sha256
哈希值：1f612c7faad3d83b094b6c315e4df950

