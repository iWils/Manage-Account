$Global:currentFolder = split-path $MyInvocation.MyCommand.Path

##########################################################################
####                      Chargement des Assembly                     ####
##########################################################################

Add-Type -AssemblyName PresentationFramework

[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')  				| out-null
[System.Reflection.Assembly]::LoadWithPartialName('System.ComponentModel') 				| out-null
[System.Reflection.Assembly]::LoadWithPartialName('System.Data')           				| out-null
[System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')        				| out-null
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') 				| out-null
[System.Reflection.Assembly]::LoadWithPartialName('PresentationCore')      				| out-null
[System.Reflection.Assembly]::LoadFrom("assembly\MahApps.Metro.dll")  | out-null
[System.Reflection.Assembly]::LoadFrom("assembly\MahApps.Metro.IconPacks.dll")      | out-null  
[System.Reflection.Assembly]::LoadFrom("assembly\ControlzEx.dll")      | out-null
[System.Reflection.Assembly]::LoadFrom("assembly\Microsoft.Xaml.Behaviors.dll")      | out-null
[System.Reflection.Assembly]::LoadFrom("assembly\System.Windows.Interactivity.dll")      | out-null

##########################################################################
####               Chargement de XAML pour l'IHM WPF                  ####
##########################################################################

function LoadXaml ($filename){
    $XamlLoader=(New-Object System.Xml.XmlDocument)
    $XamlLoader.Load($filename)
    return $XamlLoader
}

$XamlMainWindow=LoadXaml($Global:currentFolder+"\Generator.xaml")
$reader = (New-Object System.Xml.XmlNodeReader $XamlMainWindow)
$Window = [Windows.Markup.XamlReader]::Load($reader)

[System.Windows.Forms.Application]::EnableVisualStyles()

##########################################################################
####                        VUES HAMBURGER                            ####
##########################################################################

#******************* Interface variable  *****************
$BtnNight = $Window.FindName("btn_night")
$TxtOrga = $Window.FindName("TxtOrga")
$TxtLogin = $Window.FindName("TxtLogin")
$PasBox = $Window.FindName("PasBox")
$TxtADDC = $Window.FindName("TxtADDC")
$TxtServer = $Window.FindName("TxtServer")
$TxtMail = $Window.FindName("TxtMail")
$BtnGenerate= $Window.FindName("BtnGenerate")



##########################################################################
####                      Test du thème système                       ####
##########################################################################

$Test_Windows_Theme = Test-Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
If ($Test_Windows_Theme)
	{
		$Windows_Theme_Key = get-itemproperty -path registry::"HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -erroraction 'silentlycontinue'	
		$Windows_Theme_Value = $Windows_Theme_Key.AppsUseLightTheme
		If($Windows_Theme_Value -ne $null)
			{
				If($Windows_Theme_Value -eq 1)
					{
						$OS_Theme = "Light"
					}
				Else
					{
						$OS_Theme = "Dark"
					}				
			}
		Else
			{
				$OS_Theme = "Light"
			}
	}
Else
	{
		$OS_Theme = "Light"
	}	
	
[ControlzEx.Theming.ThemeManager]::Current.ChangeThemeBaseColor($Window,$OS_Theme)

$BtnNight.Add_Click({
	$Theme = [ControlzEx.Theming.ThemeManager]::Current.DetectTheme($Window)
    $my_theme = ($Theme.BaseColorScheme)
	If($my_theme -eq "Light")
		{
            [ControlzEx.Theming.ThemeManager]::Current.ChangeThemeBaseColor($Window,"Dark")
				
		}
	ElseIf($my_theme -eq "Dark")
		{					
            [ControlzEx.Theming.ThemeManager]::Current.ChangeThemeBaseColor($Window,"Light")
		}		
})

$BtnGenerate.Add_Click({
    
    Write-Host $TxtOrga.Text
    Write-Host $TxtLogin.Text
    Write-Host $PasBox.Password
    Write-Host $TxtADDC.Text
    Write-Host $TxtServer.Text
    Write-Host $TxtMail.Text
    
    $PassCrypt = $PasBox.Password | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString
    Write-Host $PassCrypt   

    $json = @{Organization=$TxtOrga.Text; Account=$TxtLogin.Text; Password=$PassCrypt; Controller=$TxtADDC.Text; ServerMail=$TxtServer.Text; Mail=$TxtMail.Text } 
    $json | ConvertTo-Json | Out-File -Filepath $PSScriptRoot\"config.json"

    exit 1

})

#########################################################################
#                        Show Dialog                                    #
#########################################################################

$Window.add_MouseLeftButtonDown({
   $_.handled=$true
   $this.DragMove()
})

$Window.ShowDialog() | Out-Null

Pause