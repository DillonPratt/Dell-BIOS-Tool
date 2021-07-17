# Dell-BIOS-Tool

This tool is provides users easy access to Dell computer BIOS settings without needing to access the BIOS.

## Dependancies 
NuGet V3.3.0+ https://www.nuget.org/ <br/>
DellBiosPorivder V2.1.0 https://www.powershellgallery.com/packages/DellBIOSProvider/2.1.0
> You will be asked to install if you do have have nuget already installed.

## Compatible Machines
https://www.dell.com/support/kbdoc/en-ca/000146625/supported-platforms-bios-reference-list-for-dell-command-configure-dell-command-monitor-and-dell-command-powershell-provider

## Contributing
Anyone is free to create PR's with improvements and additions to Dell-Bios-Tool.

#Suggestions & Bug Reports
To report a bug, [click here](https://github.com/DillonPratt/Dell-BIOS-Tool/issues).

To suggest a new feature, [click here](https://github.com/DillonPratt/Dell-BIOS-Tool/issues).

## Demo
https://www.youtube.com/watch?v=lvIUx6yYKY0

## Notes
1.	This script will only work for the computer you’re running it on. It's possible to run commands through WinRM is the target computer is configured and listening, but this script has no functionality for external PC bios editing at this point.
2.	It’s impossible to send an ‘Invalid’ value to the BIOS using this tool. The options are locked to the options available in the BIOS.
3.	This only works on Dell machines. See 'Contributing' section for compatible PC's
4.	The script auto-elevates to ‘Run as Administrator’ status. 
5.	If the Dell BIOS module is not yet installed, you’ll be asked to install it first. You may also be asked to install NuGet if you don’t have it already.
