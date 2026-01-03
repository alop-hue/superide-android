import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:re_highlight/languages/all.dart';
import 'package:re_highlight/re_highlight.dart';

final txt = Mode();
final unknown = Mode();

class Language {
  final String name, details, helloWorld;
  final List<String> extension;
  final Mode? language;
  final dynamic icon;
  final String? command, type, lspExecutable;
  final List<String>? args;
  Language({
    required this.name,
    required this.extension,
    required this.details,
    required this.language,
    required this.helloWorld,
    this.icon,
    this.command,
    this.type,
    this.lspExecutable,
    this.args
  });
}

class RunTime{
  final String name, details, url, archiveName, parentName;
  final int archiveSize;
  final String? version;
  final dynamic icon;

  RunTime({
    required this.name,
    required this.details,
    required this.archiveName,
    required this.parentName,
    required this.archiveSize,
    required this.url,
    required this.icon,
    this.version
  });
}

class Extension{
  final String name, details, url, archiveName, parentName;
  final List<String> fileExtension, serverFile;
  final double archiveSize;
  final dynamic icon;  
  Extension({
    required this.name,
    required this.details,
    required this.archiveName,
    required this.parentName,
    required this.archiveSize,
    required this.url,
    required this.icon,
    required this.fileExtension,
    required this.serverFile
  });
}

