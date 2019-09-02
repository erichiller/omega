param (
	[string]$manPage,
	[parameter(mandatory=$false, position=1, ValueFromRemainingArguments=$true)]$Remaining
 )

 echo $manPage

 echo $Remaining