add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

# Parameters
$hosts = '192.168.1.2', '192.168.1.1'
$email_to = 'helpdesk@test.com'
$email_server = 'smtp.test.com'
$api_key= ""
# Folder must exists
$folder_path = "C:\Backup\PaloAlto\"

function Send-ToEmail([string]$body){

    $message = new-object Net.Mail.MailMessage;
    $message.From = "PaloAltoBackupScript@test.com";
    $message.To.Add($email_to);
    $message.Subject = "Palo Alto Config Backup Failed!";
    $message.Body = "

    $($body)" ;

    $smtp = new-object Net.Mail.SmtpClient($email_server, "25");
    $smtp.send($message);
 }

foreach ($host_pa in $hosts) {
    
    $file = "$($folder_path)\PaloAltoConfigBackup_$($host_pa)_$(get-date -f yyyy_MM_dd).xml"

    $url = "https://$($host_pa)/api/?type=export&category=configuration&key=$($api_key)"

    try
    {
        $Response = Invoke-WebRequest -UseBasicParsing -PassThru -OutFile $file -Uri $url
        $StatusCode = $Response.StatusCode
    }
    catch
    {
        $StatusCode = $_.Exception.Response.StatusCode.value__
        $Response = $_
    }


    if ($StatusCode -ne 200 ) {
        Send-ToEmail -body "  Palo Alto Server: $($host_pa)
        Reason:
        
        $($Response.Exception)
        $($Response.ErrorDetails)
        "
        exit
    }


}
