# Thunder

[![Build Status](https://travis-ci.org/anthonycastelli/Thunder.svg?branch=master)](https://travis-ci.org/anthonycastelli/Thunder)

Automated 1-click deployment of Swift projects to servers. Once set up, deploying your project is as simple as:
```
$ thunder deploy
```
Thunder will clone your project onto your server(s), build it, and start the application (and do anything else you want it to do). 

Originally forked off of [Flock](https://github.com/jakeheis/Flock).

Table of Contents
=================

   * [Installation](#installation)
       * [Homebrew](#homebrew)
       * [Manual](#manual)
   * [Setup](#setup)
      * [Init](#init)
      * [Dependencies](#dependencies)
         * [Server dependencies](#server-dependencies)
      * [Environments](#environments)
   * [Tasks](#tasks)
       * [Running tasks](#running-tasks)
       * [Writing your own tasks](#writing-your-own-tasks)
   * [Permissions](#permissions)
   * [Related projects](#related-projects)

# Installation
### Homebrew
```bash
~brew install anthonycastelli/repo/thunder~
```
### Manual
```bash
git clone https://github.com/anthonycastelli/ThunderCLI
cd ThunderCLI
swift build -c release
ln -s .build/release/ThunderCLI /usr/bin/local/thunder
```
If the symlink doesnt work, get the full path of the current working directory using `pwd`

# Setup
## Init
To start using Thunder, run:
```bash
thunder --init
```
After this command completes, you should follow the instructions Thunder prints. Following these instructions should be enough to get your project up and running. For more information about the files Flock creates, read on.

### Thunderfile
The Flockfile specifies which tasks and configurations you want Flock to use. 
`Thunder.Deploy` includes the following tasks:
```bash
thunder deploy          # Invokes deploy:git, deploy:build, and deploy:link 
thunder deploy:git      # Clones your project onto your server into a timestamped directory
thunder deploy:build    # Builds your project
thunder deploy:link     # Links your newly built project directory as the current directory
```
Running `thunder deploy` will:

1. Clone your project onto your server into a timestamped directory (e.g. `/home/deploy/www/VaporExample/releases/20161028211084`)
2. Build your project
3. Link your built project to the `current` directory (e.g. `/home/deploy/www/VaporExample/current`)

`FThunder.Tools` includes tasks which assist in installing the necessary tools for your swift project to run on the server:
```bash
thunder tools                 # Invokes tools:dependencies, tools:swift       
thunder tools:dependencies    # Installs dependencies necessary for 
thunder tools:account       # Will setup the deploy account
```


### config/deploy/ThunderDependencies.json
This file contains your Flock dependencies. To start this only contains `Flock` itself, but if you want to use third party tasks you can add their repositories here. You specify the repository's URL and version (there are three ways to specify version):
```json
{
   "dependencies" : [
       {
           "name" : "https://github.com/anthonycastelli/Thunder",
           "major": 1
       }
   ]
}
```
See the [dependencies](#dependencies) section below for more information on third party dependencies.

### config/deploy/Always.swift
This file contains configuration which will always be used. This is where config which is needed regardless of environment should be placed. Some fields you'll need to update before running any Flock tasks:
```
Config.projectName = "ProjectName"
Config.executableName = "ExecutableName"
Config.repoURL = "URL"
```

### config/deploy/Production.swift and config/deploy/Staging.swift
These files contain configuration specific to the production and staging environments, respectively. They will only be run when Flock is executed in their environment (using `thunder task -e staging`). Generally this is where you'll want to specify your production and staging servers. There are multiple ways to specify a server:
```swift
func configure() {
      // For project-wide auth:
      Config.SSHAuthMethod = .key("/path/to/my/key")
      Servers.add(ip: "9.9.9.9", user: "deploy", roles: [.app, .db, .web])
      
      // For server-specific auth:
      Servers.add(ip: "9.9.9.9", user: "deploy", roles: [.app, .db, .web], authMethod: .key("/path/to/another/key"))

      // Or, if you've added your server to your .ssh/config file, you can use this shorthand:
      Servers.add(SSHHost: "NamedServer", roles: [.app, .db, .web])
}
```

### .thunder
You can (in general) ignore all the files in this directory.


## Environments

If you want to add additional configuration environments (beyond "staging" and "production), you can do that in the `Thunderfile`. To create a `testing` environment, for example, you would start by running `thunder --add-env Testing` and then modify the `Thunderfile` as such:
```swift
...

Thunder.configure(.always, with: Always()) // Located at config/deploy/Always.swift
Thunder.configure(.env("production"), with: Production()) // Located at config/deploy/Production.swift
Thunder.configure(.env("staging"), with: Staging()) // Located at config/deploy/Staging.swift
Thunder.configure(.env("testing"), with: Testing()) // Located at config/deploy/Testing.swift

...
```

# Tasks

### Running tasks
You can see the available tasks by running `flock` with no arguments. To run a task, just call `flock <task>`, such as:
```bash
thunder deploy # Run the deploy task
thunder deploy:build # Run the build task located under the deploy namespace
```
Passing the `-n` flag tells Flock to do a dry-run, meaning to only print commands without actually executing any.
```bash
thunder vapor:start -n # Do a dry-run of the start task located under the vapor namespace
```
You can also pass the `-e <env>` key, telling Flock to run the task in a certain environment:
```bash
thunder tools -e staging # Run the tools task in the staging environment
```

### Writing your own tasks
Start by running:
```bash
thunder --create db:migrate # Or whatever you want to call your new task
```

This will create file at config/deploy/DbMigrateTask.swift with the following contents:
```swift
import Thunder

extension Thunder {
   public static let <NameThisGroup>: [Task] = [
       MigrateTask()
   ]
}

// Delete if no custom Config properties are needed
extension Config {
   // public static var myVar = ""
}

class MigrateTask: Task {
   let name = "migrate"
   let namespace = "db"

   func run(on server: Server) throws {
      // Do work
   }
}
```

Some of `Server`'s available methods are:
```swift
try server.execute("mysql -v") // Execute a command remotely

let contents = try server.capture("cat myFile") // Execute a command remotely and capture the output

// Execute all commands in this closure within Path.currentDirectory
try server.within(Path.currentDirectory) {
    try server.execute("ls")
    if server.fileExists("anotherFile.txt") { // Check the existence of a file on the server
        try server.execute("cat anotherFile.txt")
    }
}
```

Check out [Server.swift](https://github.com/anthonycastelli/Thunder/blob/master/Sources/Server.swift#L73) to see all of `Server`'s available methods. Also take a look at [Paths.swift](https://github.com/anthonycastelli/Thunder/blob/master/Sources/Paths.swift) to see the built-in paths for your `server.within` calls.

After running `thunder --create`, make sure you:

1. Replace \<NameThisGroup\> at the top of your new file with a custom name
1. In your Flockfile, add `Flock.use(WhateverINamedIt)`

#### Hooking

If you wish to hook your task onto another task (i.e. always run this task before/after another task, just add an array of hook times to your Task:
```swift
class MigrateTask: Task {
   let name = "migrate"
   let namespace = "db"
   let hookTimes: [HookTime] = [.after("deploy:build")]
   
   func run(on server: Server) throws {
      // Do work
   }
}
```

#### Invoking another task
```swift
func run(on server: Server) throws {
      try invoke("other:task")
}
```
# Permissions
### thunder deploy
In general, you should create a dedicated deploy user on your server. [Authentication & Authorisation](http://capistranorb.com/documentation/getting-started/authentication-and-authorisation/#) is a great resource for learning how to do this.

To ensure the `deploy` task succeeds, make sure:
- The deploy user has access to `Config.deployDirectory` (default /home/deploy/www)
- The deploy user has access to the `swift` executable

Some additional considerations if you are using `Thunder.Server`:
- The deploy user can run `supervisorctl` commands (see [Using supervisorctl with linux permissions but without root or sudo](https://coffeeonthekeyboard.com/using-supervisorctl-with-linux-permissions-but-without-root-or-sudo-977/) for more info)
- The deploy user has access to the `supervisor` config file (default /etc/supervisor/conf.d/server.conf)

Running `flock tools` can take care of most of these things for you, but you must set `Config.supervisordUser` in `config/deploy/Always.swift` to your dedicated deploy user *before* running `thunder tools`.
### flock tools
The `tools` task must be run as the root user. This means that in `config/deploy/Production.swift`, in your `Servers.add` call you must pass `user: "root"`. As mentioned above, it is not a good idea to deploy with `user: "root"`, so you should only call `flock tools` with this configuration and then change it to make calls with your dedicated deploy user rather then the root user.

# Server
### NGINX
Don't forget to setup your vapor NGINX config file. A good example is [The Vapor Docs](https://docs.vapor.codes/2.0/deploy/nginx/)

### SSL (LetsEncrypt)
Here is a nice getting started setup for SSL certificates via LetsEncrypt [GitHub Gist](https://gist.github.com/cecilemuller/a26737699a7e70a7093d4dc115915de8)

Don't forget your `sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 4096`

If you use LetsEncrypt, you'll want to setup some sort of renewal script. 

1. Edit your crontab: \"sudo crontab -e\" (This must be done on the root account. EC2 Instance is ubuntu via the certificate from AWS)
2. Add this to your crontab

```bash
# Lets Encrypt SSL Renewal every Monday at 2:30 AM
30 2 * * 1 sudo certbot renew --noninteractive --renew-hook >> /home/deploy/logs/le-renew.log
35 2 * * 1 sudo systemctl reload nginx
``` 
