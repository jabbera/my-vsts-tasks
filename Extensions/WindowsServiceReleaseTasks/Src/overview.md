# Windows service release management tasks
This extension contains tasks to start and stop windows services as well as change the startup type. This uses powershell remoting.

1. **Start Windows Service(s)**

	This task will start windows service(s) on a list of machines and change the startup type to Automatic or Manual.

2. **Stop Windows Service(s)**

	This task will stop windows service(s) on a list of machines and change the startup type to Disabled, Automatic or Manual.

3. **Install (TopShelf) Windows Service(s)**
	
	Can be used to call executables that use [TopShelf](http://topshelf-project.com/) and install them as a service.

4. **Grant Logon As A Service Right**

	Topshelf handles this for you, but if you are winging it, you'll need this.
	
Note: 1.16153.1 includes breaking changes from version 0.0.*. You will need to resave your builds\releases after installing. 

Primary Changes include:

 * New task: Grant logon as a service
 * Ability to kill service if it doesn't stop in time

 * Removing DSC in favor of remote powershell execution via Invoke-RemoteDeployment
 * Allowing multiple services\exe by  comma separating them
 * Relocation of the install task to Deploy from Utility

Icons made by [Google](http://www.flaticon.com/authors/google) [www.flaticon.com](http://www.flaticon.com) [CC 3.0 BY](http://creativecommons.org/licenses/by/3.0/)
Icons made by [Freepik](http://www.freepik.com) [www.flaticon.com](http://www.flaticon.com) [CC 3.0 BY](http://creativecommons.org/licenses/by/3.0/)
