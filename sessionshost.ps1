configuration SessionHost
{

Import-DscResource -ModuleName xPendingReboot, xTimeZone, xStorage, xPSDesiredStateConfiguration

    Node localhost
    {
      
        WindowsFeature RDS-RD-Server
        {
            Ensure = "Present"
            Name = "RDS-RD-Server"
        }

       # Set the timezone for the server
        xTimeZone WestEurope {
            TimeZone = 'W. Europe Standard Time'
            IsSingleInstance = 'Yes'
        }

        # Create the RDS application admin directory for the application
        File BeheerDirectory {
            Ensure = 'Present'
            DestinationPath = 'C:\Software'
            Type = 'Directory'
        }

    }
}