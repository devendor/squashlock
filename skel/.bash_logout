# Process autogit based on var set in .bash_login
if ${AUTOGIT:-false} ; then
    cd  $HOME && {
        [ -d .git ] || git init .
        git diff -q | grep -q . && {
            git add --ignore-errors .
            git commit -m "Autocommit $(date +%s) ${HOSTNAME}"
        }
    }
fi
true
