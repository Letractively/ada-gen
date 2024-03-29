-----------------------------------------------------------------------
--  gen-model-packages -- Packages holding model, query representation
--  Copyright (C) 2009, 2010, 2011, 2012, 2013, 2014 Stephane Carrez
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

with Ada.Strings;
with Ada.Strings.Maps;

with Gen.Utils;
with Gen.Model.Enums;
with Gen.Model.Tables;
with Gen.Model.Queries;
with Gen.Model.Beans;

with Util.Strings;
with Util.Strings.Transforms;
with Util.Log.Loggers;
package body Gen.Model.Packages is

   use type DOM.Core.Node;
   use Util.Log;

   Log : constant Loggers.Logger := Loggers.Create ("Gen.Model.Packages");

   --  ------------------------------
   --  Get the value identified by the name.
   --  If the name cannot be found, the method should return the Null object.
   --  ------------------------------
   overriding
   function Get_Value (From : in Package_Definition;
                       Name : in String) return Util.Beans.Objects.Object is
   begin
      if Name = "name" then
         return Util.Beans.Objects.To_Object (From.Name);

      elsif Name = "package" then
         return Util.Beans.Objects.To_Object (From.Base_Name);

      elsif Name = "tables" then
         return From.Tables_Bean;

      elsif Name = "enums" then
         return From.Enums_Bean;

      elsif Name = "queries" then
         return From.Queries_Bean;

      elsif Name = "beans" then
         return From.Beans_Bean;

      elsif Name = "usedTypes" then
         return From.Used;

      elsif Name = "useCalendarTime" then
         return Util.Beans.Objects.To_Object (From.Uses_Calendar_Time);

      else
         return Definition (From).Get_Value (Name);
      end if;
   end Get_Value;

   --  ------------------------------
   --  Find the type identified by the name.
   --  ------------------------------
   function Find_Type (From : in Package_Definition;
                       Name : in Unbounded_String)
                       return Gen.Model.Mappings.Mapping_Definition_Access is
      Pos : Mappings.Cursor;
   begin
      if Index (Name, ".") > 0 then
         Pos := From.Types.Find (Name);
         if not Mappings.Mapping_Maps.Has_Element (Pos) then
            return From.Model.Find_Type (Name);
         end if;
      else
         Pos := From.Types.Find (From.Name & "." & Name);
      end if;
      if Mappings.Mapping_Maps.Has_Element (Pos) then
         return Mappings.Mapping_Maps.Element (Pos);
      else
         return null;
      end if;
   end Find_Type;

   --  ------------------------------
   --  Get the model which contains all the package definitions.
   --  ------------------------------
   function Get_Model (From : in Package_Definition)
                       return Model_Definition_Access is
   begin
      return From.Model;
   end Get_Model;

   --  ------------------------------
   --  Returns True if the package is a pre-defined package and must not be generated.
   --  ------------------------------
   function Is_Predefined (From : in Package_Definition) return Boolean is
   begin
      return From.Is_Predefined;
   end Is_Predefined;

   --  ------------------------------
   --  Set the package as a pre-defined package.
   --  ------------------------------
   procedure Set_Predefined (From : in out Package_Definition) is
   begin
      From.Is_Predefined := True;
   end Set_Predefined;

   --  ------------------------------
   --  Register the declaration of the given enum in the model.
   --  ------------------------------
   procedure Register_Enum (O      : in out Model_Definition;
                            Enum   : access Gen.Model.Enums.Enum_Definition'Class) is
      Name : constant String := Enum.Get_Name;
   begin
      Log.Info ("Registering enum {0}", Name);

      O.Register_Package (Enum.Pkg_Name, Enum.Package_Def);
      if Enum.Package_Def.Enums.Find (Name) /= null then
         raise Name_Exist with "Enum '" & Name & "' already defined";
      end if;
      Enum.Package_Def.Enums.Append (Enum.all'Access);
      Enum.Package_Def.Types.Include (Enum.Name, Enum.all'Access);
      O.Enums.Append (Enum.all'Access);
      Gen.Model.Mappings.Register_Type (To_String (Enum.Name), Enum.all'Access,
                                        Gen.Model.Mappings.T_ENUM);
   end Register_Enum;

   --  ------------------------------
   --  Register the declaration of the given table in the model.
   --  ------------------------------
   procedure Register_Table (O     : in out Model_Definition;
                             Table : access Gen.Model.Tables.Table_Definition'Class) is
      Name           : constant String := Table.Get_Name;
   begin
      Log.Info ("Registering table {0}", Name);

      O.Register_Package (Table.Pkg_Name, Table.Package_Def);
      if Table.Package_Def.Tables.Find (Name) /= null then
         raise Name_Exist with "Table '" & Name & "' already defined";
      end if;
      Table.Package_Def.Tables.Append (Table.all'Access);
      Table.Package_Def.Types.Include (Table.Name, Table.all'Access);
      if O.Is_Generation_Enabled (Ada.Strings.Unbounded.To_String (Table.Pkg_Name)) then
         O.Tables.Append (Table.all'Access);
      end if;
   end Register_Table;

   --  ------------------------------
   --  Register the declaration of the given query in the model.
   --  ------------------------------
   procedure Register_Query (O     : in out Model_Definition;
                             Table : access Gen.Model.Queries.Query_File_Definition'Class) is
   begin
      O.Register_Package (Table.Pkg_Name, Table.Package_Def);
      Table.Package_Def.Queries.Append (Table.all'Access);
      O.Queries.Append (Table.all'Access);
   end Register_Query;

   --  ------------------------------
   --  Register the declaration of the given bean in the model.
   --  ------------------------------
   procedure Register_Bean (O     : in out Model_Definition;
                            Bean  : access Gen.Model.Beans.Bean_Definition'Class) is
   begin
      O.Register_Package (Bean.Pkg_Name, Bean.Package_Def);
      Bean.Package_Def.Beans.Append (Bean.all'Access);
      Bean.Package_Def.Types.Include (Bean.Name, Bean.all'Access);
      O.Queries.Append (Bean.all'Access);
   end Register_Bean;

   --  ------------------------------
   --  Register or find the package knowing its name
   --  ------------------------------
   procedure Register_Package (O      : in out Model_Definition;
                               Name   : in Unbounded_String;
                               Result : out Package_Definition_Access) is
      Pkg : constant String := Util.Strings.Transforms.To_Upper_Case (To_String (Name));
      Key : constant Unbounded_String := To_Unbounded_String (Pkg);
      Pos : constant Package_Map.Cursor := O.Packages.Find (Key);
   begin
      if not Package_Map.Has_Element (Pos) then
         declare
            Map : Ada.Strings.Maps.Character_Mapping;
            Base_Name : Unbounded_String;
         begin
            Map := Ada.Strings.Maps.To_Mapping (From => ".", To => "-");
            Base_Name := Translate (Name, Map);

            Result := new Package_Definition;
            Result.Name  := Name;
            Result.Model := O'Unchecked_Access;
            Result.Tables_Bean := Util.Beans.Objects.To_Object (Result.Tables'Access,
                                                                Util.Beans.Objects.STATIC);
            Util.Strings.Transforms.To_Lower_Case (To_String (Base_Name),
                                                   Result.Base_Name);
            O.Packages.Insert (Key, Result);
            Log.Debug ("Ada package '{0}' registered", Name);
         end;
      else
         Result := Package_Map.Element (Pos);
      end if;
   end Register_Package;

   --  ------------------------------
   --  Returns True if the model contains at least one package.
   --  ------------------------------
   function Has_Packages (O : in Model_Definition) return Boolean is
   begin
      return not O.Packages.Is_Empty;
   end Has_Packages;

   --  ------------------------------
   --  Enable the generation of the Ada package given by the name.  By default all the Ada
   --  packages found in the model are generated.  When called, this enables the generation
   --  only for the Ada packages registered here.
   --  ------------------------------
   procedure Enable_Package_Generation (Model : in out Model_Definition;
                                        Name  : in String) is
   begin
      Model.Gen_Packages.Include (Util.Strings.Transforms.To_Upper_Case (Name));
   end Enable_Package_Generation;

   --  ------------------------------
   --  Returns True if the generation is enabled for the given package name.
   --  ------------------------------
   function Is_Generation_Enabled (Model : in Model_Definition;
                                   Name  : in String) return Boolean is
      Upper_Name : constant String := Util.Strings.Transforms.To_Upper_Case (Name);
      Key        : constant Unbounded_String := To_Unbounded_String (Upper_Name);
   begin
      return not Model.Packages.Element (Key).Is_Predefined
        and (Model.Gen_Packages.Is_Empty or Model.Gen_Packages.Contains (Upper_Name));
   end Is_Generation_Enabled;

   --  ------------------------------
   --  Prepare the generation of the package:
   --  o identify the column types which are used
   --  o build a list of package for the with clauses.
   --  ------------------------------
   overriding
   procedure Prepare (O : in out Package_Definition) is
      use Gen.Model.Tables;

      procedure Prepare_Table (Table : in Table_Definition_Access);
      procedure Prepare_Definition (Def : in Definition_Access);
      procedure Collect_Dependencies (Table : in Definition_Access);

      Used_Types  : Gen.Utils.String_Set.Set;
      T : constant Util.Beans.Basic.Readonly_Bean_Access := O.Used_Types'Unchecked_Access;

      procedure Prepare_Table (Table : in Table_Definition_Access) is
         C     : Column_List.Cursor := Table.Members.First;
      begin
         Table.Prepare;

         --  Walk the columns to get their type.
         while Column_List.Has_Element (C) loop
            declare
               use type Model.Mappings.Basic_Type;
               use type Model.Mappings.Mapping_Definition_Access;

               Col  : constant Column_Definition_Access := Column_List.Element (C);
               T    : constant Model.Mappings.Mapping_Definition_Access := Col.Get_Type_Mapping;
               Name : constant String := To_String (Col.Type_Name);
               Pkg  : constant String := Gen.Utils.Get_Package_Name (Name);
            begin
               if T = null then
                  Log.Error ("Column {0} has null type in table {1} - type is name {2}",
                             Col.Get_Name, Table.Get_Name, Name);

               else
                  case T.Kind is
                     when Model.Mappings.T_DATE =>
                        O.Uses_Calendar_Time := True;

                     when Model.Mappings.T_ENUM | Model.Mappings.T_BEAN | Model.Mappings.T_TABLE =>
                        if Pkg'Length > 0 and Pkg /= O.Name then
                           Used_Types.Include (To_Unbounded_String (Pkg));
                        end if;

                     when others =>
                        if T.Kind /= Model.Mappings.T_DATE
                          and (Name = "Date" or Name = "DateTime" or Name = "Time") then
                           Log.Error ("Date type {0} is invalid in table {1} - type is name {2}",
                                      Model.Mappings.Basic_Type'Image (T.Kind), Table.Get_Name,
                                      Name);
                        end if;
                  end case;
               end if;
            end;
            Column_List.Next (C);
         end loop;
      end Prepare_Table;

      procedure Prepare_Definition (Def : in Definition_Access) is
      begin
         if Def.all in Table_Definition'Class then
            Prepare_Table (Table_Definition_Access (Def));
         else
            Def.Prepare;
         end if;
      end Prepare_Definition;

      procedure Collect_Dependencies (Table : in Definition_Access) is
      begin
         if Table.all in Table_Definition'Class then
            Table_Definition'Class (Table.all).Collect_Dependencies;
         end if;
      end Collect_Dependencies;

   begin
      Log.Info ("Preparing package {0}", O.Name);

      O.Used := Util.Beans.Objects.To_Object (T, Util.Beans.Objects.STATIC);
      O.Used_Types.Row := 0;
      O.Used_Types.Values.Clear;
      O.Uses_Calendar_Time := False;

      O.Enums.Sort;
      O.Queries.Sort;
      O.Enums.Iterate (Process => Prepare_Definition'Access);
      O.Tables.Iterate (Process => Prepare_Definition'Access);
      O.Queries.Iterate (Process => Prepare_Definition'Access);
      O.Beans.Iterate (Process => Prepare_Definition'Access);

      --  Collect the table dependencies and sort the tables so that tables that depend on
      --  others are processed at the end.
      O.Tables.Iterate (Process => Collect_Dependencies'Access);
      Dependency_Sort (O.Tables);

      declare
         P : Gen.Utils.String_Set.Cursor := Used_Types.First;
      begin
         while Gen.Utils.String_Set.Has_Element (P) loop
            declare
               Name : constant Unbounded_String := Gen.Utils.String_Set.Element (P);
            begin
               Log.Info ("with {0}", Name);
               O.Used_Types.Values.Append (Util.Beans.Objects.To_Object (Name));
            end;
            Gen.Utils.String_Set.Next (P);
         end loop;
      end;
   end Prepare;

   --  ------------------------------
   --  Initialize the package instance
   --  ------------------------------
   overriding
   procedure Initialize (O : in out Package_Definition) is
      use Util.Beans.Objects;
   begin
      O.Enums_Bean   := Util.Beans.Objects.To_Object (O.Enums'Unchecked_Access, STATIC);
      O.Tables_Bean  := Util.Beans.Objects.To_Object (O.Tables'Unchecked_Access, STATIC);
      O.Queries_Bean := Util.Beans.Objects.To_Object (O.Queries'Unchecked_Access, STATIC);
      O.Beans_Bean   := Util.Beans.Objects.To_Object (O.Beans'Unchecked_Access, STATIC);
      O.Used         := Util.Beans.Objects.To_Object (O.Used_Types'Unchecked_Access, STATIC);
   end Initialize;

   --  ------------------------------
   --  Get the number of elements in the list.
   --  ------------------------------
   overriding
   function Get_Count (From : List_Object) return Natural is
   begin
      Log.Debug ("Length {0}", Natural'Image (Natural (From.Values.Length)));
      return Natural (From.Values.Length);
   end Get_Count;

   --  ------------------------------
   --  Set the current row index.  Valid row indexes start at 1.
   --  ------------------------------
   overriding
   procedure Set_Row_Index (From  : in out List_Object;
                            Index : in Natural) is
   begin
      Log.Debug ("Setting row {0}", Natural'Image (Index));
      From.Row := Index;
   end Set_Row_Index;

   --  ------------------------------
   --  Get the element at the current row index.
   --  ------------------------------
   overriding
   function Get_Row (From  : List_Object) return Util.Beans.Objects.Object is
   begin
      Log.Debug ("Getting row {0}", Natural'Image (From.Row));
      return From.Values.Element (From.Row - 1);
   end Get_Row;

   --  ------------------------------
   --  Get the value identified by the name.
   --  If the name cannot be found, the method should return the Null object.
   --  ------------------------------
   overriding
   function Get_Value (From : in List_Object;
                       Name : in String) return Util.Beans.Objects.Object is
      pragma Unreferenced (From);
      pragma Unreferenced (Name);
   begin
      return Util.Beans.Objects.Null_Object;
   end Get_Value;

   --  ------------------------------
   --  Get the value identified by the name.
   --  If the name cannot be found, the method should return the Null object.
   --  ------------------------------
   overriding
   function Get_Value (From : in Model_Definition;
                       Name : in String) return Util.Beans.Objects.Object is
   begin
      if Name = "tables" then
         return From.Tables_Bean;

      elsif Name = "dirname" then
         return Util.Beans.Objects.To_Object (From.Dir_Name);

      else
         return Definition (From).Get_Value (Name);
      end if;
   end Get_Value;

   --  ------------------------------
   --  Set the directory name associated with the model. This directory name allows to
   --  save and build a model in separate directories for the application, the unit tests
   --  and others.
   --  ------------------------------
   procedure Set_Dirname (O : in out Model_Definition;
                          Target_Dir : in String;
                          Model_Dir  : in String) is
   begin
      O.Dir_Name := To_Unbounded_String (Target_Dir);
      O.DB_Name  := To_Unbounded_String (Model_Dir);
   end Set_Dirname;

   --  ------------------------------
   --  Get the directory name associated with the model.
   --  ------------------------------
   function Get_Dirname (O : in Model_Definition) return String is
   begin
      return To_String (O.Dir_Name);
   end Get_Dirname;

   --  ------------------------------
   --  Get the directory name which contains the model.
   --  ------------------------------
   function Get_Model_Directory (O : in Model_Definition) return String is
   begin
      return To_String (O.DB_Name);
   end Get_Model_Directory;

   --  ------------------------------
   --  Initialize the model definition instance.
   --  ------------------------------
   overriding
   procedure Initialize (O : in out Model_Definition) is
      T : constant Util.Beans.Basic.Readonly_Bean_Access := O.Tables'Unchecked_Access;
   begin
      O.Tables_Bean := Util.Beans.Objects.To_Object (T, Util.Beans.Objects.STATIC);
      O.Dir_Name    := To_Unbounded_String ("src");
   end Initialize;

   --  ------------------------------
   --  Prepare the generation of the package:
   --  o identify the column types which are used
   --  o build a list of package for the with clauses.
   --  ------------------------------
   overriding
   procedure Prepare (O : in out Model_Definition) is
      Iter : Package_Cursor := O.Packages.First;
   begin
      while Has_Element (Iter) loop
         Element (Iter).Prepare;
         Next (Iter);
      end loop;
      O.Tables.Sort;
   end Prepare;

   --  ------------------------------
   --  Get the first package of the model definition.
   --  ------------------------------
   function First (From : Model_Definition) return Package_Cursor is
   begin
      return From.Packages.First;
   end First;

   --  ------------------------------
   --  Register a type mapping.  The <b>From</b> type describes a type in the XML
   --  configuration files (hibernate, query, ...) and the <b>To</b> represents the
   --  corresponding Ada type.
   --  ------------------------------
   procedure Register_Type (O    : in out Model_Definition;
                            From : in String;
                            To   : in String) is
   begin
      null;
   end Register_Type;

   --  ------------------------------
   --  Returns False if the <tt>Left</tt> table does not depend on <tt>Right</tt>.
   --  Returns True if the <tt>Left</tt> table depends on the <tt>Right</tt> table.
   --  ------------------------------
   function Dependency_Compare (Left, Right : in Definition_Access) return Boolean is
      use Gen.Model.Tables;

      T_Left  : constant Table_Definition_Access := Table_Definition'Class (Left.all)'Access;
      T_Right : constant Table_Definition_Access := Table_Definition'Class (Right.all)'Access;
   begin
      Log.Info ("Table {0} and {1} do not depend on each other",
                To_String (Left.Name), To_String (Right.Name));

      case Gen.Model.Tables.Depends_On (T_Left, T_Right) is
         when FORWARD =>
            return False;

         when BACKWARD =>
            return True;

         when others =>
            --  Two tables that don't depend on each other are sorted on their name.
            return Left.Name < Right.Name;
      end case;
   end Dependency_Compare;

   --  ------------------------------
   --  Find the type identified by the name.
   --  ------------------------------
   function Find_Type (From : in Model_Definition;
                       Name : in Unbounded_String)
                       return Gen.Model.Mappings.Mapping_Definition_Access is
      N : constant Natural := Ada.Strings.Unbounded.Index (Name, ".", Ada.Strings.Backward);
      L : constant Natural := Ada.Strings.Unbounded.Length (Name);
   begin
      if N = 0 then
         return null;
      end if;
      declare
         Pkg_Name  : constant String := Ada.Strings.Unbounded.Slice (Name, 1, N - 1);
         Base_Name : constant String := Ada.Strings.Unbounded.Slice (Name, N + 1, L);
         Key       : constant String := Util.Strings.Transforms.To_Upper_Case (Pkg_Name);
         Pos       : constant Package_Map.Cursor := From.Packages.Find (To_Unbounded_String (Key));
      begin
         if Package_Map.Has_Element (Pos) then
            return Package_Map.Element (Pos).Find_Type (To_Unbounded_String (Base_Name));
         else
            return null;
         end if;
      end;
   end Find_Type;

end Gen.Model.Packages;
