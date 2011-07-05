-----------------------------------------------------------------------
--  Gen.Database.Model -- Gen.Database.Model
-----------------------------------------------------------------------
--  File generated by ada-gen DO NOT MODIFY
--  Template used: templates/model/package-spec.xhtml
--  Ada Generator: https://ada-gen.googlecode.com/svn/trunk Revision 166
-----------------------------------------------------------------------
--  Copyright (C) 2009, 2010, 2011 Stephane Carrez
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
with ADO.Sessions;
with ADO.Objects;
with ADO.Statements;
with ADO.SQL;
with ADO.Schemas;
with ADO.Queries;
with ADO.Queries.Loaders;
with Ada.Calendar;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Util.Beans.Objects;
package Gen.Database.Model is
   --  --------------------
   --  Application Schema information
   --  --------------------
   --  Create an object key for Schema.
   function Schema_Key (Id : in ADO.Identifier) return ADO.Objects.Object_Key;
   --  Create an object key for Schema from a string.
   --  Raises Constraint_Error if the string cannot be converted into the object key.
   function Schema_Key (Id : in String) return ADO.Objects.Object_Key;

   type Schema_Ref is new ADO.Objects.Object_Ref with null record;

   Null_Schema : constant Schema_Ref;
   function "=" (Left, Right : Schema_Ref'Class) return Boolean;

   --  Set the model name
   procedure Set_Name (Object : in out Schema_Ref;
                       Value  : in Ada.Strings.Unbounded.Unbounded_String);
   procedure Set_Name (Object : in out Schema_Ref;
                       Value : in String);

   --  Get the model name
   function Get_Name (Object : in Schema_Ref)
                 return Ada.Strings.Unbounded.Unbounded_String;
   function Get_Name (Object : in Schema_Ref)
                 return String;

   --  Set the schema version
   procedure Set_Version (Object : in out Schema_Ref;
                          Value  : in Integer);

   --  Get the schema version
   function Get_Version (Object : in Schema_Ref)
                 return Integer;

   --  Set the upgrade date
   procedure Set_Date (Object : in out Schema_Ref;
                       Value  : in ADO.Nullable_Time);

   --  Get the upgrade date
   function Get_Date (Object : in Schema_Ref)
                 return ADO.Nullable_Time;

   --  Load the entity identified by 'Id'.
   --  Raises the NOT_FOUND exception if it does not exist.
   procedure Load (Object  : in out Schema_Ref;
                   Session : in out ADO.Sessions.Session'Class;
                   Id      : in Ada.Strings.Unbounded.Unbounded_String);

   --  Load the entity identified by 'Id'.
   --  Returns True in <b>Found</b> if the object was found and False if it does not exist.
   procedure Load (Object  : in out Schema_Ref;
                   Session : in out ADO.Sessions.Session'Class;
                   Id      : in Ada.Strings.Unbounded.Unbounded_String;
                   Found   : out Boolean);

   --  Find and load the entity.
   overriding
   procedure Find (Object  : in out Schema_Ref;
                   Session : in out ADO.Sessions.Session'Class;
                   Query   : in ADO.SQL.Query'Class;
                   Found   : out Boolean);

   --  Save the entity.  If the entity does not have an identifier, an identifier is allocated
   --  and it is inserted in the table.  Otherwise, only data fields which have been changed
   --  are updated.
   overriding
   procedure Save (Object  : in out Schema_Ref;
                   Session : in out ADO.Sessions.Master_Session'Class);

   --  Delete the entity.
   overriding
   procedure Delete (Object  : in out Schema_Ref;
                     Session : in out ADO.Sessions.Master_Session'Class);

   overriding
   function Get_Value (Item : in Schema_Ref;
                       Name : in String) return Util.Beans.Objects.Object;

   --  Table definition
   SCHEMA_TABLE : aliased constant ADO.Schemas.Class_Mapping;

   --  Internal method to allocate the Object_Record instance
   overriding
   procedure Allocate (Object : in out Schema_Ref);

   --  Copy of the object.
   function Copy (Object : Schema_Ref) return Schema_Ref;

   package Schema_Vectors is
      new Ada.Containers.Vectors (Index_Type   => Natural,
                                  Element_Type => Schema_Ref,
                                  "="          => "=");
   subtype Schema_Vector is Schema_Vectors.Vector;

   procedure List (Object  : in out Schema_Vector;
                   Session : in out ADO.Sessions.Session'Class;
                   Query   : in ADO.SQL.Query'Class);

   --  --------------------
   --  
   --  --------------------
   type Database_Info is tagged record
      --  the database name.
      Name : Ada.Strings.Unbounded.Unbounded_String;

   end record;

   package Database_Info_Vectors is
      new Ada.Containers.Vectors (Index_Type   => Natural,
                                  Element_Type => Database_Info,
                                  "="          => "=");
   subtype Database_Info_Vector is Database_Info_Vectors.Vector;

   procedure List (Object  : in out Database_Info_Vector;
                   Session : in out ADO.Sessions.Session'Class;
                   Context : in out ADO.Queries.Context'Class);

   Query_Database_List : constant ADO.Queries.Query_Definition_Access;

   Query_Table_List : constant ADO.Queries.Query_Definition_Access;

   Query_Create_Database : constant ADO.Queries.Query_Definition_Access;

   Query_Create_User_No_Password : constant ADO.Queries.Query_Definition_Access;

   Query_Create_User_With_Password : constant ADO.Queries.Query_Definition_Access;

   Query_Flush_Privileges : constant ADO.Queries.Query_Definition_Access;


private
   SCHEMA_NAME : aliased constant String := "ADO_SCHEMA";
   COL_0_1_NAME : aliased constant String := "NAME";
   COL_1_1_NAME : aliased constant String := "VERSION";
   COL_2_1_NAME : aliased constant String := "DATE";
   SCHEMA_TABLE : aliased constant ADO.Schemas.Class_Mapping :=
     (Count => 3,
      Table => SCHEMA_NAME'Access,
      Members => (
         COL_0_1_NAME'Access,
         COL_1_1_NAME'Access,
         COL_2_1_NAME'Access
)
     );
   Null_Schema : constant Schema_Ref
      := Schema_Ref'(ADO.Objects.Object_Ref with others => <>);
   type Schema_Impl is
      new ADO.Objects.Object_Record (Key_Type => ADO.Objects.KEY_STRING,
                                     Of_Class => SCHEMA_TABLE'Access)
   with record
       Version : Integer;
       Date : ADO.Nullable_Time;
   end record;
   type Schema_Access is access all Schema_Impl;
   overriding
   procedure Destroy (Object : access Schema_Impl);
   overriding
   procedure Find (Object  : in out Schema_Impl;
                   Session : in out ADO.Sessions.Session'Class;
                   Query   : in ADO.SQL.Query'Class;
                   Found   : out Boolean);
   overriding
   procedure Load (Object  : in out Schema_Impl;
                   Session : in out ADO.Sessions.Session'Class);
   procedure Load (Object  : in out Schema_Impl;
                   Stmt    : in out ADO.Statements.Query_Statement'Class;
                   Session : in out ADO.Sessions.Session'Class);
   overriding
   procedure Save (Object  : in out Schema_Impl;
                   Session : in out ADO.Sessions.Master_Session'Class);
   procedure Create (Object  : in out Schema_Impl;
                     Session : in out ADO.Sessions.Master_Session'Class);
   overriding
   procedure Delete (Object  : in out Schema_Impl;
                     Session : in out ADO.Sessions.Master_Session'Class);
   procedure Set_Field (Object : in out Schema_Ref'Class;
                        Impl   : out Schema_Access;
                        Field  : in Positive);

   package File_Databaseinfo is
      new ADO.Queries.Loaders.File (Path => "create-database.xml",
                                    Sha1 => "5CCC0C05ECA7B8D6757ED08034015B1453C95014");

   package Def_Databaseinfo_Database_List is
      new ADO.Queries.Loaders.Query (Name => "database-list",
                                     File => File_Databaseinfo.File'Access);
   Query_Database_List : constant ADO.Queries.Query_Definition_Access
   := Def_Databaseinfo_Database_List.Query'Access;

   package Def_Databaseinfo_Table_List is
      new ADO.Queries.Loaders.Query (Name => "table-list",
                                     File => File_Databaseinfo.File'Access);
   Query_Table_List : constant ADO.Queries.Query_Definition_Access
   := Def_Databaseinfo_Table_List.Query'Access;

   package Def_Databaseinfo_Create_Database is
      new ADO.Queries.Loaders.Query (Name => "create-database",
                                     File => File_Databaseinfo.File'Access);
   Query_Create_Database : constant ADO.Queries.Query_Definition_Access
   := Def_Databaseinfo_Create_Database.Query'Access;

   package Def_Databaseinfo_Create_User_No_Password is
      new ADO.Queries.Loaders.Query (Name => "create-user-no-password",
                                     File => File_Databaseinfo.File'Access);
   Query_Create_User_No_Password : constant ADO.Queries.Query_Definition_Access
   := Def_Databaseinfo_Create_User_No_Password.Query'Access;

   package Def_Databaseinfo_Create_User_With_Password is
      new ADO.Queries.Loaders.Query (Name => "create-user-with-password",
                                     File => File_Databaseinfo.File'Access);
   Query_Create_User_With_Password : constant ADO.Queries.Query_Definition_Access
   := Def_Databaseinfo_Create_User_With_Password.Query'Access;

   package Def_Databaseinfo_Flush_Privileges is
      new ADO.Queries.Loaders.Query (Name => "flush-privileges",
                                     File => File_Databaseinfo.File'Access);
   Query_Flush_Privileges : constant ADO.Queries.Query_Definition_Access
   := Def_Databaseinfo_Flush_Privileges.Query'Access;
end Gen.Database.Model;
