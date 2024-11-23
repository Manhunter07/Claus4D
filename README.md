# Claus4D
Definition file importer, processor and exporter for Paradox Interactive's Clausewitz game engine

## What does this library do?
Claus4D (_"Clausewitz for Delphi"_) is a library I wrote some years ago (in 2021) to parse, modify and process definition files for Paradox Interactive's Clausewitz game engine, used in many of its current, recent and likely future games. It's tested on Stellaris game files, but should work as well on other game files like those of _Europa Universalis_, _Crusader Kings_ and _Hearts of Iron_.

## Which language features are supported?
The library supports the parsing of most common features. These include:
* Constructors (including nested constructors)
* Comments (both line and in-line comments)
* Values
   * Numbers (both interger and floating-point)
   * Dates
   * Colors (both RGB and hex)
   * Strings (quoted, unquoted or automatically-quoted)
* Collections (including nested collections)

## What is it good for?
You can parse, mofify and save game files for a variety of Paradox games in your Pascal/Delphi application using a fully-functional DOM. There are no external dependencies and the library compiles on any current Delphi version. It hasn't been tested, but should also run with FPC.

## How to get started?
1.  Make sure you include the `Claus` unit file in the uses-clause:
    ```pas
    uses
      {...} Claus;
    ```
2.  Declare a `TClausFile` variable:
    ```pas
    var
      {...}
      ClausFile: TClausFile;
    ```
3.  To load a Clausewitz definition file, use the `CreateFromFile` constructor:
    ```pas
      ClausFile := TClausFile.CreateFromFile('...');
    ```
    It takes the file path as argumment and reads the entire file in.
4.  You can now edit the DOM tree view the `Values` property. This is the root node and gives you access to all values of the document:
    ```pas
      (ClausFile.Values[0] as TClausTextValue).Value := '...';
    ```
    Each value type has its own class declared. You can access their values via the `Value` property.
    Values, constructors (key-value pairs) or collections (value groups) can be inserted, changed or deleted.
6.  To save the modified file, use the `SaveToFile` procedure:
    ```pas
      ClausFile.SaveToFile('...');
    ```
    It takes the file path as argumment.

## What is missing?
There are obviously a lot of edge-cases missing in this library. Some of which include variables, some edge-cases and typed objects. There are definitely a few scenarios where the parser wrongly throws an exception on valid code or where code is interpreted incorrectly. If you feel like there is something specifically missing, please create an issue or a pull request.
