# Windows service release management tasks

### Now Supporting deployment groups
No more usernames and passwords for deployment accounts!

This extension contains tasks to start and stop windows services as well as change the startup type.

1. **Start Windows Service(s)**

	This task will start windows service(s) on a list of machines and change the startup type to Automatic or Manual.

2. **Stop Windows Service(s)**

	This task will stop windows service(s) on a list of machines and change the startup type to Disabled, Automatic or Manual.

3. **Install (TopShelf) Windows Service(s)**
	
	Can be used to call executables that use [TopShelf](http://topshelf-project.com/) and install them as a service.

4. **Grant Logon As A Service Right**

	Topshelf handles this for you, but if you are winging it, you'll need this.
	

Version 7 changes:

 * Support deployment groups nativly. No more managing remote credentials in your releases!
 * Support instance names in start\stop tasks

Icons made by [Google](http://www.flaticon.com/authors/google) [www.flaticon.com](http://www.flaticon.com) [CC 3.0 BY](http://creativecommons.org/licenses/by/3.0/)
Icons made by [Freepik](http://www.freepik.com) [www.flaticon.com](http://www.flaticon.com) [CC 3.0 BY](http://creativecommons.org/licenses/by/3.0/)
