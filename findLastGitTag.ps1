$minors = @()
git fetch origin
$TAGS = git tag --list "${branchName}"
foreach ($tag in $TAGS)
{
    $minors += $tag.SubString($tag.LastIndexOf(".") + 1) -as [int]
}
if ($minors.Length -eq 0)
{
    $minors.Clear(); $minors += 0 -as [int]
}
$minors | sort -descending | select -First 1