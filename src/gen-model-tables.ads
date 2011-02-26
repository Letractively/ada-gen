-----------------------------------------------------------------------
--  gen-model-tables -- Database table model representation
--  Copyright (C) 2009, 2010 Stephane Carrez
--  Written by Stephane Carrez (Stephane.Carrez@gmail.com)
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.
-----------------------------------------------------------------------
with EL.Objects;

with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Strings.Unbounded;
with Ada.Strings.Unbounded.Hash;
with Gen.Model.List;
package Gen.Model.Tables is

   use Ada.Strings.Unbounded;

   --  ------------------------------
   --  Column Definition
   --  ------------------------------
   type Column_Definition is new Definition with private;
   type Column_Definition_Access is access all Column_Definition'Class;

   --  Get the value identified by the name.
   --  If the name cannot be found, the method should return the Null object.
   overriding
   function Get_Value (From : Column_Definition;
                       Name : String) return EL.Objects.Object;

   --  ------------------------------
   --  Table Definition
   --  ------------------------------
   type Table_Definition is new Definition with private;
   type Table_Definition_Access is access all Table_Definition'Class;

   --  Get the value identified by the name.
   --  If the name cannot be found, the method should return the Null object.
   overriding
   function Get_Value (From : Table_Definition;
                       Name : String) return EL.Objects.Object;

   --  Register all the columns defined in the table
   procedure Register_Columns (Table : in out Table_Definition);

   --  ------------------------------
   --  Package Definition
   --  ------------------------------
   type Package_Definition is new Definition with private;
   type Package_Definition_Access is access all Package_Definition'Class;

   --  Get the value identified by the name.
   --  If the name cannot be found, the method should return the Null object.
   overriding
   function Get_Value (From : Package_Definition;
                       Name : String) return EL.Objects.Object;

   --  ------------------------------
   --  Model Definition
   --  ------------------------------
   --  The <b>Model_Definition</b> contains the complete model from one or
   --  several files.
   type Model_Definition is new Definition with private;
   type Model_Definition_Access is access all Model_Definition'Class;

   --  Get the value identified by the name.
   --  If the name cannot be found, the method should return the Null object.
   overriding
   function Get_Value (From : Model_Definition;
                       Name : String) return EL.Objects.Object;

   procedure Initialize (O : in out Model_Definition;
                         N : in DOM.Core.Node);

   --  Register or find the package knowing its name
   procedure Register_Package (O      : in out Model_Definition;
                               Name   : in Unbounded_String;
                               Result : out Package_Definition_Access);

   --  Register a new class definition in the model.
   procedure Register_Class (O    : in out Model_Definition;
                             Node : in DOM.Core.Node);

   package Package_Map is
     new Ada.Containers.Indefinite_Hashed_Maps (Key_Type        => Unbounded_String,
                                                Element_Type    => Package_Definition_Access,
                                                Hash            => Ada.Strings.Unbounded.Hash,
                                                Equivalent_Keys => "=");

   subtype Package_Cursor is Package_Map.Cursor;

   --  Get the first package of the model definition.
   function First (From : Model_Definition) return Package_Cursor;

   --  Returns true if the package cursor contains a valid package
   function Has_Element (Position : Package_Cursor) return Boolean
     renames Package_Map.Has_Element;

   --  Returns the package definition.
   function Element (Position : Package_Cursor) return Package_Definition_Access
     renames Package_Map.Element;

   --  Move the iterator to the next package definition.
   procedure Next (Position : in out Package_Cursor)
     renames Package_Map.Next;

--     function Find_Class (From : Model_Definition;
--                          Name : String) return Table_Definition;


   package Table_Map is
     new Ada.Containers.Indefinite_Hashed_Maps (Key_Type        => Unbounded_String,
                                                Element_Type    => Table_Definition_Access,
                                                Hash            => Ada.Strings.Unbounded.Hash,
                                                Equivalent_Keys => "=");

   subtype Table_Cursor is Table_Map.Cursor;

   --  Returns true if the table cursor contains a valid table
   function Has_Element (Position : Table_Cursor) return Boolean
     renames Table_Map.Has_Element;

   --  Returns the table definition.
   function Element (Position : Table_Cursor) return Table_Definition_Access
     renames Table_Map.Element;

   --  Move the iterator to the next table definition.
   procedure Next (Position : in out Table_Cursor)
     renames Table_Map.Next;

--     function Find_Class (From : Model_Definition;
--                          Name : String) return Table_Definition;

private

   type Column_Definition is new Definition with record
      Number : Natural := 0;
      Table  : Table_Definition_Access;

      --  Whether the column must not be null in the database
      Not_Null : Boolean := False;

      --  Whether the column must be unique
      Unique   : Boolean := False;

      --  The column type name.
      Type_Name : Unbounded_String;

      --  The SQL type associated with the column.
      Sql_Type : Unbounded_String;

      --  The SQL name associated with the column.
      Sql_Name : Unbounded_String;

      --  True if this column is the optimistic locking version column.
      Is_Version : Boolean := False;

      --  True if this column is the primary key column.
      Is_Key : Boolean := False;
   end record;

   package Column_List is new Gen.Model.List (T         => Column_Definition,
                                              T_Access  => Column_Definition_Access);

   procedure Initialize (O : in out Table_Definition);

   type Table_Definition is new Definition with record
      Members        : aliased Column_List.List_Definition;
      Members_Bean   : EL.Objects.Object;
      Parent         : Table_Definition_Access;
      Package_Def    : Package_Definition_Access;
      Name           : Unbounded_String;
      Type_Name      : Unbounded_String;
      Pkg_Name       : Unbounded_String;
      Version_Column : Column_Definition_Access;
      Id_Column      : Column_Definition_Access;
   end record;

   package Table_List is new Gen.Model.List (T        => Table_Definition,
                                             T_Access => Table_Definition_Access);

   type Package_Definition is new Definition with record
      Tables      : aliased Table_List.List_Definition;
      Tables_Bean : EL.Objects.Object;
      Pkg_Name    : Unbounded_String;
      Name        : Unbounded_String;
      Base_Name   : Unbounded_String;
   end record;

   type Model_Definition is new Definition with record
      Tables      : aliased Table_List.List_Definition;
      Tables_Bean : EL.Objects.Object;
      Packages    : Package_Map.Map;
   end record;

end Gen.Model.Tables;
