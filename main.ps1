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

$XamlMainWindow=LoadXaml($Global:currentFolder+"\main.xaml")
$reader = (New-Object System.Xml.XmlNodeReader $XamlMainWindow)
$Window = [Windows.Markup.XamlReader]::Load($reader)

[System.Windows.Forms.Application]::EnableVisualStyles()

##########################################################################
####                        VUES HAMBURGER                            ####
##########################################################################

#******************* Interface variable  *****************
$btn_night = $Window.FindName("btn_night")

#******************* Target View  *****************

$HamburgerMenuControl = $Window.FindName("HamburgerMenuControl")

$UnlockView = $Window.FindName("UnlockView") 
$ResetView = $Window.FindName("ResetView")
$InfoView = $Window.FindName("InfoView") 
$AboutView = $Window.FindName("AboutView") 

#******************* Load Other Views  *****************
$viewFolder = $Global:currentFolder +"\views"

$XamlChildWindow = LoadXaml($viewFolder+"\Reset.xaml")
$Childreader     = (New-Object System.Xml.XmlNodeReader $XamlChildWindow)
$ResetXaml        = [Windows.Markup.XamlReader]::Load($Childreader)


$XamlChildWindow = LoadXaml($viewFolder+"\Unlock.xaml")
$Childreader     = (New-Object System.Xml.XmlNodeReader $XamlChildWindow)
$UnlockXaml    = [Windows.Markup.XamlReader]::Load($Childreader)


$XamlChildWindow = LoadXaml($viewFolder+"\Info.xaml")
$Childreader     = (New-Object System.Xml.XmlNodeReader $XamlChildWindow)
$InfoXaml    = [Windows.Markup.XamlReader]::Load($Childreader)


$XamlChildWindow = LoadXaml($viewFolder+"\About.xaml")
$Childreader     = (New-Object System.Xml.XmlNodeReader $XamlChildWindow)
$AboutXaml       = [Windows.Markup.XamlReader]::Load($Childreader)


$UnlockView.Children.Add($UnlockXaml)       | Out-Null
$ResetView.Children.Add($ResetXaml)  | Out-Null    
$InfoView.Children.Add($InfoXaml)  | Out-Null      
$AboutView.Children.Add($AboutXaml)        | Out-Null

#******************************************************
# Initialize with the first value of Item Section *****
#******************************************************

$HamburgerMenuControl.SelectedItem = $HamburgerMenuControl.ItemsSource[0]


##########################################################################
####                           UNLOCK VIEW                            ####
##########################################################################

$TxbloginUnlk = $UnlockXaml.FindName("TxbloginUnlk")
$btnValidUnlk = $UnlockXaml.FindName("btnValidUnlk")
$BarprogressUlk = $UnlockXaml.FindName("BarprogressUlk")


$btnValidUnlk.add_Click({

    # OK CANCEL Style
    $okAndCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative
    # OK ONLY
    $okOnly      = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative

    # Metro Dialog Settings
    $settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()
    $settings.ColorScheme = [MahApps.Metro.Controls.Dialogs.MetroDialogColorScheme]::Theme

    # show ok/cancel message
    $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Window,"Confirmation","Are you sure? ",$okAndCancel, $settings)
    

    If ($result -eq "Affirmative"){ 
        Write-Host $TxbloginUnlk.Text
        $BarprogressUlk.Visibility="Visible"
    }
    else{
        exit 1
    }
  
})


##########################################################################
####                           RESET VIEW                             ####
##########################################################################

$TxbloginRst = $ResetXaml.FindName("TxbloginRst")
$btnValidRst = $ResetXaml.FindName("btnValidRst")
$BarprogressRst = $ResetXaml.FindName("BarprogressRst")


$btnValidRst.add_Click({

    # OK CANCEL Style
    $okAndCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative
    # OK ONLY
    $okOnly      = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative

    # Metro Dialog Settings
    $settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()
    $settings.ColorScheme = [MahApps.Metro.Controls.Dialogs.MetroDialogColorScheme]::Theme

    # show ok/cancel message
    $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Window,"Confirmation","Are you sure? ",$okAndCancel, $settings)
    

    If ($result -eq "Affirmative"){ 
        Write-Host $TxbloginRst.Text
        $BarprogressRst.Visibility="Visible"

    }
    else{
        exit 1
    }
  
})


