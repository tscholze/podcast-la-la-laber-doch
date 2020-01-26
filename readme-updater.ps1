## Constants ##

$TemplatePath =  $PSScriptRoot + "/index_template.html"
$TargetPath = $PSScriptRoot + "/index.html"
$Uri = "http://feeds.soundcloud.com/users/soundcloud:users:757101730/sounds.rss"

$RowTemplate = '
<tr>
    <td>
        <a title="Zur Episode gehen" href="{{link}}}}">{{title}}</a>
    </td>
    <td>{{Description}}</td>
    <td>{{Duration}}</td>
</tr>';

## End constants ##

# Get feed from server
$Response = Invoke-WebRequest -Uri $Uri -UseBasicParsing -ContentType "application/xml"

# Ensure http code 200 is returned.
If ($Response.StatusCode -ne "200") 
{
    # Else, print an error and exit.
    Write-Host "Failed to read RSS file. Webserver returned status code $($Response.StatusCode)."
    Exit-PSSession    
}

# Get the xml-based content of the response.
$Feed = [xml]$Response.Content

# Empty list that will contain all items of the feed.
$Items = @()

$ns = New-Object System.Xml.XmlNamespaceManager($Feed.NameTable)
$ns.AddNamespace("itunes","http://www.itunes.com/dtds/podcast-1.0.dtd")

# Map the feed into an object (list).
ForEach ($Item in $Feed.rss.channel.item)
 {
    $Items += [PSCustomObject] @{
        'Title' = $Item.title.Split("-")[0].Trim()
        'Description' = $Item.title.Split("-")[1].Trim()
        'Link' = $Item.link
        'Duration' = $Item.Duration
    }
}

# Sort items ascending by its title.
# We assume that the title's prefix is an incremeting id.
$Items = $Items | Sort-Object -Property title

# Build html rows out of items
$RowsHtml = ""
ForEach ($Item in $Items)
{
    # Replace placeholder in template with actual value.
    $RowsHtml += $RowTemplate.Replace("{{Title}}", $Item.Title).Replace("{{Link}}", $Item.Link).Replace("{{Description}}", $Item.Description).Replace("{{Duration}}", $Item.Duration)
}

# Read target file
$Content = Get-Content -Path $TemplatePath -Raw;
$Content = $Content.Replace("{{TABLE_CONTENT}}", $RowsHtml)


Remove-Item -Path $TargetPath -ErrorAction SilentlyContinu
$Content | Out-File $TargetPath

# Git commit and push it to remote
Set-Location $PSScriptRoot
git add .
git commit -m "Updated index.html"
git push

Write-Host "We are Done"
