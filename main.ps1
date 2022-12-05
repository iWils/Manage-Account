$Global:currentFolder = split-path $MyInvocation.MyCommand.Path
$Configfile = $Global:currentFolder+"\config.json"
$DateHeure = Get-Date -Format "dd-MM-yyyy-HH:mm"
$LogFile = $Global:currentFolder+"\Log_ReinitAccount.log"

Add-content -path $LogFile -Value " "
Add-content -path $LogFile -Value " --- Script ouvert par: $env:USERNAME a $DateHeure --- "

##########################################################################
####                      Chargement des Assembly                     ####
##########################################################################

Add-Type -AssemblyName PresentationFramework

[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')           | out-null
[System.Reflection.Assembly]::LoadWithPartialName('System.ComponentModel')          | out-null
[System.Reflection.Assembly]::LoadWithPartialName('System.Data')                    | out-null
[System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')                 | out-null
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework')          | out-null
[System.Reflection.Assembly]::LoadWithPartialName('PresentationCore')               | out-null
[System.Reflection.Assembly]::LoadFrom("assembly\MahApps.Metro.dll")                | out-null
[System.Reflection.Assembly]::LoadFrom("assembly\MahApps.Metro.IconPacks.dll")      | out-null  
[System.Reflection.Assembly]::LoadFrom("assembly\ControlzEx.dll")                   | out-null
[System.Reflection.Assembly]::LoadFrom("assembly\Microsoft.Xaml.Behaviors.dll")     | out-null
[System.Reflection.Assembly]::LoadFrom("assembly\System.Windows.Interactivity.dll") | out-null

#########################################################################
#                    Lecture du fichier de config                       #
#########################################################################

Add-content -path $LogFile -Value " --- $DateHeure : Ouverture du fichier de configuration --- "

If(Test-Path $Configfile){
    $Config = Get-Content -Raw $Configfile
    $Cfg = $Config | ConvertFrom-Json
    
    $PwdSecStr = $Cfg.Password | ConvertTo-SecureString
    $Credential = New-Object System.Management.Automation.PSCredential ($($Cfg.Account), $PwdSecStr)
    Add-content -path $LogFile -Value " --- $DateHeure : Fichier config.json ouvert --- "
 }
 Else{
    Write-Host "Le fichier n'existe pas !"
    Add-content -path $LogFile -Value " --- $DateHeure : Fichier config.json n'existe pas. Merci de le créer avec Generator.exe --- "
    exit 1
 }

##########################################################################
####                    Fonction d'envoi de mail                      ####
##########################################################################

function SendMail ($Firstname,$Password,$Usermail,$Server, $Adminmail){

    Send-MailMessage -To "admin"
    $XamlLoader=(New-Object System.Xml.XmlDocument)
    $XamlLoader.Load($filename)
    return $XamlLoader
}

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
$ResetView.Children.Add($ResetXaml)         | Out-Null    
$InfoView.Children.Add($InfoXaml)           | Out-Null      
$AboutView.Children.Add($AboutXaml)         | Out-Null

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
    $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Window,"Confirmation","Êtes-vous sûre? ",$okAndCancel, $settings)
    
    If ($result -eq "Affirmative"){ 
        Write-Host $TxbloginUnlk.Text
        $BarprogressUlk.Visibility="Visible"

        Try{
            $sdists = New-PSSession -Credential $Credential -ComputerName $($Cfg.Controller) -ErrorAction SilentlyContinue
        
            Invoke-command -Scriptblock {param($User) & Unlock-ADAccount -Identity $User} -session $sdists -ArgumentList $TxbloginUnlk.Text
        
            Remove-PSSession $sdists
        
            Write-Host "OK pour l'AD" -f Green
            Add-content -path $LogFile -Value " --- $DateHeure : Déblocage de compte OK pour l'AD ---"
            [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMessageAsync($Window, "Succès :-)", "Compte AD débloqué",$okOnly, $settings)		
        }
        Catch{ 
            Write-host "Erreur pour l'AD" -f Red
            [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMessageAsync($Window, "Echèc :-(", "Problème d'accès à l'AD",$okOnly, $settings)
            Add-content -path $LogFile -Value "--- $DateHeure : Déblocage de compte KO pour l'AD ---"
            Add-content -path $LogFile -Value "--- $DateHeure : Erreur: $errorvar ---"
        }

        $BarprogressUlk.Visibility="Hidden"
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
    $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Window,"Confirmation","Êtes-vous sûre? ",$okAndCancel, $settings)
    

    If ($result -eq "Affirmative"){ 
        Write-Host $TxbloginRst.Text
        $BarprogressRst.Visibility="Visible"

        $Newpasswd = [System.Web.Security.Membership]::GeneratePassword(14, 2)
        Add-content -path $LogFile -Value " --- Nouveau mot de passe: $Newpasswd --- "

        Try{
            $sdists = New-PSSession -Credential $Credential -ComputerName $($Cfg.Controller) -ErrorAction SilentlyContinue
        
            Invoke-Command -ScriptBlock {
                param($UserID,$UserPass,$ADMlogin,$ADMpass) # Déclaration des variable utile sur la session distante
        
                Import-Module ActiveDirectory
        
                $Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $ADMlogin, $ADMpass
                Set-ADAccountPassword -Identity $UserID -Credential $Cred -NewPassword (ConvertTo-SecureString -AsPlainText $UserPass -Force) -Reset > $null
        
            } -Session $sdists -ArgumentList $TxbloginRst.Text,$Newpasswd,$($Cfg.Account),$($PwdSecStr) -ErrorVariable errorvar 2>$null

            $Usermail = Invoke-command -Scriptblock {param($User) & Get-ADUser -Identity $User -Properties *} -session $sdists -ArgumentList $TxbloginRst.Text
        
            Remove-PSSession $sdists

            Write-Host "OK pour l'AD" -f Green
            Add-content -path $LogFile -Value " --- $DateHeure : Nouveau mot de passe pour le compte OK pour l'AD ---"
            [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMessageAsync($Window, "Succès :-)", "Nouveau mot de passe appliqué et envoyé à l'adresse $($Usermail.EmailAddress) !!!",$okOnly, $settings)		
        }
        Catch{ 
            Write-host "Erreur pour l'AD" -f Red
            [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMessageAsync($Window, "Echèc :-(", "Problème d'accès à l'AD",$okOnly, $settings)
            Add-content -path $LogFile -Value "--- $DateHeure : Nouveau mot de passe pour le compte KO pour l'AD ---"
            Add-content -path $LogFile -Value "--- $DateHeure : Erreur: $errorvar ---"
        }

        $BarprogressRst.Visibility="Hidden"

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
    $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Window,"Confirmation","Êtes-vous sûre? ",$okAndCancel, $settings)
    

    If ($result -eq "Affirmative"){ 
        Write-Host $TxbloginInfo.Text
        $BarprogressIfo.Visibility="Visible"

        Try{
            $sdists = New-PSSession -Credential $Credential -ComputerName $($Cfg.Controller) -ErrorAction SilentlyContinue

            $Return = Invoke-command -Scriptblock {param($User) & Get-ADUser -Identity $User -Properties *} -session $sdists -ArgumentList $TxbloginInfo.Text
            $Return2 = Invoke-command -Scriptblock {param($User) & Get-ADUser -Identity $User -Properties "DisplayName", "msDS-UserPasswordExpiryTimeComputed" |
            Select-Object -Property "Displayname",@{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}} -session $sdists -ArgumentList $TxbloginInfo.Text
        
            Remove-PSSession $sdists
        
            Write-Host "OK pour l'AD" -f Green
            Add-content -path $LogFile -Value " --- $DateHeure : Déblocage de compte OK pour l'AD ---"
            [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMessageAsync($Window, "Succès :-)", "Extraction terminée",$okOnly, $settings)			
        }
        Catch{ 
            Write-host "Erreur pour l'AD" -f Red
            [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMessageAsync($Window, "Echec :-(", "Problème d'accès à l'AD",$okOnly, $settings)
            Add-content -path $LogFile -Value "--- $DateHeure : Déblocage de compte KO pour l'AD ---"
            Add-content -path $LogFile -Value "--- $DateHeure : Erreur: $errorvar ---"
        }

        $BarprogressIfo.Visibility="Hidden"
    }
    else{
        exit 1
    }
    
    ### Affichage du volet Basique
    $IsEnabled_Value.Content = $Return.Enabled
    $Locked_Value.Content = $Return.LockedOut
    $IsPWDExpired_Value.Content = $Return.PasswordExpired
    $DisplayName_Value.Content = $Return.DisplayName
    $Account_Value.Content = $Return.SamAccountName
    $PWDLastChange_Value.Content = $Return.PasswordLastSet.ToString("dd/MM/yyyy HH:mm:ss")
    $PWD_Expiration_Date_Value.Content = $Return2.ExpiryDate.ToString("dd/MM/yyyy HH:mm:ss")
    $LastLogOn_Value.Content = $Return.LastLogonDate.ExpiryDate.ToString("dd/MM/yyyy HH:mm:ss")
    $UserOU_Value.Text = $Return.DistinguishedName
    $UserOU_Value.BorderBrush = "Transparent"

    ### Affichage du volet Avancé
    $Dept_Value.Content = $Return.Department
    $Mail_Value.Content = $Return.EmailAddress
    $Office_Value.Content = $Return.Office
    $LastBadPWD_Value.Content = $Return.LastBadPasswordAttempt.ToString("dd/MM/yyyy HH:mm:ss")
    $WhenCreated_Value.Content = $Return.whenCreated.ToString("dd/MM/yyyy HH:mm:ss")
    $WhenChanged_Value.Content = $Return.whenChanged.ToString("dd/MM/yyyy HH:mm:ss")
    $CannotChangePassword_Value.Content = $Return.CannotChangePassword
    $PWDNeverExpires_Value.Content = $Return.PasswordNeverExpires
  
})


############################################################################################################
# 								EXPORT INFOS PART
############################################################################################################

# ---------------------------------------------------------------------
# Action after clicking on the export user informations
# ---------------------------------------------------------------------

$Export_User_Values.Add_Click({
	$tmp_folder = $env:TEMP	
	$Users_Infos_TXT = "$tmp_folder\Infos_$MyUser.csv"

	If ($TxbloginInfo.Text -eq "")
		{
			[MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMessageAsync($Window, "Oops :-(", "Please select a user !!!")						
		}
	Else
		{		
		
			$Global:Users_Infos_To_Export = @{
			'SamAccountName' = $Get_User_Infos.SamAccountName
			'FullName' = $Get_User_Infos.Name
			'UserOU' = $Get_User_Infos.DistinguishedName	
			'LastLogOn' = $Get_User_Infos.LastLogonDate	
			'IsLocked' = $Get_User_Infos.LockedOut					
			'Dept' = $Get_User_Infos.Department	 
			'IsEnabled' = $Get_User_Infos.Enabled			
			'LastBadPWD' = $Get_User_Infos.LastBadPasswordAttempt									
			'Mail' = $Get_User_Infos.Mail	
			'Office' = $Get_User_Infos.Office	
			'IsPWDExpired' = $Get_User_Infos.PasswordExpired									
			'PWDLastChange' = $Get_User_Infos.PasswordLastSet		
			'WhenChanged' = $Get_User_Infos.WhenChanged									
			'WhenCreated' = $Get_User_Infos.WhenCreated	
			'CannotChangePassword' = $Get_User_Infos.CannotChangePassword						
			}
			New-Object -Type PSObject -Property $Users_Infos_To_Export		
			$Users_Infos_To_Export | out-file $Users_Infos_TXT			
			invoke-item $Users_Infos_TXT		
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
#                            Show Dialog                                #
#########################################################################

$Window.add_MouseLeftButtonDown({
   $_.handled=$true
   $this.DragMove()
})

# Make PowerShell Disappear
#$windowcode = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
#$asyncwindow = Add-Type -MemberDefinition $windowcode -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
#$null = $asyncwindow::ShowWindowAsync((Get-Process -PID $pid).MainWindowHandle, 0)

# Force garbage collection just to start slightly lower RAM usage.
[System.GC]::Collect()

$Window.ShowDialog() | Out-Null

Pause