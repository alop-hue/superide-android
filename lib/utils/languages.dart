import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:highlight/highlight.dart';
import 'package:highlight/languages/arduino.dart';
import 'package:highlight/languages/armasm.dart';
import 'package:highlight/languages/avrasm.dart';
import 'package:highlight/languages/bash.dart';
import 'package:highlight/languages/cs.dart';
import 'package:highlight/languages/clojure.dart';
import 'package:highlight/languages/coffeescript.dart';
import 'package:highlight/languages/cpp.dart';
import 'package:highlight/languages/css.dart';
import 'package:highlight/languages/dart.dart';
import 'package:highlight/languages/elixir.dart';
import 'package:highlight/languages/fsharp.dart';
import 'package:highlight/languages/go.dart';
import 'package:highlight/languages/haskell.dart';
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/kotlin.dart';
import 'package:highlight/languages/lua.dart';
import 'package:highlight/languages/markdown.dart';
import 'package:highlight/languages/objectivec.dart';
import 'package:highlight/languages/perl.dart';
import 'package:highlight/languages/php.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/r.dart';
import 'package:highlight/languages/ruby.dart';
import 'package:highlight/languages/rust.dart';
import 'package:highlight/languages/scala.dart';
import 'package:highlight/languages/scss.dart';
import 'package:highlight/languages/sql.dart';
import 'package:highlight/languages/swift.dart';
import 'package:highlight/languages/typescript.dart';
import 'package:highlight/languages/x86asm.dart';
import 'package:highlight/languages/yaml.dart';

class Language {
  final String name, extension, details, helloWorld;
  final Mode language;
  final dynamic icon;
  final String? command,type;
  Language({
      required this.name,
      required this.extension,
      required this.details,
      required this.language,
      required this.helloWorld,
      this.icon,
      this.command,
      this.type
      });
}

