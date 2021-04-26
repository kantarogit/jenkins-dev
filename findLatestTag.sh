declare -a minors
git fetch origin
tags=`git tag --list $1`
echo $tags
for tag in $tags
do
        echo $tag
        version=${tag#*.}
        echo "version+ " $version
        minors+=($version)
done
echo "some minors "+ ${minors[@]}
echo "minors size" + ${#minors[@]}
if [ ${#minors[@]} -eq 0 ]; then
        minors+=("0")
fi
echo ${minors[-1]}
