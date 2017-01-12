//
//  RealmGenerator.swift
//
//  Created by Anthony Miller on 1/4/17.
//  Copyright (c) 2017 App-Order, LLC. All rights reserved.
//

import Foundation

import Realm

// TODO: Document

public struct RealmGenerator {
    
    public static func generateAttributeFiles(for schema: RLMSchema, destination url: URL) throws {
        let fm = FileManager.default
        
        if !fm.fileExists(atPath: url.absoluteString) {
            try fm.createDirectory(atPath: url.absoluteString, withIntermediateDirectories: true, attributes: nil)
        }
        
        for object in schema.objectSchema {
            let file = generateFile(for: object)
            let fileURL = url
                .appendingPathComponent(object.className)
                .appendingPathExtension("generated")
                .appendingPathExtension("swift")
            
            do { try fm.removeItem(at: fileURL) } catch { }
            
            do {
             try file.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                
                throw error
            }
        }
        
    }
    
    private static func generateFile(for object: RLMObjectSchema) -> String {
        var components = [header(for: object),
                          importStatements,
                          objectExtensionHeader(for: object),
                          objectAttributes(for: object),
                          attributeExtensionHeader(for: object),
                          attributeExtensionAttributes(for: object),
                          ]
        
        if let uniqueIdentifiableExtension = uniqueIdentifiableExtension(for: object) {
            components.append(uniqueIdentifiableExtension)
        }
        
        return components.joined(separator: "\n\n")
    }
    
    private static func header(for object: RLMObjectSchema) -> String {
        return "//" + "\n" +
        "//  \(object.className).generated.swift"                                   + "\n" +
        "//"                                                                        + "\n" +
        "//  This code was generated by the QueryGenie code generator tool."        + "\n" +
        "//"                                                                        + "\n" +
        "//  Changes to this file may cause incorrect behavior and will be lost if" + "\n" +
        "//  the code is regenerated."                                              + "\n" +
        "//"
    }
    
    private static let importStatements: String = {
        return
        "import Foundation"     + "\n" +
        "\n" +
        "import RealmSwift"     + "\n" +
        "import QueryGenie"
    }()
    
    private static func objectExtensionHeader(for object: RLMObjectSchema) -> String {
        return
        "// MARK: - \(object.className) Query Attributes"           + "\n" +
                                                                      "\n" +
        "extension \(object.className) {"
    }
    
    private static func objectAttributes(for object: RLMObjectSchema) -> String {
        var lines = [String]()
        
        for property in object.allProperties {
            var attribute = self.attribute(for: property)
            if let primaryKey = object.primaryKeyProperty, property.isEqual(to: primaryKey) {
                attribute += " // Primary Key"
            }
            lines.append(attribute)
        }
        
        lines.append("")
        lines.append("}")
        
        return lines.joined(separator: "\n")
    }
    
    private static func attribute(for property: RLMProperty) -> String {
        let attributeType = property.optional ? "NullableAttribute" : "Attribute"
        let valueType = property.type
        return "    public static let \(property.name) = QueryGenie.\(attributeType)<\(self.valueType(for: property))>(\"\(property.name)\")"
    }
    
    private static func valueType(for property: RLMProperty) -> String {
        switch property.type {
        case .int: return "Int"
        case .bool: return "Bool"
        case .float: return "Float"
        case .double: return "Double"
        case .string: return "String"
        case .data: return "Data"
        case .any: return "Any"
        case .date: return "Date"
        case .object: return property.objectClassName ?? "Any"
        case .array: return "List<\(property.objectClassName ?? "Any")>"
        case .linkingObjects: return "LinkingObjects<\(property.objectClassName ?? "Any")>"
        }
    }

    private static func attributeExtensionHeader(for object: RLMObjectSchema) -> String {
        return
            "// MARK: - AttributeProtocol Extensions - \(object.className)"                             + "\n" +
                                                                                                          "\n" +
            "extension QueryGenie.AttributeProtocol where Self.ValueType: \(object.className) {"
    }
    
    private static func attributeExtensionAttributes(for object: RLMObjectSchema) -> String {
        var lines = [String]()
        
        for property in object.allProperties {
            var attribute = self.attributeExtensionAttribute(for: property)
            if let primaryKey = object.primaryKeyProperty, property.isEqual(to: primaryKey) {
                attribute += " // Primary Key"
            }
            lines.append(attribute)
        }
        
        lines.append("")
        lines.append("}")
        
        return lines.joined(separator: "\n")
    }
    
    private static func attributeExtensionAttribute(for property: RLMProperty) -> String {
        let attributeType = property.optional ? "NullableAttribute" : "Attribute"
        let valueType = property.type
        return "    public var \(property.name): QueryGenie.\(attributeType)<\(self.valueType(for: property))> " +
        "{ return \(attributeType)(\"\(property.name)\", self) }"
    }
    
    private static func uniqueIdentifiableExtension(for object: RLMObjectSchema) -> String? {
        guard let primaryKeyProperty = object.primaryKeyProperty else { return nil }
        
        return
            "// MARK: - UniqueIdentifiable - \(object.className)"                                       + "\n" +
                                                                                                          "\n" +
            "extension \(object.className): UniqueIdentifiable {"                                       + "\n" +
                                                                                                          "\n" +
            "   public typealias UniqueIdentifierType = \(self.valueType(for: primaryKeyProperty))"     + "\n" +
                                                                                                          "\n" +
            "}"
    }

}

fileprivate extension RLMObjectSchema {
    
    var allProperties: [RLMProperty] {
        let computedProperties = value(forKey: "computedProperties") as? [RLMProperty] ?? []
        return properties + computedProperties
    }
    
}