final langtxt = Language(
  name: 'Text File',
  extension: ['txt'],
  details: 'A normal text file.',
  language: txt,
  helloWorld: 'Hello World',
  icon: SvgPicture.asset('assets/material_icons/document.svg',height: 35,width: 35)
);
final langpython = Language(
  name: 'Python',
  extension: ['py'],
  details: 'A popular language known for simplicity and versatility.',
  language: builtinAllLanguages['python'],
  helloWorld: 'print("Hello, World!")',
  command: 'python',
  icon: SvgPicture.asset('assets/material_icons/python.svg',height: 35,width: 35),
  type: 'interpreted',
  lspExecutable: "/data/data/com.vsdroid/bin/node",
  args: ["--stdio"]
);
final langjavascript = Language(
  name: 'Javascript',
  extension: ['js','mjs','cjs'],
  details: 'A versatile scripting language for dynamic web development.',
  language: builtinAllLanguages['javascript'],
  helloWorld: 'console.log("Hello, World!");',
  command: 'node',
  icon: SvgPicture.asset('assets/material_icons/javascript.svg',height: 35,width: 35),
  type: 'interpreted',
  lspExecutable: "/data/data/com.vsdroid/bin/node",
  args: ["--stdio"]
);
final langtypescript = Language(
    name: 'Typescript',
    extension: ['ts','tsx'],
    details: 'A statically typed superset of JavaScript.',
  language: builtinAllLanguages['typescript'],
    helloWorld: 'console.log("Hello, World!");',
    command: 'tsc',
    icon: SvgPicture.asset('assets/material_icons/typescript.svg',height: 35,width: 35),
    type: 'interpreted',
    lspExecutable: "/data/data/com.vsdroid/bin/node",
    args: ["--stdio"]
);
final langjava = Language(
  name: 'Java',
  extension: ['java'],
  details: 'A platform-independent language for enterprise and web apps.',
  language: builtinAllLanguages['java'],
  helloWorld:'public class tempCode{\n  public static void main(String[] args){ \n    System.out.println("Hello, World!");\n  }\n}',
  icon: SvgPicture.asset('assets/material_icons/java.svg',height: 35,width: 35),
  command: 'javac',
  type: 'compiled',
  // lspExecutable: "/data/data/com.vsdroid/bin/java",
);
final langc = Language(
  name: 'C',
  extension: ['c'],
  details:'A powerful, low-level language widely used in system programming.',
  language: builtinAllLanguages['c'],
  helloWorld:'#include <stdio.h> \n\nint main(){\n  printf("Hello, World!n");\n  return 0;\n}',
  command: 'clang',
  icon: SvgPicture.asset('assets/material_icons/c.svg',height: 35,width: 35),
  type: 'compiled',
  lspExecutable: "/data/data/com.vsdroid/bin/ccls",
);
final langcpp = Language(
  name: 'C++',
  extension: ['cpp','c++','cc'],
  details:'A high-performance language used for system programming and games.',
  language: builtinAllLanguages['cpp'],
  helloWorld:'#include <iostream> \n\nint main(){\n  std::cout << "Hello, World!" << std::endl;\n  return 0; }',
  command: 'clang++',
  icon: SvgPicture.asset('assets/material_icons/cpp.svg',height: 35,width: 35),
  type: 'compiled',
  lspExecutable: "/data/data/com.vsdroid/bin/ccls",
);
final langdart = Language(
  name: 'Dart',
  extension: ['dart'],
  details:'Optimized for building fast, multi-platform apps, often with Flutter.',
  language: builtinAllLanguages['dart'],
  helloWorld: 'void main(){\n print("Hello, World!");\n}',
  command: 'dart',
  type: 'compiled(no binary)',
  icon: SvgPicture.asset('assets/material_icons/dart.svg',height: 35,width: 35),
);
final langhtml = Language(
  name: 'HTML',
  extension: ['html','htm'],
  details: 'The standard markup language for creating web pages.',
  language: builtinAllLanguages['xml'],
  helloWorld:'''
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="UTF-8"> 
              <meta name="viewport" content="width=device-width initial-scale=1.0">
              <meta http-equiv="X-UA-Compatible" content="ie=edge">
            </head>
            <body>
              <h1>Hello World</h1>
            </body>
            </html>''',
  icon: SvgPicture.asset('assets/material_icons/html.svg',height: 35,width: 35),
  args: ["--stdio"],
  lspExecutable: "/data/data/com.vsdroid/bin/node",
);
final langcss = Language(
  name: 'CSS',
  extension: ['css'],
  details: 'Used to style and format web pages.',
  language: builtinAllLanguages['css'],
  helloWorld: '/* Hello, World! */',
  lspExecutable: "/data/data/com.vsdroid/bin/node",
  args: ["--stdio"],
  icon: SvgPicture.asset('assets/material_icons/css.svg',height: 35,width: 35),
);
final langscss = Language(
  name: 'SCSS',
  extension: ['scss'],
  details: 'Enhances CSS with features like variables and nesting.',
  language: builtinAllLanguages['scss'],
  helloWorld: '/* Hello, World! */',
  icon: SvgPicture.asset('assets/material_icons/sass.svg',height:35,width:35),
);
final langless = Language(
  name: 'Less',
  extension: ['less'],
  details: 'A CSS pre-processor with a more dynamic syntax.',
  language: builtinAllLanguages['less'],
  helloWorld: '/* Hello, World! */',
  icon: SvgPicture.asset('assets/material_icons/less.svg',height: 35,width: 35),
);
final langphp = Language(
    name: 'PHP',
    extension: ['php'],
    details: 'A server-side language for dynamic web development.',
    language: builtinAllLanguages['php'],
    helloWorld: '<?php echo "Hello, World!"; ?>',
    icon: SvgPicture.asset('assets/material_icons/php.svg',height: 35,width: 35),
    command: 'php');
