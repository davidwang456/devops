gitlab支持的CICD LANGUAGE :https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates

查找src目录，并以,分隔
find . -type d -name src | grep -v target | tr '\n' ',' | sed 's/,$//'

find . -type d -name src | grep -v target | sed 's#/src$##' | tr '\n' ',' | sed 's/,$//'



find . -type d -name src | grep -v target | awk '{sub("/src$", ""); print}' | tr '\n' ',' | sed 's/,$//'


UPDATE harbor_user 
SET password = 'e6caf85b1cd5039e02d94e8f524f5601',
    salt = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6',
    password_version = 'sha256'
WHERE username = 'admin';

