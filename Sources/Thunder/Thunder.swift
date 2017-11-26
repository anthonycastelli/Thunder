//
//  Flock.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

#if os(Linux)
import Glibc
#else
import Darwin
#endif

import SwiftCLI

public class Thunder {
  
    private(set) static var tasks: [Task] = []
    private static var configurations: [ConfigurationTime: Configuration] = [:]
  
    // MARK: - Public
    
    public static func use(_ taskSource: TaskSource) {
        tasks += taskSource.tasks
    }
    
    public static func configure(_ time: ConfigurationTime, with configuration: Configuration) {
        configurations[time] = configuration
    }
    
    public static func run() -> Never {
        tasks += TaskSource.tools.tasks
        tasks += TaskSource.deploy.tasks
        tasks += TaskSource.vapor.tasks

        TaskExecutor.setup(with: tasks)
        
        let commands = tasks.map { TaskCommand(task: $0) as Command }
        
        let cli = CLI(
            name: "Thunder",
            version: "1.1.0",
            description: "Thunder: Automated deployment of your Vapor app"
        )
        
        cli.commands = commands
        cli.commands.append(HelpCommand())
        
//        cli.helpCommand = HelpCommand()
//        cli.versionCommand = VersionCommand()
        
//        CommandAliaser.alias(from: "-h", to: <#T##String#>)
//        CommandAliaser.alias(from: "-h", to: CLI.helpCommand.name)
//        CommandAliaser.alias(from: "-v", to: CLI.versionCommand?.name)
        
        let result = cli.go()
        exit(result)
    }
    
    // MARK: - Internal
    
    static func configure(for environment: String) {
        Config.environment = environment
        
        configurations[.always]?.configure()
        configurations[.env(environment)]?.configure()
    }
    
}