##########################################################################
####                             INFO VIEW                            ####
##########################################################################

$TxbloginInfo = $InfoXaml.FindName("TxbloginInfo")
$btnValidInfo = $InfoXaml.FindName("btnValidInfo")
$BarprogressIfo = $InfoXaml.FindName("BarprogressIfo")

# Basic infos block
$Expander_Basic_Block = $InfoXaml.findname("Expander_Basic_Block") 
$Expander_Basic = $InfoXaml.findname("Expander_Basic") 
$IsEnabled_Value = $InfoXaml.findname("IsEnabled_Value") 
$Locked_Value = $InfoXaml.findname("Locked_Value") 
$IsPWDExpired_Value = $InfoXaml.findname("IsPWDExpired_Value") 
$DisplayName_Value = $InfoXaml.findname("DisplayName_Value") 
$Account_Value = $InfoXaml.findname("Account_Value") 
$PWDLastChange_Value = $InfoXaml.findname("PWDLastChange_Value") 
$PWD_Expiration_Date_Value = $InfoXaml.findname("PWD_Expiration_Date_Value") 
$LastLogOn_Value = $InfoXaml.findname("LastLogOn_Value") 
$UserOU_Value = $InfoXaml.findname("UserOU_Value") 

# More infos block
$Expander_More_Block = $InfoXaml.findname("Expander_More_Block") 
$Expander_More = $InfoXaml.findname("Expander_More") 
$Dept_Value = $InfoXaml.findname("Dept_Value") 
$Mail_Value = $InfoXaml.findname("Mail_Value") 
$Office_Value = $InfoXaml.findname("Office_Value") 
$LastBadPWD_Value = $InfoXaml.findname("LastBadPWD_Value") 
$WhenCreated_Value = $InfoXaml.findname("WhenCreated_Value") 
$WhenChanged_Value = $InfoXaml.findname("WhenChanged_Value") 
$CannotChangePassword_Value = $InfoXaml.findname("CannotChangePassword_Value") 
$PWDNeverExpires_Value = $InfoXaml.findname("PWDNeverExpires_Value") 

# More options action block
$Expander_More_options_Block = $InfoXaml.findname("Expander_More_options_Block") 
$Expander_More_options = $InfoXaml.findname("Expander_More_options") 
$Export_User_Values = $InfoXaml.findname("Export_User_Values") 
$User_Display_Groups = $InfoXaml.findname("User_Display_Groups")


$btnValidInfo.add_Click({

    # OK CANCEL Style
    $okAndCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative
    # OK ONLY
    $okOnly      = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative

    # Metro Dialog Settings
    $settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()
    $settings.ColorScheme = [MahApps.Metro.Controls.Dialogs.MetroDialogColorScheme]::Theme

    # show ok/cancel message
    $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Window,"Confirmation","Are you sure? ",$okAndCancel, $settings)
    

    If ($result -eq "Affirmative"){ 
        Write-Host $TxbloginInfo.Text
        $BarprogressIfo.Visibility="Visible"
    }
    else{
        exit 1
    }
  
})


#########################################################################
#                        HAMBURGER EVENTS                               #
#########################################################################

#******************* Items Section  *******************

$HamburgerMenuControl.add_ItemClick({
    
   $HamburgerMenuControl.Content = $HamburgerMenuControl.SelectedItem
   $HamburgerMenuControl.IsPaneOpen = $false

})

#******************* Options Section  *******************

$HamburgerMenuControl.add_OptionsItemClick({

    $HamburgerMenuControl.Content = $HamburgerMenuControl.SelectedOptionsItem
    $HamburgerMenuControl.IsPaneOpen = $false

})

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

$btn_night.Add_Click({
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


#########################################################################
#                        Show Dialog                                    #
#########################################################################

$Window.add_MouseLeftButtonDown({
   $_.handled=$true
   $this.DragMove()
})

$Window.ShowDialog() | Out-Null

Pause