List<Language> languages = [
  Language(
    name: 'Python',
    extension: 'py',
    details: 'A popular language known for simplicity and versatility.',
    language: python,
    helloWorld: 'print("Hello, World!")',
    command: 'python',
    type: 'interpreted'
  ),
  Language(
    name: 'Javascript',
    extension: 'js',
    details: 'A versatile scripting language for dynamic web development.',
    language: javascript,
    helloWorld: 'console.log("Hello, World!");',
    command: 'node',
    type: 'interpreted'
  ),
  Language(
    name: 'Java',
    extension: 'java',
    details: 'A platform-independent language for enterprise and web apps.',
    language: java,
    helloWorld:'public class HelloWorld{\n  public static void main(String[] args){ \n    System.out.println("Hello, World!");\n  }\n}',
    command: 'javac',
    type: 'compiled'
  ),
  Language(
    name: 'C',
    extension: 'c',
    details:'A powerful, low-level language widely used in system programming.',
    language: cpp,
    helloWorld:'#include <stdio.h> \n\nint main(){\n  printf("Hello, World!n");\n  return 0;\n}',
    command: 'gcc',
    type: 'compiled'
  ),
  Language(
    name: 'C++',
    extension: 'cpp',
    details:
        'A high-performance language used for system programming and games.',
    language: cpp,
    helloWorld:
        '#include <iostream> \n\nint main(){\n  std::cout << "Hello, World!" << std::endl;\n  return 0; }',
    command: 'g++',
    type: 'compiled'
  ),
  Language(
    name: 'HTML',
    extension: 'html',
    details: 'The standard markup language for creating web pages.',
    language: xml,
    helloWorld:'<!DOCTYPE html>\n\n<html>\n <head>\n  <h1>Hello World</h1>\n </head>\n</html>',
  ),
  Language(
    name: 'CSS',
    extension: 'css',
    details: 'Used to style and format web pages.',
    language: css,
    helloWorld: '/* Hello, World! */',
  ),
  Language(
    name: 'Typescript',
    extension: 'ts',
    details: 'A statically typed superset of JavaScript.',
    language: typescript,
    helloWorld: 'console.log("Hello, World!");',
    command: 'ts-node',
    type: 'interpreted'
  ),
  Language(
    name: 'PHP',
    extension: 'php',
    details: 'A server-side language for dynamic web development.',
    language: php,
    helloWorld: '<?php echo "Hello, World!"; ?>',
    command: 'php'
  ),
  Language(
    name: 'SQL',
    extension: 'sql',
    details: 'Used for querying and managing relational databases.',
    language: sql,
    helloWorld: '-- Hello, World!',
  ),
  Language(
    name: 'XML',
    extension: 'xml',
    details: 'Markup language primarily used to store and transport structured data.',
    language: xml,
    helloWorld: '<catalog>\n <book id="1">\n  <title>Learning XML</title>\n  <author>John Doe</author>\n  <price>29.99</price>\n </book>\n</catalog>',
  ),
  Language(
    name: 'Swift',
    extension: 'swift',
    details: 'Apple\'s language for iOS and macOS apps.',
    language: swift,
    helloWorld: 'print("Hello, World!")',
    command: 'swift',
    type: 'compiled'
  ),
  Language(
    name: 'Kotlin',
    extension: 'kt',
    details: 'Modern JVM language, popular for Android development.',
    language: kotlin,
    helloWorld: 'fun main(){\n println("Hello, World!")\n}',
    command: 'kotlinc',
    type: 'compiled'
  ),
  Language(
    name: 'C#',
    extension: 'cs',
    details: 'A modern, object-oriented language for Windows apps and games.',
    language: cs,
    helloWorld:'using System;\n\nclass Program{\n static void Main(){\n  Console.WriteLine("Hello, World!");\n  }\n }',
    command: 'csc',
    type: 'compiled'
  ),
  Language(
    name: 'Rust',
    extension: 'rs',
    details: 'Focused on performance, safety, and concurrency.',
    language: rust,
    helloWorld: 'fn main(){\n println!("Hello, World!");\n}',
    command: 'rustc',
    type: 'compiled'
  ),
  Language(
    name: 'Go',
    extension: 'go',
    details:'Known for simplicity and performance, ideal for concurrent programming.',
    language: go,
    helloWorld:'package main\n\nimport "fmt"\n\nfunc main(){\n fmt.Println("Hello, World!")\n}',
    command: 'go run',
    type: 'compiled'
  ),
  Language(
    name: 'Ruby',
    extension: 'rb',
    details: 'Dynamic language, often used with the Rails framework.',
    language: ruby,
    helloWorld: 'puts "Hello, World!"',
    command: 'ruby',
    type: 'compiled'
  ),
  Language(
    name: 'Dart',
    extension: 'dart',
    details:'Optimized for building fast, multi-platform apps, often with Flutter.',
    language: dart,
    helloWorld: 'void main(){\n print("Hello, World!");\n}',
    command: 'dart',
    type: 'compiled'
  ),
  Language(
    name: 'Json',
    extension: 'json',
    details: 'A lightweight format for data interchange.',
    language: json,
    helloWorld: '{ "hello": "world" }',
  ),
  Language(
    name: 'Markdown',
    extension: 'md',
    details: 'A markup language for formatting plain text.',
    language: markdown,
    helloWorld: '# Hello, World!',
  ),
  Language(
    name: 'Yaml',
    extension: 'yml',
    details: 'A readable data serialization format.',
    language: yaml,
    helloWorld: '# Hello, World!',
  ),
  Language(
    name: 'R',
    extension: 'r',
    details: 'Used for statistical computing and data visualization.',
    language: r,
    helloWorld: 'cat("Hello, World!")',
    type: 'interpreted'
  ),
  Language(
    name: 'Scala',
    extension: 'scala',
    details: 'Combines functional and object-oriented programming.',
    language: scala,
    helloWorld:'object Hello{\n def main(args: Array[String]) = { println("Hello, World!") } \n}',
  ),
  Language(
    name: 'Lua',
    extension: 'lua',
    details: 'A lightweight scripting language often used in game development.',
    language: lua,
    helloWorld: 'print("Hello, World!")',
    type: 'compiled'
  ),
  Language(
    name: 'Bash',
    extension: 'sh',
    details: 'A shell scripting language for automating Unix-based tasks.',
    language: bash,
    helloWorld: 'echo "Hello, World!"',
    command: 'bash',
    type: 'interpreted'
  ),
  Language(
    name: 'Haskell',
    extension: 'hs',
    details: 'A purely functional language with strong static typing.',
    language: haskell,
    helloWorld: 'main = putStrLn "Hello, World!"',
  ),
  Language(
    name: 'Elixir',
    extension: 'ex',
    details: 'A functional language for building scalable applications.',
    language: elixir,
    helloWorld: 'IO.puts "Hello, World!"',
    command: 'elixir'
  ),
  Language(
    name: 'Objective C',
    extension: 'm',
    details: 'Used for macOS and iOS development.',
    language: objectivec,
    helloWorld:'#import <Foundation/Foundation.h> \nint main() {\n NSLog(@"Hello, World!");\n return 0;\n}',
    command: 'gcc',
    type: 'compiled'
  ),
  Language(
    name: 'Fsharp',
    extension: 'fs',
    details: 'A functional-first language for .NET applications.',
    language: fsharp,
    helloWorld: 'printfn "Hello, World!"',
    command: 'mono'
  ),
  Language(
    name: 'Perl',
    extension: 'pl',
    details: 'Known for text processing and system scripting.',
    language: perl,
    helloWorld: 'print "Hello, World!";',
    command:'perl'
  ),
  Language(
    name: 'SCSS',
    extension: 'scss',
    details: 'Enhances CSS with features like variables and nesting.',
    language: scss,
    helloWorld: '/* Hello, World! */',
  ),
  Language(
    name: 'Clojure',
    extension: 'clj',
    details:
        'A functional language running on the JVM, known for immutability.',
    language: clojure,
    helloWorld: '(println "Hello, World!")',
    command: 'lein run'
  ),
  Language(
      name: 'Arduino',
      extension: 'ino',
      details:
          'Used to program Arduino microcontrollers for interactive devices.',
      language: arduino,
      helloWorld:
          'void setup(){\n  Serial.begin(9600);\n} \n\nvoid loop(){\n  Serial.println("Hello, World!");\n  delay(1000);\n}',
      icon: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: SvgPicture.asset(
          'assets/icons/file-type-arduino.svg',
          height: 32.5,
          width: 32.5,
        ),
      )),
  Language(
    name: 'x86 assembly',
    extension: 'asm',
    details: 'Low-level language for x86 processors.',
    language: x86Asm,
    helloWorld:
        'mov eax, 0 \nmov ebx, 4 \nmov ecx, msg \nmov edx, 13 \nint 0x80 \nret \nmsg db "Hello, World!", 0',
  ),
  Language(
    name: 'ARM assembly',
    extension: 's',
    details:
        'Low-level language for ARM processors, common in embedded systems.',
    language: armasm,
    helloWorld:
        '.section .data \nmsg: .asciz "Hello, World!" \n.section .text \n.global _start \n_start: \nldr r0, =msg \nmov r7, #4 \nsvc #0',
  ),
  Language(
    name: 'AVR assembly',
    extension: 'asm',
    details: 'Assembly language for AVR microcontrollers in embedded systems.',
    language: avrasm,
    helloWorld:
        '.section .data \nmsg: .asciz "Hello, World!" \n.section .text \n.global _start \n_start: \nldi r16, low(msg) \nout 0x20, r16 \nldi r16, high(msg) \nout 0x21, r16',
  ),
  Language(
    name: 'Coffeescript',
    extension: 'coffee',
    details: 'Compiles to JavaScript, offering a cleaner syntax.',
    language: coffeescript,
    helloWorld: 'console.log "Hello, World!"',
    command: 'coffee',
    type: 'interpreted'
  ),
];
