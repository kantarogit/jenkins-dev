$minors = @()
git fetch origin
$TAGS = git tag --list "f3*"
foreach ($tag in $TAGS)
{
    $minors += $tag.SubString($tag.LastIndexOf(".") + 1) -as [int]
}
if ($minors.Length -eq 0)
{
    $minors.Clear(); $minors += 1 -as [int]
}
$minors | sort -descending | select -First 1