final langsql = Language(
  name: 'SQL',
  extension: ['sql'],
  details: 'Used for querying and managing relational databases.',
  language: builtinAllLanguages['sql'],
  icon: SvgPicture.asset('assets/material_icons/database.svg',height: 35,width: 35),
  helloWorld: '-- Hello, World!',
);
final langxml = Language(
  name: 'XML',
  extension: ['xml'],
  details:'Markup language primarily used to store and transport structured data.',
  language: builtinAllLanguages['xml'],
  icon: SvgPicture.asset('assets/material_icons/xml.svg',height: 35,width: 35),
  helloWorld:'<catalog>\n <book id="1">\n  <title>Learning XML</title>\n  <author>John Doe</author>\n  <price>29.99</price>\n </book>\n</catalog>',
);
final langswift = Language(
  name: 'Swift',
  extension: ['swift'],
  details: 'Apple\'s language for iOS and macOS apps.',
  language: builtinAllLanguages['swift'],
  helloWorld: 'print("Hello, World!")',
  command: 'swift',
  icon: SvgPicture.asset('assets/material_icons/swift.svg',height: 35,width: 35),
  type: 'compiled'
);
final langkotlin = Language(
  name: 'Kotlin',
  extension: ['kt'],
  details: 'Modern JVM language, popular for Android development.',
  language: builtinAllLanguages['kotlin'],
  helloWorld: 'fun main(){\n println("Hello, World!")\n}',
  command: 'kotlinc',
  icon: SvgPicture.asset('assets/material_icons/kotlin.svg',height: 35,width: 35),
  type: 'compiled'
);
final langcsharp = Language(
  name: 'C#',
  extension: ['cs'],
  details: 'A modern, object-oriented language for Windows apps and games.',
  language: builtinAllLanguages['csharp'],
  helloWorld:'using System;\n\nclass Program{\n static void Main(){\n  Console.WriteLine("Hello, World!");\n  }\n }',
  command: 'csc',
  icon: SvgPicture.asset('assets/material_icons/csharp.svg',height: 35,width: 35),
  type: 'compiled'
);
final langrust = Language(
  name: 'Rust',
  extension: ['rs'],
  details: 'Focused on performance, safety, and concurrency.',
  language: builtinAllLanguages['rust'],
  helloWorld: 'fn main(){\n println!("Hello, World!");\n}',
  command: 'rustc',
  icon: SvgPicture.asset('assets/material_icons/rust.svg',height: 35,width: 35),
  type: 'compiled'
);
final langgo = Language(
  name: 'Go',
  extension: ['go'],
  details:'Known for simplicity and performance, ideal for concurrent programming.',
  language: builtinAllLanguages['go'],
  helloWorld:'package main\n\nimport "fmt"\n\nfunc main(){\n fmt.Println("Hello, World!")\n}',
  command: 'go run',
  icon: SvgPicture.asset('assets/material_icons/go_gopher.svg',height: 35,width: 35),
  type: 'compiled(no binary)'
);
final langruby = Language(
  name: 'Ruby',
  extension: ['rb'],
  details: 'Dynamic language, often used with the Rails framework.',
  language: builtinAllLanguages['ruby'],
  helloWorld: 'puts "Hello, World!"',
  command: 'ruby',
  icon: SvgPicture.asset('assets/material_icons/ruby.svg',height: 35,width: 35),
  type: 'compiled(no binary)'
);
final langjson = Language(
  name: 'Json',
  extension: ['json'],
  details: 'A lightweight format for data interchange.',
  language: builtinAllLanguages['json'],
  icon: SvgPicture.asset('assets/material_icons/json.svg',height: 35,width: 35),
  lspExecutable: "/data/data/com.vsdroid/bin/node",
  args: ["--stdio"],
  helloWorld: '{ "hello": "world" }',
);
final langmarkdown = Language(
  name: 'Markdown',
  extension: ['md'],
  details: 'A markup language for formatting plain text.',
  language: builtinAllLanguages['markdown'],
  lspExecutable: "/data/data/com.vsdroid/bin/node",
  args: ["--stdio"],
  icon: SvgPicture.asset('assets/material_icons/markdown.svg',height: 35,width: 35),
  helloWorld: '# Hello, World!',
);
final langyaml = Language(
  name: 'Yaml',
  extension: ['yml','yaml'],
  details: 'A readable data serialization format.',
  language: builtinAllLanguages['yaml'],
  icon: SvgPicture.asset('assets/material_icons/yaml.svg',height: 35,width: 35),
  helloWorld: '# Hello, World!',
);
final langr = Language(
  name: 'R',
  extension: ['r'],
  details: 'Used for statistical computing and data visualization.',
  language: builtinAllLanguages['r'],
  icon: SvgPicture.asset('assets/material_icons/r.svg',height: 35,width: 35),
  helloWorld: 'cat("Hello, World!")',
  type: 'interpreted'
);
final langscala = Language(
  name: 'Scala',
  extension: ['scala'],
  details: 'Combines functional and object-oriented programming.',
  language: builtinAllLanguages['scala'],
  command: 'scalac',
  icon: SvgPicture.asset('assets/material_icons/scala.svg',height: 35,width: 35),
  helloWorld:'object Hello{\n def main(args: Array[String]) = {\n  println("Hello, World!")  \n} \n}',
  type: 'compiled'
);
final langlua = Language(
  name: 'Lua',
  extension: ['lua'],
  details:'A lightweight scripting language often used in game development.',
  language: builtinAllLanguages['lua'],
  command: 'lua',
  icon: SvgPicture.asset('assets/material_icons/lua.svg',height: 35,width: 35),
  helloWorld: 'print("Hello, World!")',
  type: 'compiled(no binary)'
);
final langbash = Language(
  name: 'Bash',
  extension: ['sh','bash'],
  details: 'A shell scripting language for automating Unix-based tasks.',
  language: builtinAllLanguages['bash'],
  helloWorld: 'echo "Hello, World!"',
  command: 'bash',
  icon: SvgPicture.asset('assets/material_icons/console.svg',height: 35,width: 35),
  type: 'interpreted'
);
final langhaskell = Language(
  name: 'Haskell',
  extension: ['hs'],
  details: 'A purely functional language with strong static typing.',
  language: builtinAllLanguages['haskell'],
  helloWorld: 'main = putStrLn "Hello, World!"',
  icon: SvgPicture.asset('assets/material_icons/haskell.svg',height: 35,width: 35),
);
final langelixir = Language(
  name: 'Elixir',
  extension: ['ex','exs'],
  details: 'A functional language for building scalable applications.',
  language: builtinAllLanguages['elixir'],
  helloWorld: 'IO.puts "Hello, World!"',
  command: 'elixir',
  type: 'compiled(no binary)',
  icon: SvgPicture.asset('assets/material_icons/elixir.svg',height: 35,width: 35),
);
final langobjectivec = Language(
  name: 'Objective C',
  extension: ['m','mm'],
  details: 'Used for macOS and iOS development.',
  language: builtinAllLanguages['objectivec'],
  helloWorld:'#import <Foundation/Foundation.h> \nint main() {\n NSLog(@"Hello, World!");\n return 0;\n}',
  command: 'gcc',
  icon: SvgPicture.asset('assets/material_icons/objective-c.svg',height: 35,width: 35),
  type: 'compiled'
);
final langfsharp = Language(
  name: 'Fsharp',
  extension: ['fsx','fs'],
  details: 'A functional-first language for .NET applications.',
  language: builtinAllLanguages['fsharp'],
  helloWorld: 'printfn "Hello, World!"',
  command: 'mono',
  type: 'compiled',
  icon: SvgPicture.asset('assets/material_icons/fsharp.svg',height: 35,width: 35),
);
final langperl = Language(
  name: 'Perl',
  extension: ['pl'],
  details: 'Known for text processing and system scripting.',
  language: builtinAllLanguages['perl'],
  helloWorld: 'print "Hello, World!";',
  command: 'perl',
  type: 'interpreted',
  icon: SvgPicture.asset('assets/material_icons/perl.svg',height: 35,width: 35),
); 
final langclojure = Language(
  name: 'Clojure',
  extension: ['clj','cljs'],
  details:'A functional language running on the JVM, known for immutability.',
  language: builtinAllLanguages['clojure'],
  helloWorld: '(println "Hello, World!")',
  command: 'lein run',
  icon: SvgPicture.asset('assets/material_icons/clojure.svg',height: 35,width: 35),
);
final langarduino = Language(
  name: 'Arduino',
  extension: ['ino'],
  details:
      'Used to program Arduino microcontrollers for interactive devices.',
  language: builtinAllLanguages['arduino'],
  helloWorld:
      'void setup(){\n  Serial.begin(9600);\n} \n\nvoid loop(){\n  Serial.println("Hello, World!");\n  delay(1000);\n}',
  icon: SvgPicture.asset(
    'assets/icons/file-type-arduino.svg',
    height: 35,
    width: 35,
  )
);
final langx86asm = Language(
  name: 'x86 assembly',
  extension: ['asm'],
  details: 'Low-level language for x86 processors.',
  language: builtinAllLanguages['x86asm'],
  helloWorld:'mov eax, 0 \nmov ebx, 4 \nmov ecx, msg \nmov edx, 13 \nint 0x80 \nret \nmsg db "Hello, World!", 0',
  icon: SvgPicture.asset('assets/material_icons/assembly.svg',height: 35,width: 35),
);
final langarmasm = Language(
  name: 'ARM assembly',
  extension: ['s','S'],
  details:'Low-level language for ARM processors, common in embedded systems.',
  language: builtinAllLanguages['armasm'],
  helloWorld:'.section .data \nmsg: .asciz "Hello, World!" \n.section .text \n.global _start \n_start: \nldr r0, =msg \nmov r7, #4 \nsvc #0',
  icon: SvgPicture.asset('assets/material_icons/assembly.svg',height: 35,width: 35),
);
final langavrasm = Language(
  name: 'AVR assembly',
  extension: ['asm'],
  details: 'Assembly language for AVR microcontrollers in embedded systems.',
  language: builtinAllLanguages['avrasm'],
  helloWorld:'.section .data \nmsg: .asciz "Hello, World!" \n.section .text \n.global _start \n_start: \nldi r16, low(msg) \nout 0x20, r16 \nldi r16, high(msg) \nout 0x21, r16',
  icon: SvgPicture.asset('assets/material_icons/assembly.svg',height: 35,width: 35),
);
final langcoffeescript = Language(
    name: 'Coffeescript',
  extension: ['coffee'],
    details: 'Compiles to JavaScript, offering a cleaner syntax.',
    language: builtinAllLanguages['coffeescript'],
    helloWorld: 'console.log "Hello, World!"',
    command: 'coffee',
    type: 'interpreted');
