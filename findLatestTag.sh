declare -a minors
git fetch origin
tags=`git tag --list $1`
for tag in $tags
do
        version=${tag#*.}
        minors+=($version)
done
if [ ${#minors[@]} -eq 0 ]; then
        minors+=("0")
fi
echo ${minors[-1]}
