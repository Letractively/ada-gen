-----------------------------------------------------------------------
--  Gen.Database.Model -- Gen.Database.Model
-----------------------------------------------------------------------
--  File generated by ada-gen DO NOT MODIFY
--  Template used: templates/model/package-body.xhtml
--  Ada Generator: https://ada-gen.googlecode.com/svn/trunk Revision 305
-----------------------------------------------------------------------
--  Copyright (C) 2011 Stephane Carrez
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
with Ada.Unchecked_Deallocation;
with Util.Beans.Objects.Time;
package body Gen.Database.Model is

   use type ADO.Objects.Object_Record_Access;
   use type ADO.Objects.Object_Ref;
   use type ADO.Objects.Object_Record;

   function Schema_Key (Id : in ADO.Identifier) return ADO.Objects.Object_Key is
      Result : ADO.Objects.Object_Key (Of_Type  => ADO.Objects.KEY_STRING,
                                       Of_Class => SCHEMA_TABLE'Access);
   begin
      ADO.Objects.Set_Value (Result, Id);
      return Result;
   end Schema_Key;

   function Schema_Key (Id : in String) return ADO.Objects.Object_Key is
      Result : ADO.Objects.Object_Key (Of_Type  => ADO.Objects.KEY_STRING,
                                       Of_Class => SCHEMA_TABLE'Access);
   begin
      ADO.Objects.Set_Value (Result, Id);
      return Result;
   end Schema_Key;

   function "=" (Left, Right : Schema_Ref'Class) return Boolean is
   begin
      return ADO.Objects.Object_Ref'Class (Left) = ADO.Objects.Object_Ref'Class (Right);
   end "=";

   procedure Set_Field (Object : in out Schema_Ref'Class;
                        Impl   : out Schema_Access) is
      Result : ADO.Objects.Object_Record_Access;
   begin
      Object.Prepare_Modify (Result);
      Impl := Schema_Impl (Result.all)'Access;
   end Set_Field;

   --  Internal method to allocate the Object_Record instance
   procedure Allocate (Object : in out Schema_Ref) is
      Impl : Schema_Access;
   begin
      Impl := new Schema_Impl;
      Impl.Version := 0;
      Impl.Date.Is_Null := True;
      ADO.Objects.Set_Object (Object, Impl.all'Access);
   end Allocate;

   -- ----------------------------------------
   --  Data object: Schema
   -- ----------------------------------------

   procedure Set_Name (Object : in out Schema_Ref;
                        Value : in String) is
      Impl : Schema_Access;
   begin
      Set_Field (Object, Impl);
      ADO.Objects.Set_Field_Key_Value (Impl.all, 1, Value);
   end Set_Name;

   procedure Set_Name (Object : in out Schema_Ref;
                       Value  : in Ada.Strings.Unbounded.Unbounded_String) is
      Impl : Schema_Access;
   begin
      Set_Field (Object, Impl);
      ADO.Objects.Set_Field_Key_Value (Impl.all, 1, Value);
   end Set_Name;

   function Get_Name (Object : in Schema_Ref)
                 return String is
   begin
      return Ada.Strings.Unbounded.To_String (Object.Get_Name);
   end Get_Name;
   function Get_Name (Object : in Schema_Ref)
                  return Ada.Strings.Unbounded.Unbounded_String is
      Impl : constant Schema_Access := Schema_Impl (Object.Get_Object.all)'Access;
   begin
      return Impl.Get_Key_Value;
   end Get_Name;


   procedure Set_Version (Object : in out Schema_Ref;
                          Value  : in Integer) is
      Impl : Schema_Access;
   begin
      Set_Field (Object, Impl);
      ADO.Objects.Set_Field_Integer (Impl.all, 2, Impl.Version, Value);
      ADO.Objects.Set_Field_Integer (Impl.all, 2, Impl.Version, Value);
   end Set_Version;

   function Get_Version (Object : in Schema_Ref)
                  return Integer is
      Impl : constant Schema_Access := Schema_Impl (Object.Get_Load_Object.all)'Access;
   begin
      return Impl.Version;
   end Get_Version;


   procedure Set_Date (Object : in out Schema_Ref;
                       Value  : in ADO.Nullable_Time) is
      Impl : Schema_Access;
   begin
      Set_Field (Object, Impl);
      ADO.Objects.Set_Field_Time (Impl.all, 3, Impl.Date, Value);
   end Set_Date;

   function Get_Date (Object : in Schema_Ref)
                  return ADO.Nullable_Time is
      Impl : constant Schema_Access := Schema_Impl (Object.Get_Load_Object.all)'Access;
   begin
      return Impl.Date;
   end Get_Date;

   --  Copy of the object.
   procedure Copy (Object : in Schema_Ref;
                   Into   : in out Schema_Ref) is
      Result : Schema_Ref;
   begin
      if not Object.Is_Null then
         declare
            Impl : constant Schema_Access
              := Schema_Impl (Object.Get_Load_Object.all)'Access;
            Copy : constant Schema_Access
              := new Schema_Impl;
         begin
            ADO.Objects.Set_Object (Result, Copy.all'Access);
            Copy.Copy (Impl.all);
            Copy.all.Set_Key (Impl.all.Get_Key);
            Copy.Version := Impl.Version;
            Copy.Date := Impl.Date;
         end;
      end if;
      Into := Result;
   end Copy;

   procedure Find (Object  : in out Schema_Ref;
                   Session : in out ADO.Sessions.Session'Class;
                   Query   : in ADO.SQL.Query'Class;
                   Found   : out Boolean) is
      Impl  : constant Schema_Access := new Schema_Impl;
   begin
      Impl.Find (Session, Query, Found);
      if Found then
         ADO.Objects.Set_Object (Object, Impl.all'Access);
      else
         ADO.Objects.Set_Object (Object, null);
         Destroy (Impl);
      end if;
   end Find;

   procedure Load (Object  : in out Schema_Ref;
                   Session : in out ADO.Sessions.Session'Class;
                   Id      : in Ada.Strings.Unbounded.Unbounded_String) is
      Impl  : constant Schema_Access := new Schema_Impl;
      Found : Boolean;
      Query : ADO.SQL.Query;
   begin
      Query.Bind_Param (Position => 1, Value => Id);
      Query.Set_Filter ("name = ?");
      Impl.Find (Session, Query, Found);
      if not Found then
         Destroy (Impl);
         raise ADO.Objects.NOT_FOUND;
      end if;
      ADO.Objects.Set_Object (Object, Impl.all'Access);
   end Load;

   procedure Load (Object  : in out Schema_Ref;
                   Session : in out ADO.Sessions.Session'Class;
                   Id      : in Ada.Strings.Unbounded.Unbounded_String;
                   Found   : out Boolean) is
      Impl  : constant Schema_Access := new Schema_Impl;
      Query : ADO.SQL.Query;
   begin
      Query.Bind_Param (Position => 1, Value => Id);
      Query.Set_Filter ("name = ?");
      Impl.Find (Session, Query, Found);
      if not Found then
         Destroy (Impl);
      else
         ADO.Objects.Set_Object (Object, Impl.all'Access);
      end if;
   end Load;

   procedure Save (Object  : in out Schema_Ref;
                   Session : in out ADO.Sessions.Master_Session'Class) is
      Impl : ADO.Objects.Object_Record_Access := Object.Get_Object;
   begin
      if Impl = null then
         Impl := new Schema_Impl;
         ADO.Objects.Set_Object (Object, Impl);
      end if;
      if not ADO.Objects.Is_Created (Impl.all) then
         Impl.Create (Session);
      else
         Impl.Save (Session);
      end if;
   end Save;

   procedure Delete (Object  : in out Schema_Ref;
                     Session : in out ADO.Sessions.Master_Session'Class) is
      Impl : constant ADO.Objects.Object_Record_Access := Object.Get_Object;
   begin
      if Impl /= null then
         Impl.Delete (Session);
      end if;
   end Delete;

   --  --------------------
   --  Free the object
   --  --------------------
   procedure Destroy (Object : access Schema_Impl) is
      type Schema_Impl_Ptr is access all Schema_Impl;
      procedure Unchecked_Free is new Ada.Unchecked_Deallocation
              (Schema_Impl, Schema_Impl_Ptr);
      pragma Warnings (Off, "*redundant conversion*");
      Ptr : Schema_Impl_Ptr := Schema_Impl (Object.all)'Access;
      pragma Warnings (On, "*redundant conversion*");
   begin
      Unchecked_Free (Ptr);
   end Destroy;

   procedure Find (Object  : in out Schema_Impl;
                   Session : in out ADO.Sessions.Session'Class;
                   Query   : in ADO.SQL.Query'Class;
                   Found   : out Boolean) is
      Stmt : ADO.Statements.Query_Statement
          := Session.Create_Statement (SCHEMA_TABLE'Access);
   begin
      Stmt.Set_Parameters (Query);
      Stmt.Execute;
      if Stmt.Has_Elements then
         Object.Load (Stmt, Session);
         Stmt.Next;
         Found := not Stmt.Has_Elements;
      else
         Found := False;
      end if;
   end Find;

   overriding
   procedure Load (Object  : in out Schema_Impl;
                   Session : in out ADO.Sessions.Session'Class) is
      Found : Boolean;
      Query : ADO.SQL.Query;
      Id    : constant Ada.Strings.Unbounded.Unbounded_String := Object.Get_Key_Value;
   begin
      Query.Bind_Param (Position => 1, Value => Id);
      Query.Set_Filter ("name = ?");
      Object.Find (Session, Query, Found);
      if not Found then
         raise ADO.Objects.NOT_FOUND;
      end if;
   end Load;

   procedure Save (Object  : in out Schema_Impl;
                   Session : in out ADO.Sessions.Master_Session'Class) is
      Stmt : ADO.Statements.Update_Statement
         := Session.Create_Statement (SCHEMA_TABLE'Access);
   begin
      if Object.Is_Modified (1) then
         Stmt.Save_Field (Name  => COL_0_1_NAME, --  NAME
                          Value => Object.Get_Key);
         Object.Clear_Modified (1);
      end if;
      if Object.Is_Modified (2) then
         Stmt.Save_Field (Name  => COL_1_1_NAME, --  VERSION
                          Value => Object.Version);
         Object.Clear_Modified (2);
      end if;
      if Object.Is_Modified (3) then
         Stmt.Save_Field (Name  => COL_2_1_NAME, --  DATE
                          Value => Object.Date);
         Object.Clear_Modified (3);
      end if;
      if Stmt.Has_Save_Fields then
         Stmt.Set_Filter (Filter => "name = ?");
         Stmt.Add_Param (Value => Object.Get_Key);
         declare
            Result : Integer;
         begin
            Stmt.Execute (Result);
            if Result /= 1 then
               if Result /= 0 then
                  raise ADO.Objects.UPDATE_ERROR;
               end if;
            end if;
         end;
      end if;
   end Save;

   procedure Create (Object  : in out Schema_Impl;
                     Session : in out ADO.Sessions.Master_Session'Class) is
      Query : ADO.Statements.Insert_Statement
                  := Session.Create_Statement (SCHEMA_TABLE'Access);
      Result : Integer;
   begin
      Query.Save_Field (Name  => COL_0_1_NAME, --  NAME
                        Value => Object.Get_Key);
      Query.Save_Field (Name  => COL_1_1_NAME, --  VERSION
                        Value => Object.Version);
      Query.Save_Field (Name  => COL_2_1_NAME, --  DATE
                        Value => Object.Date);
      Query.Execute (Result);
      if Result /= 1 then
         raise ADO.Objects.INSERT_ERROR;
      end if;
      ADO.Objects.Set_Created (Object);
   end Create;

   procedure Delete (Object  : in out Schema_Impl;
                     Session : in out ADO.Sessions.Master_Session'Class) is
      Stmt : ADO.Statements.Delete_Statement
         := Session.Create_Statement (SCHEMA_TABLE'Access);
   begin
      Stmt.Set_Filter (Filter => "name = ?");
      Stmt.Add_Param (Value => Object.Get_Key);
      Stmt.Execute;
   end Delete;

   function Get_Value (Item : in Schema_Ref;
                       Name : in String) return Util.Beans.Objects.Object is
      Obj  : constant ADO.Objects.Object_Record_Access := Item.Get_Load_Object;
      Impl : access Schema_Impl;
   begin
      if Obj = null then
         return Util.Beans.Objects.Null_Object;
      end if;
      Impl := Schema_Impl (Obj.all)'Access;
      if Name = "name" then
         return ADO.Objects.To_Object (Impl.Get_Key);
      end if;
      if Name = "version" then
         return Util.Beans.Objects.To_Object (Long_Long_Integer (Impl.Version));
      end if;
      if Name = "date" then
         if Impl.Date.Is_Null then
            return Util.Beans.Objects.Null_Object;
         else
            return Util.Beans.Objects.Time.To_Object (Impl.Date.Value);
         end if;
      end if;
      return Util.Beans.Objects.Null_Object;
   end Get_Value;

   procedure List (Object  : in out Schema_Vector;
                   Session : in out ADO.Sessions.Session'Class;
                   Query   : in ADO.SQL.Query'Class) is
      Stmt : ADO.Statements.Query_Statement := Session.Create_Statement (SCHEMA_TABLE'Access);
   begin
      Stmt.Set_Parameters (Query);
      Stmt.Execute;
      Schema_Vectors.Clear (Object);
      while Stmt.Has_Elements loop
         declare
            Item : Schema_Ref;
            Impl : constant Schema_Access := new Schema_Impl;
         begin
            Impl.Load (Stmt, Session);
            ADO.Objects.Set_Object (Item, Impl.all'Access);
            Object.Append (Item);
         end;
         Stmt.Next;
      end loop;
   end List;

   --  ------------------------------
   --  Load the object from current iterator position
   --  ------------------------------
   procedure Load (Object  : in out Schema_Impl;
                   Stmt    : in out ADO.Statements.Query_Statement'Class;
                   Session : in out ADO.Sessions.Session'Class) is
      pragma Unreferenced (Session);
   begin
      Object.Set_Key_Value (Stmt.Get_Unbounded_String (0));
      Object.Version := Stmt.Get_Integer (1);
      Object.Date := Stmt.Get_Time (2);
      ADO.Objects.Set_Created (Object);
   end Load;
   --  --------------------
   --  information about the database
   --  --------------------
   procedure List (Object  : in out Database_Info_Vector;
                   Session : in out ADO.Sessions.Session'Class;
                   Context : in out ADO.Queries.Context'Class) is
      procedure Read (Into : in out Database_Info);

      Stmt : ADO.Statements.Query_Statement
          := Session.Create_Statement (Context);
      Pos  : Natural := 0;
      procedure Read (Into : in out Database_Info) is
      begin
         Into.Name := Stmt.Get_Unbounded_String (0);
      end Read;
   begin
      Stmt.Execute;
      Database_Info_Vectors.Clear (Object);
      while Stmt.Has_Elements loop
         Object.Insert_Space (Before => Pos);
         Object.Update_Element (Index => Pos, Process => Read'Access);
         Pos := Pos + 1;
         Stmt.Next;
      end loop;
   end List;


end Gen.Database.Model;