final langaccesslog = Language(
  name: 'Access Log',
  extension: ['log'],
  details: 'Common format for logging web server requests.',
  language: builtinAllLanguages['accesslog'],
  helloWorld: '# Placeholder for Hello, World!',
  icon: SvgPicture.asset('assets/material_icons/log.svg',height: 35,width: 35),
);
final langada = Language(
  name: 'Ada',
  extension: ['ada'],
  details: 'A structured, statically typed, high-level language.',
  language: builtinAllLanguages['ada'],
  helloWorld: 'with Ada.Text_IO; use Ada.Text_IO;\nbegin\n  Put_Line("Hello, World!");\nend;',
  icon: SvgPicture.asset('assets/material_icons/ada.svg',height: 35,width: 35),
);
final langangelscript = Language(
  name: 'AngelScript',
  extension: ['as'],
  details: 'A scripting language designed for game development.',
  language: builtinAllLanguages['angelscript'],
  helloWorld: 'void main() {\n print("Hello, World!");\n}',
  icon: SvgPicture.asset(
    'assets/material_icons/angelscript.svg',
    height: 40,
    width: 40,
    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)
  ),
);
final langbrainfuck = Language(
  name: 'Brainfuck',
  extension: ['bf'],
  details: 'A minimalist, esoteric programming language.',
  language: builtinAllLanguages['brainfuck'],
  helloWorld: '++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+<<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.',
  icon: SvgPicture.asset('assets/material_icons/brainfuck.svg',height: 35,width: 35),
);
final langcmake = Language(
  name: 'CMake',
  extension: ['cmake'],
  details: 'Cross-platform build system.',
  language: builtinAllLanguages['cmake'],
  helloWorld: '# Placeholder for Hello, World!',
  icon: SvgPicture.asset('assets/material_icons/cmake.svg',height: 35,width: 35),
);
final langd = Language(
  name: 'D',
  extension: ['d'],
  details: 'A system programming language with C-like syntax and features.',
  language: builtinAllLanguages['d'],
  helloWorld: 'import std.stdio; void main() { writeln("Hello, World!"); }',
  icon: SvgPicture.asset('assets/material_icons/d.svg',height: 35,width: 35),
);
final langerlang = Language(
  name: 'Erlang',
  extension: ['erl'],
  details: 'A language for building scalable, fault-tolerant systems.',
  language: builtinAllLanguages['erlang'],
  helloWorld: 'io:format("Hello, World!~n").',
  icon: SvgPicture.asset('assets/material_icons/erlang.svg',height: 35,width: 35),
);
final langfortran = Language(
  name: 'Fortran',
  extension: ['f90'],
  details: 'A language for numerical and scientific computing.',
  language: builtinAllLanguages['fortran'],
  helloWorld: 'program hello\n  print *, "Hello, World!"\nend program hello',
  icon: SvgPicture.asset('assets/material_icons/fortran.svg',height: 35,width: 35),
);
final langgradle = Language(
  name: 'Gradle',
  extension: ['gradle'],
  details: 'Configuration file used for Android development.',
  language: builtinAllLanguages['gradle'],
  helloWorld: 'program hello\n  print *, "Hello, World!"\nend program hello',
  icon: SvgPicture.asset('assets/material_icons/gradle.svg',height: 35,width: 35),
);
final langgroovy = Language(
  name: 'Groovy',
  extension: ['groovy'],
  details: 'A language for the JVM with dynamic and static features.',
  language: builtinAllLanguages['groovy'],
  helloWorld: 'println "Hello, World!"',
  icon: SvgPicture.asset('assets/material_icons/groovy.svg',height: 35,width: 35),
);
final langjulia = Language(
  name: 'Julia',
  extension: ['jl'],
  details: 'A high-performance language for technical computing.',
  language: builtinAllLanguages['julia'],
  helloWorld: 'println("Hello, World!")',
  icon: SvgPicture.asset('assets/material_icons/julia.svg',height: 35,width: 35),
);
final langlisp = Language(
  name: 'Lisp',
  extension: ['lisp'],
  details: 'A family of functional, symbolic programming languages.',
  language: builtinAllLanguages['lisp'],
  helloWorld: '(print "Hello, World!")',
  icon: SvgPicture.asset('assets/material_icons/lisp.svg',height: 35,width: 35),
);
final langverilog = Language(
  name: 'Verilog',
  extension: ['v'],
  details: 'A hardware description language used in digital design.',
  language: builtinAllLanguages['verilog'],
  helloWorld: 'module hello;\ninitial begin\n  \$display("Hello, World!");\nend\nendmodule',
  icon: SvgPicture.asset('assets/material_icons/verilog.svg',height: 35,width: 35),
);

