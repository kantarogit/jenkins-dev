$minors = @()
git fetch origin
echo $args[0]
$TAGS = git tag --list $args[0]+"*"
echo $TAGS
foreach ($tag in $TAGS)
{
    $minors += $tag.SubString($tag.LastIndexOf(".") + 1) -as [int]
}
if ($minors.Length -eq 0)
{
    $minors.Clear(); $minors += 0 -as [int]
}
$minors | sort -descending | select -First 1