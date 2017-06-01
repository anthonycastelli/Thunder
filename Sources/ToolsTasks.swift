//
//  ToolsCluster.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

import Rainbow

public extension TaskSource {
    static let tools = TaskSource(tasks:  [
        ToolsTask(),
        DependencyInstallationTask(),
        DeployAccountTask()
    ])
}

private let tools = "tools"

class ToolsTask: Task {
    let name = tools
    
    func run(on server: Server) throws {
        try invoke("tools:dependencies")
    }
}

class DependencyInstallationTask: Task {
    let name = "dependencies"
    let namespace = tools
    
    func run(on server: Server) throws {
        // Base stuff for the server
        print("Installing core components".cyan)
        try server.execute("sudo apt-get -qq update")
        try server.execute("sudo apt-get -qq install clang libicu-dev git libpython2.7 libcurl4-openssl-dev curl")
        
        print("Installing NGINX and Letsencrypt")
        try server.execute("sudo apt-get install nginx letsencrypt")
        
        print("Installing Vapor and Swift")
        try server.execute("wget -q https://repo.vapor.codes/apt/keyring.gpg -O- | sudo apt-key add -")
        try server.execute("echo \"deb https://repo.vapor.codes/apt $(lsb_release -sc) main\" | sudo tee /etc/apt/sources.list.d/vapor.list")
        try server.execute("sudo apt-get update")
        try server.execute("sudo apt-get install swift vapor")
        
        print("Testing Vapor".cyan)
        try server.execute("vapor version")
        
        print("Depending on your database setup, you may need to install the MySQL or PostgresQL libraries.".green)
        print("Don't forget to update your nginx sites (/etc/nginx/sites-enabled/default)".green)
        print("After generating an SSL certificate, make sure you setup ssl support for nginx.".green)
        try invoke("tools:account")
    }
}

class DeployAccountTask: Task {
    let name = "acount"
    let namespace = tools
    
    func run(on server: Server) throws {
        
        print("Setting up deploy account".cyan)
        try server.execute("sudo adduser --disabled-password --gecos \"\" deploy")
//        try server.execute("sudo adduser deploy sudo")
        try server.execute("sudo mkdir /home/deploy/.ssh")
        try server.execute("sudo chmod 700 /home/deploy/.ssh")
        try server.execute("sudo touch /home/deploy/.ssh/authorized_keys")
        try server.execute("sudo chmod 400 /home/deploy/.ssh/authorized_keys")
        try server.execute("sudo chown deploy:deploy /home/deploy -R")
        
        try server.execute("sudo mkdir /home/deploy/www")
        try server.execute("sudo chown deploy:deploy /home/deploy/www -R")
        try server.execute("sudo mkdir /home/deploy/logs")
        try server.execute("sudo chown deploy:deploy /home/deploy/logs -R")
        try server.execute("sudo mkdir /home/deploy/www/letsencrypt/.well-known/acme-challenge")
        try server.execute("sudo chown deploy:deploy /home/deploy/www/letsencrypt/.well-known/acme-challenge -R")
        
        print("And one last final thing. The deploy account is setup passwordless, so before you can deploy your Vapor app, you'll have to add your ssh key to '/home/deploy/.ssh/authorized_keys'. Make sure you do that through the root account.".green)
    }
}