List<Language> languages = [
  langtxt,
  langpython,
  langjavascript,
  langtypescript,
  langjava,
  langc,
  langcpp,
  langdart,
  langhtml,
  langcss,
  langkotlin,
  langrust,
  langgo,
  langcsharp,
  langscss,
  langless,
  langphp,
  langsql,
  langxml,
  langswift,
  langruby,
  langjson,
  langmarkdown,
  langyaml,
  langr,
  langscala,
  langlua,
  langbash,
  langhaskell,
  langelixir,
  langobjectivec,
  langfsharp,
  langperl,
  langclojure,
  langarduino,
  langx86asm,
  langarmasm,
  langavrasm,
  langcoffeescript,
  langaccesslog,
  langada,
  langangelscript,
  langbrainfuck,
  langcmake,
  langd,
  langerlang,
  langfortran,
  langgradle,
  langgroovy,
  langjulia,
  langlisp,
  langverilog,
];

final pythonRunTime = RunTime(
  name: "Python",
  details: "The python interpreter.\nDownload the based-pyright extension for LSP support.",
  version: "3.13.5",
  url: "https://github.com/heckmon/android-arm64-shared-libraries/releases/download/v0.0.1/python.zip",
  archiveName: "python.zip",
  archiveSize: 78,
  parentName: "python",
  icon: SvgPicture.asset('assets/material_icons/python.svg',height: 35, width: 35),
);

