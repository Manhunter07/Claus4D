unit Claus;

////////////////////////////////////////////////////////////////////////////////
///  Clausewitz engine definition file importer, processor and exporter      ///
///  ----------------------------------------------------------------------  ///
///  This unit allows the import, export and in-memory manipulation of       ///
///  definition files for Paradox Interactive's Clausewitz engine in Delphi  ///
///  10, 11 and 12. Although it supports most syntax elements, there are     ///
///  still ocasions when this library fails to load. Also, it should only    ///
///  used for automated output because it does not print out comments or     ///
///  empty lines. Use at your own risk.                                      ///
///                                                                          ///
///  Written by Dennis Göhlert                                               ///
///  Licensed under Mozilla Public License (MPL) 2.0                         ///
////////////////////////////////////////////////////////////////////////////////

interface

uses
  System.SysUtils, System.Classes, System.UITypes, System.Generics.Collections;

type
  EClausValueException = class(Exception);

  TClausHierarchyAllowance = (haParent, haChildren);

  TClausStrings = class(TStringList)
  public
    /// <summary>
    ///   Creates a string list with Unix line breaks, UTF-8 encoding and no trailing line break
    /// </summary>
    constructor Create;
    /// <summary>
    ///   Indentates a string with "#9"
    /// </summary>
    procedure Indent(const AIndex: Integer);
  end;

  TClausValueClass = class of TClausValue;

  TClausValue = class abstract
  private class var
    FValueClasses: TList<TClausValueClass>;
  private
    FParent: TClausValue;
  protected
    class procedure ParseWhitespaces(const ACode: String; var AIndex: Integer);
    class function Allowed(const AAllowance: TClausHierarchyAllowance): Boolean; virtual;
    class function Parse(const ACode: String; var AIndex: Integer): TClausValue; virtual;
    procedure Insert(const AValue: TClausValue); virtual;
  public
    class constructor Create;
    class destructor Destroy;
    /// <summary>
    ///   The parent value if nested ("nil" for the root)
    /// </summary>
    property Parent: TClausValue read FParent;
    /// <summary>
    ///   Registers a value class for parsing
    /// </summary>
    class procedure RegisterValueClass(const AClass: TClausValueClass);
    /// <summary>
    ///   Unregisters a value class for parsing
    /// </summary>
    class procedure UnregisterValueClass(const AClass: TClausValueClass);
    /// <summary>
    ///   Returns the value as a string
    /// </summary>
    function ToString: String; override; abstract;
  end;

  TClausNumberValue = class abstract(TClausValue)
  protected
    class function Parse(const ACode: String; var AIndex: Integer): TClausValue; override;
  end;

  TClausIntegerValue = class(TClausNumberValue)
  private
    FValue: Int64;
  public
    /// <summary>
    ///   The numeric (integer) value
    /// </summary>
    property Value: Int64 read FValue write FValue;
    /// <summary>
    ///   Creates a new number value with a (integer) number as value
    /// </summary>
    constructor Create(const AValue: Int64);
    /// <summary>
    ///   Returns the number as a string
    /// </summary>
    function ToString: String; override;
  end;

  TClausFloatValue = class(TClausNumberValue)
  private
    FValue: Single;
  public
    /// <summary>
    ///   The numeric (floating-point) value
    /// </summary>
    property Value: Single read FValue write FValue;
    /// <summary>
    ///   Creates a new number value with a (floating-point) number as value
    /// </summary>
    constructor Create(const AValue: Single);
    /// <summary>
    ///   Returns the number as a string
    /// </summary>
    function ToString: String; override;
  end;

  TClausDateValue = class(TClausNumberValue)
  private
    FValue: TDate;
  public
    /// <summary>
    ///   The (encoded) date value
    /// </summary>
    property Value: TDate read FValue write FValue;
    /// <summary>
    ///   Creates a new date value with an encoded date as value
    /// </summary>
    constructor Create(const AValue: TDate);
    /// <summary>
    ///   Returns the number as a string
    /// </summary>
    function ToString: String; override;
  end;

  TClausColorNotation = (cnRGB, cnHex);

  TClausColorValue = class(TClausValue)
  private
    FValue: TColor;
    FNotation: TClausColorNotation;
  protected
    class function Parse(const ACode: String; var AIndex: Integer): TClausValue; override;
    class function Color(const ARed, AGreen, ABlue: Byte): TColor;
  public
    /// <summary>
    ///   The (encoded) color value
    /// </summary>
    property Value: TColor read FValue write FValue;
    /// <summary>
    ///   The color notation used for the export
    /// </summary>
    property Notation: TClausColorNotation read FNotation write FNotation nodefault;
    /// <summary>
    ///   Creates a new color value with an encoded color and a notation
    /// </summary>
    constructor Create(const AValue: TColor; ANotation: TClausColorNotation);
    /// <summary>
    ///   Returns the color as an RGB or hex string
    /// </summary>
    function ToString: String; override;
  end;

  TClausTextQuotation = (tqQuoted, tqUnquoted, tqAutomatic);

  TClausTextValue = class(TClausValue)
  private
    FValue: String;
    FQuotation: TClausTextQuotation;
    procedure SetValue(const AValue: String);
  protected
    class function Parse(const ACode: String; var AIndex: Integer): TClausValue; override;
  public
    /// <summary>
    ///   The (unquoted) string value
    /// </summary>
    property Value: String read FValue write SetValue;
    /// <summary>
    ///   The kind of quotation method used for the export
    /// </summary>
    property Quotation: TClausTextQuotation read FQuotation write FQuotation default tqAutomatic;
    /// <summary>
    ///   Creates a new text value with a string as value and an optional custom quotation method
    /// </summary>
    constructor Create(const AValue: String; const AQuotation: TClausTextQuotation = tqAutomatic);
    /// <summary>
    ///   Returns the text as a quoted or unquoted string
    /// </summary>
    function ToString: String; override;
  end;

  TClausValues = class abstract(TClausValue)
  private
    FValues: TObjectList<TClausValue>;
    function GetValues(const AIndex: Integer): TClausValue;
    procedure SetValues(const AIndex: Integer; const AValue: TClausValue);
    function GetCount: Integer;
    function GetAsArray: TArray<TClausValue>;
    procedure SetAsArray(const AValue: TArray<TClausValue>);
    function GetContainsAny(const AValueClass: TClausValueClass): Boolean;
    function GetContainsOnly(const AValueClass: TClausValueClass): Boolean;
  protected
    class function Allowed(const AAllowance: TClausHierarchyAllowance): Boolean; override;
  public
    /// <summary>
    ///   The sub values
    /// </summary>
    property Values[const AIndex: Integer]: TClausValue read GetValues write SetValues; default;
    /// <summary>
    ///   The amount of sub values
    /// </summary>
    property Count: Integer read GetCount;
    /// <summary>
    ///   The sub values as a dynamic array
    /// </summary>
    property AsArray: TArray<TClausValue> read GetAsArray write SetAsArray;
    /// <summary>
    ///   There are sub values of this type
    /// </summary>
    property ContainsAny[const AValueClass: TClausValueClass]: Boolean read GetContainsAny;
    /// <summary>
    ///   There are only sub values of this type
    /// </summary>
    property ContainsOnly[const AValueClass: TClausValueClass]: Boolean read GetContainsOnly;
    /// <summary>
    ///   Creates a new parent value with sub values
    /// </summary>
    constructor Create(const AValues: TArray<TClausValue>);
    destructor Destroy; override;
    /// <summary>
    ///   Returns the sub values as a list
    /// </summary>
    function ToString: String; override;
    /// <summary>
    ///   Adds a new sub value
    /// </summary>
    procedure Add(const AValue: TClausValue); overload;
    /// <summary>
    ///   Adds a new sub value
    /// </summary>
    procedure Add(const AValue: TClausValue; const AIndex: Integer); overload;
    /// <summary>
    ///   Deletes a sub value
    /// </summary>
    procedure Delete(const AIndex: Integer); overload;
    /// <summary>
    ///   Deletes a sub value
    /// </summary>
    procedure Delete(const AValue: TClausValue); overload;
    /// <summary>
    ///   Deletes all sub values
    /// </summary>
    procedure Clear;
    /// <summary>
    ///   Exchanges the positions of two sub values
    /// </summary>
    procedure Exchange(const AFirstIndex, ASecondIndex: Integer); overload;
    /// <summary>
    ///   Exchanges the positions of two sub values
    /// </summary>
    procedure Exchange(const AFirstValue, ASecondValue: TClausValue); overload;
    /// <summary>
    ///   Returns the index of a sub value
    /// </summary>
    function Find(const AValue: TClausValue): Integer;
    function GetEnumerator: TEnumerator<TClausValue>;
  end;

  TClausConstructor = class;

  TClausValuesHelper = class helper for TClausValues
  private
    function GetAsColor: TClausColorValue;
    function GetConstructors(const AName: String): TArray<TClausConstructor>;
    function GetConstructorCount(const AName: String): Integer;
  protected
    function ConstructorHasName(const AConstructor: TClausConstructor; const AName: String): Boolean;
  public
    /// <summary>
    ///   The sub values interpreted as an RGB group
    /// </summary>
    property AsColor: TClausColorValue read GetAsColor;
    /// <summary>
    ///   All sub values that are constructors with a certain name
    /// </summary>
    property Constructors[const AName: String]: TArray<TClausConstructor> read GetConstructors;
    /// <summary>
    ///   The amount of all sub values that are constructors with a certain name
    /// </summary>
    property ConstructorCount[const AName: String]: Integer read GetConstructorCount;
    /// <summary>
    ///   Deletes all sub values that are constructors with a certain name
    /// </summary>
    procedure DeleteConstructors(const AName: String = String.Empty);
  end;

  TClausRootValue = class(TClausValues)
  protected
    class function Allowed(const AAllowance: TClausHierarchyAllowance): Boolean; override;
    class function Parse(const ACode: String): TClausRootValue; reintroduce;
  public
    /// <summary>
    ///   Creates an empty root value for a tree
    /// </summary>
    constructor Create;
  end;

  TClausGroupValue = class(TClausValues)
  protected
    class function Parse(const ACode: String; var AIndex: Integer): TClausValue; override;
  public
    /// <summary>
    ///   Returns the sub values as a list, surrounded with braces
    /// </summary>
    function ToString: String; override;
  end;

  TClausConstructor = class(TClausValue)
  private
    FName: TClausTextValue;
    FValue: TClausValue;
    procedure SetName(const AValue: TClausTextValue);
    procedure SetValue(const AValue: TClausValue);
  protected
    class function Allowed(const AAllowance: TClausHierarchyAllowance): Boolean; override;
    class function Parse(const APrevious: TClausValue; const ACode: String; var AIndex: Integer): TClausConstructor; reintroduce;
  public
    /// <summary>
    ///   The text value that stands in front of the equal sign
    /// </summary>
    property Name: TClausTextValue read FName write SetName;
    /// <summary>
    ///   The generic value that stands after the equal sign
    /// </summary>
    property Value: TClausValue read FValue write SetValue;
    /// <summary>
    ///   Creates a constructor value with a text value as name and a generic value as value
    /// </summary>
    constructor Create(const AName: TClausTextValue; const AValue: TClausValue); overload;
    destructor Destroy; override;
    /// <summary>
    ///   Returns the constructor name and its value
    /// </summary>
    function ToString: String; override;
  end;

  TClausFile = class
  private
    FValues: TClausValues;
  public
    property Values: TClausValues read FValues;
    /// <summary>
    ///   Creates a tree based on the code input
    /// </summary>
    constructor Create(const ACode: String = String.Empty);
    destructor Destroy; override;
    /// <summary>
    ///   Returns all values as a parsable code string
    /// </summary>
    function ToString: String; override;
    function GetEnumerator: TEnumerator<TClausValue>;
  end;

  TClausFileHelper = class helper for TClausFile
  public
    /// <summary>
    ///   Creates a tree that is loaded from a file
    /// </summary>
    constructor CreateFromFile(const AFileName: String);
    /// <summary>
    ///   Saves the tree as a parsable string
    /// </summary>
    procedure SaveToFile(const AFileName: String);
  end;

