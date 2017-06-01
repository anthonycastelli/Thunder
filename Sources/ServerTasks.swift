//
//  ServerTasks.swift
//  Flock
//
//  Created by Jake Heiser on 3/31/17.
//
//

public extension TaskSource {
    // Generic
    
    static let server = TaskSource(tasks: DefaultSupervisordProvider().createTasks())
    
    // Specialized
    
    static let vapor = TaskSource(tasks: VaporSupervisord().createTasks())
}

// MARK: - Default

public extension Config {
    static var outputLog = "/var/log/supervisor/%(program_name)s-%(process_num)s.out"
    static var errorLog = "/var/log/supervisor/%(program_name)s-%(process_num)s.err"
    
    static var supervisordName: String? = nil
    static var supervisordUser: String? = nil
}

class DefaultSupervisordProvider: SupervisordProvider {
    let taskNamespace = "server"
}

// MARK: - Vapor

class VaporSupervisord: SupervisordProvider {
    
    let taskNamespace = "vapor"
    
    func confFile(for server: Server) -> SupervisordConfFile {
        var file = SupervisordConfFile(programName: supervisordName)
        file.command += " --env=\(Config.environment)"
        return file
    }
    
}