final nodeRunTime = RunTime(
  name: "Node JS",
  details: "The node js runtime.\nTypescript runtime and LSP server are included with this bundle.",
  version: "24.4.1",
  url: "https://github.com/heckmon/android-arm64-shared-libraries/releases/download/v0.0.1/node.zip",
  archiveName: "node.zip",
  archiveSize: 51,
  parentName: "node",
  icon: SvgPicture.asset('assets/material_icons/nodejs.svg',height: 35, width: 35),
);

final clangRunTime = RunTime(
  name: "Clang",
  details: "The clang compiler for C/C++. CCLS Language server is included with this bundle",
  version: "21.1.8",
  url: "https://github.com/heckmon/android-arm64-shared-libraries/releases/download/v0.0.1/clang.zip",
  archiveName: "clang.zip",
  archiveSize: 86,
  parentName: "clang",
  icon: SvgPicture.asset('assets/icons/LLVM.svg',height: 35, width: 35),
);

final java17RunTime = RunTime(
  name: "OpenJDK",
  details: "The Java Virtual Machine.",
  version: "21",
  archiveSize: 135,
  url: "https://github.com/heckmon/android-arm64-shared-libraries/releases/download/v0.0.1/java-21-openjdk.zip",
  archiveName: "java-21-openjdk.zip",
  parentName: "java-21-openjdk",
  icon: SvgPicture.asset('assets/icons/Java.svg',height: 35, width: 35)
);