implementation

{ TClausStrings }

constructor TClausStrings.Create;
begin
  LineBreak := #10;
  TrailingLineBreak := False;
  DefaultEncoding := TEncoding.UTF8;
end;

procedure TClausStrings.Indent(const AIndex: Integer);
begin
  Self[AIndex] := Concat(#9, Self[AIndex]);
end;

{ TClausValue }

class function TClausValue.Allowed(const AAllowance: TClausHierarchyAllowance): Boolean;
const
  LAllowed: array [TClausHierarchyAllowance] of Boolean = (True, False);
begin
  Result := LAllowed[AAllowance];
end;

class constructor TClausValue.Create;
begin
  FValueClasses := TList<TClausValueClass>.Create;
end;

class destructor TClausValue.Destroy;
begin
  FValueClasses.Free;
end;

procedure TClausValue.Insert(const AValue: TClausValue);
begin
  if not Allowed(haChildren) then
  begin
    raise EClausValueException.Create('Value does not support children');
  end;
  if not AValue.Allowed(haParent) then
  begin
    raise EClausValueException.Create('Value does not support parents');
  end;
  AValue.FParent := Self;
end;

class function TClausValue.Parse(const ACode: String; var AIndex: Integer): TClausValue;
var
  LValueClass: TClausValueClass;
  LConstructor: TClausConstructor;
begin
  Result := nil;
  for LValueClass in FValueClasses do
  begin
    Result := LValueClass.Parse(ACode, AIndex);
    if Assigned(Result) then
    begin
      Break;
    end;
  end;
  if Assigned(Result) then
  begin
    ParseWhitespaces(ACode, AIndex);
    LConstructor := TClausConstructor.Parse(Result, ACode, AIndex);
    if Assigned(LConstructor) then
    begin
      Result := LConstructor;
      ParseWhitespaces(ACode, AIndex);
    end;
  end;
end;

class procedure TClausValue.ParseWhitespaces(const ACode: String; var AIndex: Integer);

  procedure ParseComment;
  begin
    Inc(AIndex);
    while AIndex < Length(ACode) do
    begin
      if ACode.Chars[AIndex] = #10 then
      begin
        Break;
      end;
      Inc(AIndex);
    end;
  end;

begin
  while (AIndex < Length(ACode)) and CharInSet(ACode.Chars[AIndex], ['#', #9, #10, #13, #32]) do
  begin
    if ACode.Chars[AIndex] = '#' then
    begin
      ParseComment;
    end;
    Inc(AIndex);
  end;
end;

class procedure TClausValue.RegisterValueClass(const AClass: TClausValueClass);
begin
  FValueClasses.Add(AClass);
end;

class procedure TClausValue.UnregisterValueClass(const AClass: TClausValueClass);
begin
  FValueClasses.Remove(AClass);
end;

{ TClausNumberValue }

class function TClausNumberValue.Parse(const ACode: String; var AIndex: Integer): TClausValue;

  function DateFromString(const AString: String): TDate;
  var
    LParts: TArray<String>;
  begin
    LParts := AString.Split(['.']);
    Result := EncodeDate(LParts[0].ToInteger, LParts[1].ToInteger, LParts[2].ToInteger);
  end;

var
  LBuilder: TStringBuilder;
begin
  if CharInSet(ACode.Chars[AIndex], ['0' .. '9']) then
  begin
    LBuilder := TStringBuilder.Create;
    try
      while (AIndex < Length(ACode)) and CharInSet(ACode.Chars[AIndex], ['0' .. '9']) do
      begin
        LBuilder.Append(ACode.Chars[AIndex]);
        Inc(AIndex);
      end;
      if ACode.Chars[AIndex] = '.' then
      begin
        LBuilder.Append(ACode.Chars[AIndex]);
        Inc(AIndex);
        while (AIndex < Length(ACode)) and CharInSet(ACode.Chars[AIndex], ['0' .. '9']) do
        begin
          LBuilder.Append(ACode.Chars[AIndex]);
          Inc(AIndex);
        end;
        if ACode.Chars[AIndex] = '.' then
        begin
          LBuilder.Append(ACode.Chars[AIndex]);
          Inc(AIndex);
          while (AIndex < Length(ACode)) and CharInSet(ACode.Chars[AIndex], ['0' .. '9']) do
          begin
            LBuilder.Append(ACode.Chars[AIndex]);
            Inc(AIndex);
          end;
          Result := TClausDateValue.Create(DateFromString(LBuilder.ToString));
        end else
        begin
          Result := TClausFloatValue.Create(LBuilder.ToString.ToSingle);
        end;
      end else
      begin
        Result := TClausIntegerValue.Create(LBuilder.ToString.ToInt64);
      end;
    finally
      LBuilder.Free;
    end;
  end else
  begin
    Result := nil;
  end;
end;

{ TClausIntegerValue }

constructor TClausIntegerValue.Create(const AValue: Int64);
begin
  inherited Create;
  Value := AValue;
end;

function TClausIntegerValue.ToString: String;
begin
  Result := Value.ToString;
end;

{ TClausFloatValue }

constructor TClausFloatValue.Create(const AValue: Single);
begin
  inherited Create;
  Value := AValue;
end;

function TClausFloatValue.ToString: String;
begin
  Result := Value.ToString;
end;

{ TClausDateValue }

constructor TClausDateValue.Create(const AValue: TDate);
begin
  inherited Create;
  Value := AValue;
end;

function TClausDateValue.ToString: String;
var
  LYear: Word;
  LMonth: Word;
  LDay: Word;
begin
  DecodeDate(Value, LYear, LMonth, LDay);
  Result := String.Join('.', [LYear.ToString, LMonth, LDay]);
end;

{ TClausColorValue }

class function TClausColorValue.Color(const ARed, AGreen, ABlue: Byte): TColor;
begin
  Result := TColors.Null;
  TColorRec(Result).R := ARed;
  TColorRec(Result).G := AGreen;
  TColorRec(Result).B := ABlue;
end;

constructor TClausColorValue.Create(const AValue: TColor; ANotation: TClausColorNotation);
begin
  inherited Create;
  Value := AValue;
  Notation := ANotation;
end;

class function TClausColorValue.Parse(const ACode: String; var AIndex: Integer): TClausValue;
var
  LBuilder: TStringBuilder;
  LRGB: TBytes;
begin
  //We can only parse hex numbers here.
  //RGB-collections are parsed as a TClausValues object.
  //This can be converted into a TClausColorValue object using TClausValuesHelper.AsColor.
  if ACode.StartsWith('0x', True) then
  begin
    Inc(AIndex, 2);
    LBuilder := TStringBuilder.Create(6);
    try
      while (AIndex < ACode.Length) and CharInSet(ACode.Chars[AIndex], ['A' .. 'F', 'a' .. 'z', '0' .. '9']) do
      begin
        LBuilder.Append(ACode.Chars[AIndex]);
      end;
      LRGB := TBytes(Concat(HexDisplayPrefix, LBuilder.ToString).ToInteger);
    finally
      LBuilder.Free;
    end;
    Result := TClausColorValue.Create(Color(LRGB[0], LRGB[1], LRGB[2]), cnHex);
  end else
  begin
    Result := nil;
  end;
end;

function TClausColorValue.ToString: String;

  function GroupString(const AValues: TArray<TClausValue>): String;
  var
    LGroup: TClausGroupValue;
  begin
    LGroup := TClausGroupValue.Create(AValues);
    try
      Result := LGroup.ToString;
    finally
      LGroup.Free;
    end;
  end;

begin
  case Notation of
    cnRGB:
      begin
        Result := GroupString([TClausIntegerValue.Create(TColorRec(Value).R), TClausIntegerValue.Create(TColorRec(Value).G), TClausIntegerValue.Create(TColorRec(Value).B)]);
      end;
    cnHex:
      begin
        Result := String.Format('0x%2x%2x%2x', [TColorRec(Value).R, TColorRec(Value).G, TColorRec(Value).B]);
      end;
  end;
end;

{ TClausTextValue }

constructor TClausTextValue.Create(const AValue: String; const AQuotation: TClausTextQuotation = tqAutomatic);
begin
  inherited Create;
  Value := AValue;
  Quotation := AQuotation;
end;

class function TClausTextValue.Parse(const ACode: String; var AIndex: Integer): TClausValue;
var
  LQuoted: Boolean;
  LBuilder: TStringBuilder;
begin
  LQuoted := ACode.Chars[AIndex] = '"';
  if LQuoted then
  begin
    Inc(AIndex);
  end;
  if LQuoted or CharInSet(ACode.Chars[AIndex], ['A' .. 'Z', 'a' .. 'z', '_']) then
  begin
    LBuilder := TStringBuilder.Create;
    try
      while (AIndex < ACode.Length) and (LQuoted or CharInSet(ACode.Chars[AIndex], ['A' .. 'Z', 'a' .. 'z', '0' .. '9', '_', '-'])) do
      begin
        if LQuoted then
        begin
          if ACode.Chars[AIndex] = '"' then
          begin
            Inc(AIndex);
            LQuoted := False;
            Break;
          end;
          if ACode.Chars[AIndex] = '\' then
          begin
            Inc(AIndex);
            if (AIndex >= ACode.Length) or not CharInSet(ACode.Chars[AIndex], ['=', '\']) then
            begin
              raise EClausValueException.Create('Invalid escape sequence');
            end;
          end;
        end;
        LBuilder.Append(ACode.Chars[AIndex]);
        Inc(AIndex);
      end;
      if LQuoted then
      begin
        raise EClausValueException.Create('String must be terminated');
      end;
      Result := TClausTextValue.Create(LBuilder.ToString);
    finally
      LBuilder.Free;
    end;
  end else
  begin
    Result := nil;
  end;
end;

procedure TClausTextValue.SetValue(const AValue: String);
begin
  if AValue.StartsWith('"') and (Quotation = tqUnquoted) then
  begin
    raise EClausValueException.Create('Unquoted strings must not start with double quotes');
  end;
  FValue := AValue;
end;

function TClausTextValue.ToString: String;

  function RequiresQuotes(const AString: String): Boolean;
  var
    LChar: Char;
  begin
    Result := AString.IsEmpty or not CharInSet(AString.Chars[0], ['A' .. 'Z', 'a' .. 'z', '_']);
    if not Result then
    begin
      for LChar in AString do
      begin
        if not CharInSet(LChar, ['A' .. 'Z', 'a' .. 'z', '0' .. '9', '_', '-']) then
        begin
          Exit(True);
        end;
      end;
    end;
  end;

  function Escape(const AString: String): String;
  var
    LBuilder: TStringBuilder;
    LChar: Char;
  begin
    LBuilder := TStringBuilder.Create;
    try
      for LChar in AString do
      begin
        if CharInSet(LChar, ['=', '\']) then
        begin
          LBuilder.Append('\');
        end;
        LBuilder.Append(LChar);
      end;
      Result := LBuilder.ToString;
    finally
      LBuilder.Free;
    end;
  end;

var
  LRequiresQuotes: Boolean;
begin
  LRequiresQuotes := RequiresQuotes(Value);
  if LRequiresQuotes and (Quotation = tqUnquoted) then
  begin
    raise EClausValueException.Create('Unquoted text values must not contain whitespaces');
  end;
  if (Quotation = tqQuoted) or (Quotation = tqAutomatic) and LRequiresQuotes then
  begin
    Result := Escape(Value).QuotedString('"');
  end else
  begin
    Result := Value;
  end;
end;

{ TClausValues }

procedure TClausValues.Add(const AValue: TClausValue);
begin
  FValues.Add(AValue);
  Insert(AValue);
end;

procedure TClausValues.Add(const AValue: TClausValue; const AIndex: Integer);
begin
  FValues.Insert(AIndex, AValue);
  Insert(AValue);
end;

class function TClausValues.Allowed(const AAllowance: TClausHierarchyAllowance): Boolean;
const
  LAllowed: array [TClausHierarchyAllowance] of Boolean = (True, True);
begin
  Result := LAllowed[AAllowance];
end;

procedure TClausValues.Clear;
begin
  FValues.Clear;
end;

constructor TClausValues.Create(const AValues: TArray<TClausValue>);
begin
  inherited Create;
  FValues := TObjectList<TClausValue>.Create(True);
  FValues.AddRange(AValues);
end;

procedure TClausValues.Delete(const AIndex: Integer);
begin
  FValues.Delete(AIndex);
end;

procedure TClausValues.Delete(const AValue: TClausValue);
begin
  FValues.Remove(AValue);
end;

destructor TClausValues.Destroy;
begin
  FValues.Free;
  inherited;
end;

procedure TClausValues.Exchange(const AFirstValue, ASecondValue: TClausValue);
begin
  FValues.Exchange(Find(AFirstValue), Find(ASecondValue));
end;

procedure TClausValues.Exchange(const AFirstIndex, ASecondIndex: Integer);
begin
  FValues.Exchange(AFirstIndex, ASecondIndex);
end;

function TClausValues.Find(const AValue: TClausValue): Integer;
begin
  Result := FValues.IndexOf(AValue);
end;

function TClausValues.GetAsArray: TArray<TClausValue>;
begin
  Result := FValues.ToArray;
end;

function TClausValues.GetContainsAny(const AValueClass: TClausValueClass): Boolean;
var
  LValue: TClausValue;
begin
  for LValue in Self do
  begin
    if LValue is AValueClass then
    begin
      Exit(True);
    end;
  end;
  Result := False;
end;

function TClausValues.GetContainsOnly(const AValueClass: TClausValueClass): Boolean;
var
  LValue: TClausValue;
begin
  for LValue in Self do
  begin
    if not (LValue is AValueClass) then
    begin
      Exit(False);
    end;
  end;
  Result := True;
end;

function TClausValues.GetCount: Integer;
begin
  Result := FValues.Count;
end;

function TClausValues.GetEnumerator: TEnumerator<TClausValue>;
begin
  Result := FValues.GetEnumerator;
end;

function TClausValues.GetValues(const AIndex: Integer): TClausValue;
begin
  Result := FValues[AIndex];
end;

procedure TClausValues.SetAsArray(const AValue: TArray<TClausValue>);
begin
  Clear;
  FValues.AddRange(AValue);
end;

procedure TClausValues.SetValues(const AIndex: Integer; const AValue: TClausValue);
begin
  FValues.Items[AIndex] := AValue;
end;

function TClausValues.ToString: String;
var
  LResult: TStrings;
  LValue: TClausValue;
begin
  LResult := TClausStrings.Create;
  try
    for LValue in Self do
    begin
      LResult.Add(LValue.ToString);
    end;
    Result := LResult.Text;
  finally
    LResult.Free;
  end;
end;

{ TClausValuesHelper }

function TClausValuesHelper.ConstructorHasName(const AConstructor: TClausConstructor; const AName: String): Boolean;
begin
  Result := AName.IsEmpty or SameText(AConstructor.Name.Value, AName);
end;

procedure TClausValuesHelper.DeleteConstructors(const AName: String);
var
  LConstructor: TClausConstructor;
begin
  for LConstructor in Constructors[AName] do
  begin
    Delete(LConstructor);
  end;
end;

function TClausValuesHelper.GetAsColor: TClausColorValue;
begin
  if (Count = 3) and (ContainsOnly[TClausNumberValue]) then
  begin
    Result := TClausColorValue.Create(TClausColorValue.Color((Self[0] as TClausIntegerValue).Value, (Self[1] as TClausIntegerValue).Value, (Self[2] as TClausIntegerValue).Value), cnRGB);
  end else
  begin
    Result := nil;
  end;
end;

function TClausValuesHelper.GetConstructorCount(const AName: String): Integer;
var
  LValue: TClausValue;
begin
  Result := 0;
  for LValue in Self do
  begin
    if (LValue is TClausConstructor) and ConstructorHasName(LValue as TClausConstructor, AName) then
    begin
      Inc(Result);
    end;
  end;
end;

function TClausValuesHelper.GetConstructors(const AName: String): TArray<TClausConstructor>;
var
  LResult: TObjectList<TClausConstructor>;
  LValue: TClausValue;
begin
  LResult := TObjectList<TClausConstructor>.Create(False);
  try
    for LValue in Self do
    begin
      if (LValue is TClausConstructor) and ConstructorHasName(LValue as TClausConstructor, AName) then
      begin
        LResult.Add(LValue as TClausConstructor);
      end;
    end;
    Result := LResult.ToArray;
  finally
    LResult.Free;
  end;
end;

{ TClausGroupValue }

class function TClausGroupValue.Parse(const ACode: String; var AIndex: Integer): TClausValue;
var
  LValue: TClausValue;
begin
  if ACode.Chars[AIndex] = '{' then
  begin
    Inc(AIndex);
    Result := TClausGroupValue.Create([]);
    ParseWhitespaces(ACode, AIndex);
    repeat
      if AIndex >= Length(ACode) then
      begin
        raise EClausValueException.Create('Value group must be terminated');
      end;
      LValue := TClausValue.Parse(ACode, AIndex);
      if Assigned(LValue) then
      begin
        (Result as TClausGroupValue).Add(LValue);
      end else
      begin
        if ACode.Chars[AIndex] <> '}' then
        begin
          raise EClausValueException.Create('Token must be a value');
        end;
      end;
    until ACode.Chars[AIndex] = '}';
    Inc(AIndex);
  end else
  begin
    Result := nil;
  end;
end;

function TClausGroupValue.ToString: String;

  procedure Indent(const AStrings: TStrings);
  var
    LIndex: Integer;
  begin
    for LIndex := 0 to Pred(AStrings.Count) do
    begin
      (AStrings as TClausStrings).Indent(LIndex);
    end;
  end;

var
  LResult: TStrings;
begin
  LResult := TClausStrings.Create;
  try
    LResult.Text := inherited ToString;
    Indent(LResult);
    LResult.Insert(0, '{');
    LResult.Add('}');
    Result := LResult.Text;
  finally
    LResult.Free;
  end;
end;

{ TClausRootValue }

class function TClausRootValue.Allowed(const AAllowance: TClausHierarchyAllowance): Boolean;
const
  LAllowed: array [TClausHierarchyAllowance] of Boolean = (False, True);
begin
  Result := LAllowed[AAllowance];
end;

constructor TClausRootValue.Create;
begin
  inherited Create([]);
end;

class function TClausRootValue.Parse(const ACode: String): TClausRootValue;
var
  LIndex: Integer;
  LValue: TClausValue;
begin
  Result := TClausRootValue.Create;
  LIndex := 0;
  ParseWhitespaces(ACode, LIndex);
  if LIndex < Length(ACode) then
  begin
    repeat
      LValue := TClausValue.Parse(ACode, LIndex);
      if Assigned(LValue) then
      begin
        (Result as TClausRootValue).Add(LValue);
      end else
      begin
        raise EClausValueException.Create('Token must be a value');
      end;
    until (LIndex >= Length(ACode));
  end;
end;

{ TClausConstructor }

class function TClausConstructor.Allowed(const AAllowance: TClausHierarchyAllowance): Boolean;
const
  LAllowed: array [TClausHierarchyAllowance] of Boolean = (True, True);
begin
  Result := LAllowed[AAllowance];
end;

destructor TClausConstructor.Destroy;
begin
  Value.Free;
  Name.Free;
  inherited;
end;

class function TClausConstructor.Parse(const APrevious: TClausValue; const ACode: String; var AIndex: Integer): TClausConstructor;
var
  LValue: TClausValue;
begin
  if (APrevious is TClausTextValue) and (ACode.Chars[AIndex] = '=') then
  begin
    Inc(AIndex);
    ParseWhitespaces(ACode, AIndex);
    LValue := TClausValue.Parse(ACode, AIndex);
    Result := TClausConstructor.Create(APrevious as TClausTextValue, LValue);
  end else
  begin
    Result := nil;
  end;
end;

procedure TClausConstructor.SetName(const AValue: TClausTextValue);
begin
  FName := AValue;
  Insert(Name);
end;

procedure TClausConstructor.SetValue(const AValue: TClausValue);
begin
  FValue := AValue;
  Insert(Value);
end;

function TClausConstructor.ToString: String;
begin
  Result := String.Format('%s = %s', [Name.ToString, Value.ToString]);
end;

constructor TClausConstructor.Create(const AName: TClausTextValue; const AValue: TClausValue);
begin
  inherited Create;
  Name := AName;
  Value := AValue;
end;

{ TClausFile }

constructor TClausFile.Create(const ACode: String = String.Empty);
begin
  inherited Create;
  FValues := TClausRootValue.Parse(ACode);
end;

destructor TClausFile.Destroy;
begin
  FValues.Free;
  inherited;
end;

function TClausFile.GetEnumerator: TEnumerator<TClausValue>;
begin
  Result := Values.GetEnumerator;
end;

function TClausFile.ToString: String;
begin
  Result := Values.ToString;
end;

{ TClausFileHelper }

constructor TClausFileHelper.CreateFromFile(const AFileName: String);
var
  LLines: TStrings;
begin
  LLines := TClausStrings.Create;
  try
    LLines.LoadFromFile(AFileName);
    inherited Create(LLines.Text);
  finally
    LLines.Free;
  end;
end;

procedure TClausFileHelper.SaveToFile(const AFileName: String);
var
  LLines: TStrings;
begin
  LLines := TClausStrings.Create;
  try
    LLines.Text := ToString;
    LLines.SaveToFile(AFileName);
  finally
    LLines.Free;
  end;
end;

initialization
  TClausValue.RegisterValueClass(TClausNumberValue);
  TClausValue.RegisterValueClass(TClausColorValue);
  TClausValue.RegisterValueClass(TClausTextValue);
  TClausValue.RegisterValueClass(TClausGroupValue);

end.