final kotlinRunTime = RunTime(
  name: "Kotlin",
  details: "The Kotlin runtime.\nNote: OpenJDK installation is required",
  archiveName: "kotlin.zip",
  parentName: "kotlin",
  archiveSize: 74,
  version: "2.2.0",
  url: "https://github.com/heckmon/android-arm64-shared-libraries/releases/download/v0.0.1/kotlin.zip",
  icon: SvgPicture.asset('assets/material_icons/kotlin.svg',height: 35, width: 35)
);

final rubyRunTime = RunTime(
  name: "Ruby",
  details: "The Ruby interpreter.",
  version: "3.4.1",
  url: "https://github.com/heckmon/android-arm64-shared-libraries/releases/download/v0.0.1/ruby.zip",
  parentName: "ruby",
  archiveName: "ruby.zip",
  archiveSize: 12,
  icon: SvgPicture.asset('assets/material_icons/ruby.svg',height: 35,width: 35)
);

final monoRunTime = RunTime(
  name: "Mono",
  details: "The Mono runtime for C# and F#.",
  version: "6.12.0",
  url: "https://github.com/heckmon/android-arm64-shared-libraries/releases/download/v0.0.1/mono.zip",
  archiveName: "mono.zip",
  archiveSize: 16,
  parentName: "mono",
  icon: SvgPicture.asset('assets/material_icons/csharp.svg',height: 35,width: 35)
);

final List<RunTime> runtimes = [
  pythonRunTime,
  nodeRunTime,
  clangRunTime,
  java17RunTime,
  kotlinRunTime,
  rubyRunTime,
  monoRunTime
];

final basedpyright = Extension(
  name: "Based-Pyright",
  details: "Langauge server for python.\nNote: Node JS runtime is required.",
  archiveName: "basedpyright.zip",
  parentName: "basedpyright",
  archiveSize: 8.4,
  url: "https://github.com/heckmon/android-arm64-shared-libraries/releases/download/v0.0.1/basedpyright.zip",
  icon: Image.asset("assets/icons/based_pyright_logo.png"),
  fileExtension: ["py"],
  serverFile: ["/data/data/com.vsdroid/extensions/basedpyright/langserver.index.js"]
);

final vscodeExtractedLSPs = Extension(
  name: "VScode-extracted LSP Servers",
  details: "Language servers extracted from the VSCode. Contains HTML, CSS, Markdown, JSON and ESLint servers\nNote: Node JS runtime is required.",
  archiveName: "vscode-langservers-extracted.zip",
  parentName: "vscode-langservers-extracted",
  archiveSize: 14,
  url: "https://github.com/heckmon/android-arm64-shared-libraries/releases/download/v0.0.1/vscode-langservers-extracted.zip",
  icon: Image.asset("assets/icons/html-css.png"),
  fileExtension: ["html", "css", "md", "json"],
  serverFile: [
    "/data/data/com.vsdroid/extensions/vscode-langservers-extracted/node_modules/vscode-langservers-extracted/lib/html-language-server/node/htmlServerMain.js",
    "/data/data/com.vsdroid/extensions/vscode-langservers-extracted/node_modules/vscode-langservers-extracted/lib/css-language-server/node/cssServerMain.js",
    "/data/data/com.vsdroid/extensions/vscode-langservers-extracted/node_modules/vscode-langservers-extracted/lib/json-language-server/node/jsonServerMain.js",
    "/data/data/com.vsdroid/extensions/vscode-langservers-extracted/node_modules/vscode-langservers-extracted/lib/markdown-language-server/node/main.js",
    "/data/data/com.vsdroid/extensions/vscode-langservers-extracted/node_modules/vscode-langservers-extracted/lib/eslint-language-server/eslintServer.js",
  ]
);

final List<Extension> extensions = [
  basedpyright,
  vscodeExtractedLSPs
];