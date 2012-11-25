-----------------------------------------------------------------------
--  gen-artifacts-xmi -- UML-XMI artifact for Code Generator
--  Copyright (C) 2012 Stephane Carrez
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
with Ada.Strings.Unbounded;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Directories;

with Gen.Configs;
with Gen.Utils;
with Gen.Model.Tables;
with Gen.Model.Enums;
with Gen.Model.Mappings;
with Gen.Model.Beans;

with Util.Log.Loggers;
with Util.Strings;
with Util.Beans;
with Util.Beans.Objects;
with Util.Serialize.Mappers.Record_Mapper;
with Util.Serialize.IO.XML;
with Util.Processes;
with Util.Streams.Pipes;
with Util.Streams.Buffered;

package body Gen.Artifacts.XMI is

   use Ada.Strings.Unbounded;
   use Gen.Model;
   use Gen.Configs;

   use type DOM.Core.Node;
   use Util.Log;

   Log : constant Loggers.Logger := Loggers.Create ("Gen.Artifacts.XMI");

   --  Get the visibility from the XMI visibility value.
   function Get_Visibility (Value : in Util.Beans.Objects.Object) return Model.XMI.Visibility_Type;

   --  Get the changeability from the XMI visibility value.
   function Get_Changeability (Value : in Util.Beans.Objects.Object)
                               return Model.XMI.Changeability_Type;

   procedure Iterate_For_Table is
     new Gen.Model.XMI.Iterate_Elements (T => Gen.Model.Tables.Table_Definition'Class);

   procedure Iterate_For_Bean is
     new Gen.Model.XMI.Iterate_Elements (T => Gen.Model.Beans.Bean_Definition'Class);

   procedure Iterate_For_Package is
     new Gen.Model.XMI.Iterate_Elements (T => Gen.Model.Packages.Package_Definition'Class);

   procedure Iterate_For_Enum is
     new Gen.Model.XMI.Iterate_Elements (T => Gen.Model.Enums.Enum_Definition'Class);

   function Find_Stereotype is
     new Gen.Model.XMI.Find_Element (Element_Type        => Model.XMI.Stereotype_Element,
                                     Element_Type_Access => Model.XMI.Stereotype_Element_Access);

   function Find_Tag_Definition is
     new Gen.Model.XMI.Find_Element (Element_Type        => Model.XMI.Tag_Definition_Element,
                                     Element_Type_Access => Model.XMI.Tag_Definition_Element_Access);

   type XMI_Fields is (FIELD_NAME,
                       FIELD_ID,
                       FIELD_ID_REF,
                       FIELD_VALUE,
                       FIELD_HREF,

                       FIELD_CLASS_NAME, FIELD_CLASS_ID,

                       FIELD_STEREOTYPE,
                       FIELD_STEREOTYPE_NAME,
                       FIELD_STEREOTYPE_ID,
                       FIELD_STEREOTYPE_HREF,

                       FIELD_ATTRIBUTE_NAME,
                       FIELD_ATTRIBUTE_ID,
                       FIELD_ATTRIBUTE_VISIBILITY,
                       FIELD_ATTRIBUTE_CHANGEABILITY,
                       FIELD_ATTRIBUTE_INITIAL_VALUE,
                       FIELD_ATTRIBUTE,

                       FIELD_MULTIPLICITY_UPPER,
                       FIELD_MULTIPLICITY_LOWER,

                       FIELD_NAMESPACE,

                       FIELD_PACKAGE_ID,
                       FIELD_PACKAGE_NAME,
                       FIELD_PACKAGE_END,
                       FIELD_CLASS_VISIBILITY,
                       FIELD_DATA_TYPE,
                       FIELD_DATA_TYPE_HREF,
                       FIELD_ENUM_DATA_TYPE,
                       FIELD_CLASS_END,
                       FIELD_ASSOCIATION_AGGREGATION,
                       FIELD_ASSOCIATION_NAME,
                       FIELD_ASSOCIATION_VISIBILITY,
                       FIELD_ASSOCIATION_ID,
                       FIELD_ASSOCIATION,
                       FIELD_ASSOCIATION_CLASS_ID,

                       FIELD_CLASSIFIER_HREF,

                       FIELD_ASSOCIATION_END_ID,
                       FIELD_ASSOCIATION_END_NAME,
                       FIELD_ASSOCIATION_END_VISIBILITY,
                       FIELD_ASSOCIATION_END_NAVIGABLE,
                       FIELD_ASSOCIATION_END,

                       FIELD_OPERATION_NAME,
                       FIELD_OPERATION_END,
                       FIELD_PARAMETER_NAME,

                       FIELD_COMMENT,
                       FIELD_COMMENT_ID,

                       FIELD_TAG_DEFINITION,
                       FIELD_TAG_DEFINITION_ID,
                       FIELD_TAG_DEFINITION_NAME,

                       FIELD_TAGGED_VALUE,

                       FIELD_ENUMERATION,
                       FIELD_ENUMERATION_LITERAL,
                       FIELD_ENUMERATION_HREF);

   type XMI_Info is record
      Model              : Gen.Model.XMI.Model_Map_Access;
      Indent : Natural := 1;
      Class_Element    : Gen.Model.XMI.Class_Element_Access;
      Class_Name       : Util.Beans.Objects.Object;
      Class_Visibility   : Gen.Model.XMI.Visibility_Type := Gen.Model.XMI.VISIBILITY_PUBLIC;
      Class_Id           : Util.Beans.Objects.Object;

      Package_Element    : Gen.Model.XMI.Package_Element_Access;
      Package_Id         : Util.Beans.Objects.Object;
      Need_Register_Package : Boolean := False;

      Attr_Id            : Util.Beans.Objects.Object;
      Attr_Element       : Gen.Model.XMI.Attribute_Element_Access;
      Attr_Visibility    : Gen.Model.XMI.Visibility_Type := Gen.Model.XMI.VISIBILITY_PUBLIC;
      Attr_Changeability : Gen.Model.XMI.Changeability_Type := Gen.Model.XMI.CHANGEABILITY_CHANGEABLE;
      Attr_Value         : Util.Beans.Objects.Object;
      Multiplicity_Lower : Integer := 0;
      Multiplicity_Upper : Integer := 0;

      Association          : Gen.Model.XMI.Association_Element_Access;
      Assos_End_Element    : Gen.Model.XMI.Association_End_Element_Access;
      Assos_End_Name       : Util.Beans.Objects.Object;
      Assos_End_Visibility : Gen.Model.XMI.Visibility_Type := Gen.Model.XMI.VISIBILITY_PUBLIC;
      Assos_End_Navigable  : Boolean := False;

      Operation            : Gen.Model.XMI.Operation_Element_Access;
      Parameter            : Gen.Model.XMI.Parameter_Element_Access;

      Name               : Util.Beans.Objects.Object;
      Id                 : Util.Beans.Objects.Object;
      Ref_Id             : Util.Beans.Objects.Object;
      Value              : Util.Beans.Objects.Object;
      Href               : Util.Beans.Objects.Object;
      Tag_Name           : Util.Beans.Objects.Object;

      Association_Id     : Util.Beans.Objects.Object;
      Stereotype_Id      : Util.Beans.Objects.Object;
      Data_Type          : Gen.Model.XMI.Data_Type_Element_Access;
      Enumeration        : Gen.Model.XMI.Enum_Element_Access;
      Tag_Definition     : Gen.Model.XMI.Tag_Definition_Element_Access;

      Stereotype         : Gen.Model.XMI.Stereotype_Element_Access;
      Tagged_Value       : Gen.Model.XMI.Tagged_Value_Element_Access;
      Comment            : Gen.Model.XMI.Comment_Element_Access;
   end record;
   type XMI_Access is access all XMI_Info;

   procedure Add_Tagged_Value (P : in out XMI_Info);

   procedure Set_Member (P     : in out XMI_Info;
                         Field : in XMI_Fields;
                         Value : in Util.Beans.Objects.Object);

   use type Gen.Model.XMI.Model_Element_Access;
   use type Gen.Model.XMI.Attribute_Element_Access;
   use type Gen.Model.XMI.Class_Element_Access;
   use type Gen.Model.XMI.Package_Element_Access;
   use type Gen.Model.XMI.Tag_Definition_Element_Access;
   use type Gen.Model.XMI.Association_End_Element_Access;
   use type Gen.Model.XMI.Stereotype_Element_Access;
   use type Gen.Model.XMI.Enum_Element_Access;
   use type Gen.Model.XMI.Comment_Element_Access;
   use type Gen.Model.XMI.Operation_Element_Access;
   use type Gen.Model.XMI.Association_Element_Access;

   --  ------------------------------
   --  Get the visibility from the XMI visibility value.
   --  ------------------------------
   function Get_Visibility (Value : in Util.Beans.Objects.Object)
                            return Model.XMI.Visibility_Type is
      S : constant String := Util.Beans.Objects.To_String (Value);
   begin
      if S = "public" then
         return Model.XMI.VISIBILITY_PUBLIC;

      elsif S = "package" then
         return Model.XMI.VISIBILITY_PACKAGE;

      elsif S = "protected" then
         return Model.XMI.VISIBILITY_PROTECTED;

      elsif S = "private" then
         return Model.XMI.VISIBILITY_PRIVATE;

      else
         return Model.XMI.VISIBILITY_PUBLIC;
      end if;
   end Get_Visibility;

   --  ------------------------------
   --  Get the changeability from the XMI visibility value.
   --  ------------------------------
   function Get_Changeability (Value : in Util.Beans.Objects.Object)
                            return Model.XMI.Changeability_Type is
      S : constant String := Util.Beans.Objects.To_String (Value);
   begin
      if S = "frozen" then
         return Model.XMI.CHANGEABILITY_FROZEN;

      elsif S = "changeable" then
         return Model.XMI.CHANGEABILITY_CHANGEABLE;

      elsif S = "addOnly" then
         return Model.XMI.CHANGEABILITY_INSERT;

      else
         return Model.XMI.CHANGEABILITY_CHANGEABLE;
      end if;
   end Get_Changeability;

   procedure Add_Tagged_Value (P : in out XMI_Info) is
      Tagged_Value : constant Model.XMI.Tagged_Value_Element_Access
        := new Model.XMI.Tagged_Value_Element (P.Model);
   begin
      Log.Info ("Add tag {0} - {1}",
                Util.Beans.Objects.To_String (P.Id),
                Util.Beans.Objects.To_String (P.Ref_Id));

      Tagged_Value.Value  := Util.Beans.Objects.To_Unbounded_String (P.Value);
      if not Util.Beans.Objects.Is_Null (P.Ref_Id) then
         Tagged_Value.Ref_Id := Util.Beans.Objects.To_Unbounded_String (P.Ref_Id);
      else
         Tagged_Value.Ref_Id := Util.Beans.Objects.To_Unbounded_String (P.Href);
      end if;
      Tagged_Value.XMI_Id := Util.Beans.Objects.To_Unbounded_String (P.Id);
      P.Model.Insert (Tagged_Value.XMI_Id, Tagged_Value.all'Access);

      --  Insert the tag value into the current element.
      if P.Assos_End_Element /= null then
         P.Assos_End_Element.Tagged_Values.Append (Tagged_Value.all'Access);

      elsif P.Association /= null then
         P.Association.Tagged_Values.Append (Tagged_Value.all'Access);

      elsif P.Attr_Element /= null then
         P.Attr_Element.Tagged_Values.Append (Tagged_Value.all'Access);

      elsif P.Class_Element /= null then
         P.Class_Element.Tagged_Values.Append (Tagged_Value.all'Access);

      elsif P.Enumeration /= null then
         P.Enumeration.Tagged_Values.Append (Tagged_Value.all'Access);

      elsif P.Package_Element /= null then
         P.Package_Element.Tagged_Values.Append (Tagged_Value.all'Access);

      elsif P.Tag_Definition /= null then
         P.Tag_Definition.Tagged_Values.Append (Tagged_Value.all'Access);

      else
         Log.Info ("Tagged value {0} ignored", Util.Beans.Objects.To_String (P.Id));
      end if;
   end Add_Tagged_Value;

   procedure Set_Member (P     : in out XMI_Info;
                         Field : in XMI_Fields;
                         Value : in Util.Beans.Objects.Object) is
   begin
      case Field is
         when FIELD_NAME =>
            P.Name := Value;

         when FIELD_ID =>
            P.Id := Value;

         when FIELD_ID_REF =>
            P.Ref_Id := Value;

         when FIELD_VALUE =>
            P.Value := Value;

         when FIELD_HREF =>
            P.Href := Value;

         when FIELD_MULTIPLICITY_LOWER =>
            P.Multiplicity_Lower := Util.Beans.Objects.To_Integer (Value);

         when FIELD_MULTIPLICITY_UPPER =>
            P.Multiplicity_Upper := Util.Beans.Objects.To_Integer (Value);

         when FIELD_CLASS_NAME =>
            P.Class_Element := new Gen.Model.XMI.Class_Element (P.Model);
            P.Class_Element.Set_Name (Value);

         when FIELD_CLASS_VISIBILITY =>
            P.Class_Visibility := Get_Visibility (Value);

         when FIELD_CLASS_ID =>
            P.Class_Id := Value;

         when FIELD_CLASS_END =>
            if P.Class_Element /= null then
               P.Class_Element.XMI_Id := Util.Beans.Objects.To_Unbounded_String (P.Class_Id);
               P.Class_Element.Visibility := P.Class_Visibility;
               Log.Info ("Adding class {0}", P.Class_Element.XMI_Id);
               P.Model.Insert (P.Class_Element.XMI_Id, P.Class_Element.all'Access);
               if P.Package_Element /= null then
                  P.Package_Element.Classes.Append (P.Class_Element.all'Access);
                  P.Package_Element.Elements.Append (P.Class_Element.all'Access);
                  P.Class_Element.Parent := P.Package_Element.all'Access;
               end if;
               P.Class_Element := null;
               P.Class_Visibility := Gen.Model.XMI.VISIBILITY_PUBLIC;
            end if;

         when FIELD_ATTRIBUTE_ID =>
            P.Attr_Id := Value;

         when FIELD_ATTRIBUTE_VISIBILITY =>
            P.Attr_Visibility := Get_Visibility (Value);

         when FIELD_ATTRIBUTE_CHANGEABILITY =>
            P.Attr_Changeability := Get_Changeability (Value);

         when FIELD_ATTRIBUTE_NAME =>
            P.Attr_Element := new Gen.Model.XMI.Attribute_Element (P.Model);
            P.Attr_Element.Set_Name (Value);

         when FIELD_ATTRIBUTE_INITIAL_VALUE =>
            P.Attr_Value := Value;

         when FIELD_ATTRIBUTE =>
            P.Attr_Element.Set_XMI_Id (P.Attr_Id);
            P.Attr_Element.Visibility    := P.Attr_Visibility;
            P.Attr_Element.Changeability := P.Attr_Changeability;
            P.Attr_Element.Multiplicity_Lower := P.Multiplicity_Lower;
            P.Attr_Element.Multiplicity_Upper := P.Multiplicity_Upper;
            P.Attr_Element.Initial_Value      := P.Attr_Value;
            P.Model.Insert (P.Attr_Element.XMI_Id, P.Attr_Element.all'Access);
            if P.Class_Element /= null then
               P.Class_Element.Elements.Append (P.Attr_Element.all'Access);
               P.Class_Element.Attributes.Append (P.Attr_Element.all'Access);
               if P.Attr_Element.Ref_Id = "" then
                  Log.Error ("Class {0}: attribute {1} has no type",
                             To_String (P.Class_Element.Name),
                             To_String (P.Attr_Element.Name));
               end if;
            end if;
            P.Attr_Element       := null;
            P.Attr_Visibility    := Gen.Model.XMI.VISIBILITY_PUBLIC;
            P.Attr_Changeability := Gen.Model.XMI.CHANGEABILITY_CHANGEABLE;
            P.Multiplicity_Lower := 0;
            P.Multiplicity_Upper := 0;

         when FIELD_ENUM_DATA_TYPE =>
            --           Print (P.Indent, "  enum-type:" & Util.Beans.Objects.To_String (Value));
            null;

         when FIELD_OPERATION_NAME =>
            P.Operation := new Gen.Model.XMI.Operation_Element (P.Model);
            P.Operation.Set_Name (Value);

         when FIELD_PARAMETER_NAME =>
            P.Attr_Element := new Gen.Model.XMI.Attribute_Element (P.Model);
            P.Attr_Element.Set_Name (Value);

         when FIELD_OPERATION_END =>
            P.Operation := null;

            --  Extract an association.
         when FIELD_ASSOCIATION_ID =>
            P.Association_Id := Value;

         when FIELD_ASSOCIATION_NAME =>
            P.Association := new Gen.Model.XMI.Association_Element (P.Model);
            P.Association.Set_Name (Value);

         when FIELD_ASSOCIATION_VISIBILITY =>
            --           Print (P.Indent, "visibility: " & Util.Beans.Objects.To_String (Value));
            null;

         when FIELD_ASSOCIATION_AGGREGATION =>
            --           Print (P.Indent, "   aggregate: " & Util.Beans.Objects.To_String (Value));
            null;

         when FIELD_ASSOCIATION_END_NAME =>
            P.Assos_End_Name := Value;

         when FIELD_ASSOCIATION_END_VISIBILITY =>
            P.Assos_End_Visibility := Get_Visibility (Value);

         when FIELD_ASSOCIATION_END_NAVIGABLE =>
            P.Assos_End_Navigable := Util.Beans.Objects.To_Boolean (Value);

         when FIELD_ASSOCIATION_END_ID =>
            P.Assos_End_Element := new Gen.Model.XMI.Association_End_Element (P.Model);
            P.Assos_End_Element.Set_XMI_Id (Value);
            P.Model.Include (P.Assos_End_Element.XMI_Id, P.Assos_End_Element.all'Access);
            if P.Association /= null then
               P.Association.Connections.Append (P.Assos_End_Element.all'Access);
            end if;

         when FIELD_ASSOCIATION_CLASS_ID =>
            if P.Assos_End_Element /= null then
               P.Assos_End_Element.Target := Util.Beans.Objects.To_Unbounded_String (Value);
            end if;

         when FIELD_ASSOCIATION_END =>
            if P.Assos_End_Element /= null then
               P.Assos_End_Element.Set_Name (P.Assos_End_Name);
               P.Assos_End_Element.Visibility := P.Assos_End_Visibility;
               P.Assos_End_Element.Navigable := P.Assos_End_Navigable;
               P.Assos_End_Element.Multiplicity_Lower := P.Multiplicity_Lower;
               P.Assos_End_Element.Multiplicity_Upper := P.Multiplicity_Upper;
               P.Assos_End_Element.Parent := P.Association.all'Access;
            end if;
            P.Multiplicity_Lower := 0;
            P.Multiplicity_Upper := 0;
            P.Assos_End_Name := Util.Beans.Objects.Null_Object;
            P.Assos_End_Navigable := False;

         when FIELD_ASSOCIATION =>
            if P.Association /= null then
               P.Association.Set_XMI_Id (P.Association_Id);
               P.Model.Include (P.Association.XMI_Id, P.Association.all'Access);
               if P.Package_Element /= null then
                  P.Package_Element.Associations.Append (P.Association.all'Access);
               end if;
            end if;
            P.Association := null;

         when FIELD_NAMESPACE =>
            if P.Need_Register_Package and P.Package_Element /= null then
               P.Package_Element.Set_XMI_Id (P.Package_Id);
               P.Model.Include (P.Package_Element.XMI_Id, P.Package_Element.all'Access);
               if P.Package_Element.Parent /= null then
                  P.Package_Element := Gen.Model.XMI.Package_Element (P.Package_Element.Parent.all)'Access;
               else
                  P.Package_Element := null;
               end if;
               if P.Package_Element /= null then
                  P.Package_Id := Util.Beans.Objects.To_Object (P.Package_Element.XMI_Id);
               end if;
               P.Need_Register_Package := False;
            end if;

         when FIELD_PACKAGE_ID =>
            P.Package_Id := Value;

         when FIELD_PACKAGE_NAME =>
            declare
               Parent : constant Gen.Model.XMI.Package_Element_Access := P.Package_Element;
            begin
               P.Package_Element := new Gen.Model.XMI.Package_Element (P.Model);
               P.Package_Element.Set_Name (Value);
               if Parent /= null then
                  P.Package_Element.Parent := Parent.all'Access;
               else
                  P.Package_Element.Parent := null;
               end if;
               P.Need_Register_Package := True;
            end;

         when FIELD_PACKAGE_END =>
            if P.Package_Element /= null then
               if P.Package_Element.Parent /= null then
                  P.Package_Element := Gen.Model.XMI.Package_Element (P.Package_Element.Parent.all)'Access;
               else
                  P.Package_Element := null;
               end if;
            end if;

            --  Tagged value associated with an attribute, operation, class, package.
         when FIELD_TAGGED_VALUE =>
            Add_Tagged_Value (P);

            --  Data type mapping.
         when FIELD_DATA_TYPE =>
            if P.Attr_Element = null and P.Operation = null then
               P.Data_Type := new Gen.Model.XMI.Data_Type_Element (P.Model);
               P.Data_Type.Set_Name (P.Name);
               P.Data_Type.XMI_Id := Util.Beans.Objects.To_Unbounded_String (P.Id);
               P.Model.Insert (P.Data_Type.XMI_Id, P.Data_Type.all'Access);
            end if;

         when FIELD_DATA_TYPE_HREF | FIELD_ENUMERATION_HREF | FIELD_CLASSIFIER_HREF =>
            if P.Attr_Element /= null then
               P.Attr_Element.Ref_Id := Util.Beans.Objects.To_Unbounded_String (Value);
               Log.Debug ("Attribute {0} has type {1}",
                          P.Attr_Element.Name, P.Attr_Element.Ref_Id);
            end if;

            --  Enumeration mapping.
         when FIELD_ENUMERATION =>
            P.Enumeration := new Gen.Model.XMI.Enum_Element (P.Model);
            P.Enumeration.Set_Name (Value);
            P.Enumeration.XMI_Id := Util.Beans.Objects.To_Unbounded_String (P.Id);
            if P.Package_Element /= null then
               P.Enumeration.Parent := P.Package_Element.all'Access;
            end if;
            P.Model.Insert (P.Enumeration.XMI_Id, P.Enumeration.all'Access);
            Log.Info ("Adding enumeration {0}", P.Enumeration.Name);
            if P.Package_Element /= null then
               P.Package_Element.Enums.Append (P.Enumeration.all'Access);
            end if;

         when FIELD_ENUMERATION_LITERAL =>
            P.Enumeration.Add_Literal (P.Id, P.Name);

         when FIELD_STEREOTYPE_NAME =>
            P.Stereotype := new Gen.Model.XMI.Stereotype_Element (P.Model);
            P.Stereotype.Set_Name (Value);

         when FIELD_STEREOTYPE_ID =>
            P.Stereotype_Id := Value;

            --  Stereotype mapping.
         when FIELD_STEREOTYPE =>
            if not Util.Beans.Objects.Is_Null (P.Stereotype_Id) and P.Stereotype /= null then
               P.Stereotype.XMI_Id := Util.Beans.Objects.To_Unbounded_String (P.Stereotype_Id);
               P.Model.Insert (P.Stereotype.XMI_Id, P.Stereotype.all'Access);
               if P.Class_Element /= null then
                  P.Class_Element.Elements.Append (P.Stereotype.all'Access);
               elsif P.Package_Element /= null then
                  P.Package_Element.Elements.Append (P.Stereotype.all'Access);
               end if;
               P.Stereotype := null;
            end if;

         when FIELD_STEREOTYPE_HREF =>
            declare
               S : Gen.Model.XMI.Ref_Type_Element_Access := new Gen.Model.XMI.Ref_Type_Element (P.Model);
            begin
               S.Href := Util.Beans.Objects.To_Unbounded_String (Value);
               if P.Class_Element /= null then
                  P.Class_Element.Stereotypes.Append (S.all'Access);
               elsif P.Package_Element /= null then
                  P.Package_Element.Stereotypes.Append (S.all'Access);
               end if;
            end;

            --  Tag definition mapping.
         when FIELD_TAG_DEFINITION_NAME =>
            P.Tag_Name := Value;

         when FIELD_TAG_DEFINITION_ID =>
            P.Tag_Definition := new Gen.Model.XMI.Tag_Definition_Element (P.Model);
            P.Tag_Definition.Set_XMI_Id (Value);
            P.Model.Insert (P.Tag_Definition.XMI_Id, P.Tag_Definition.all'Access);

         when FIELD_TAG_DEFINITION =>
            P.Tag_Definition.Set_Name (P.Tag_Name);
            P.Tag_Definition := null;

         when FIELD_COMMENT_ID =>
            P.Comment := new Gen.Model.XMI.Comment_Element (P.Model);
            P.Comment.XMI_Id := Util.Beans.Objects.To_Unbounded_String (Value);
            P.Ref_Id := Util.Beans.Objects.Null_Object;

            --  Comment mapping.
         when FIELD_COMMENT =>
            if P.Comment /= null then
               P.Comment.Text    := Util.Beans.Objects.To_Unbounded_String (P.Value);
               P.Comment.Ref_Id  := Util.Beans.Objects.To_Unbounded_String (P.Ref_Id);
               P.Model.Insert (P.Comment.XMI_Id, P.Comment.all'Access);
            end if;
            P.Comment := null;

      end case;
   exception
      when E : others =>
         Log.Error ("Extraction of field {0} with value '{1}' failed",
                    XMI_Fields'Image (Field), Util.Beans.Objects.To_String (Value));
         Log.Error ("Cause", E);
         raise;
   end Set_Member;

   package XMI_Mapper is
     new Util.Serialize.Mappers.Record_Mapper (Element_Type        => XMI_Info,
                                               Element_Type_Access => XMI_Access,
                                               Fields              => XMI_Fields,
                                               Set_Member          => Set_Member);

   XMI_Mapping        : aliased XMI_Mapper.Mapper;

   --  ------------------------------
   --  After the configuration file is read, processes the node whose root
   --  is passed in <b>Node</b> and initializes the <b>Model</b> with the information.
   --  ------------------------------
   procedure Initialize (Handler : in out Artifact;
                         Path    : in String;
                         Node    : in DOM.Core.Node;
                         Model   : in out Gen.Model.Packages.Model_Definition'Class;
                         Context : in out Generator'Class) is

   begin
      Log.Debug ("Initializing query artifact for the configuration");

      Gen.Artifacts.Artifact (Handler).Initialize (Path, Node, Model, Context);
--        Iterate (Gen.Model.Packages.Model_Definition (Model), Node, "query-mapping");
   end Initialize;

   --  ------------------------------
   --  Prepare the generation of the package:
   --  o identify the column types which are used
   --  o build a list of package for the with clauses.
   --  ------------------------------
   overriding
   procedure Prepare (Handler : in out Artifact;
                      Model   : in out Gen.Model.Packages.Model_Definition'Class;
                      Context : in out Generator'Class) is

      --  Collect the enum literal for the enum definition.
      procedure Prepare_Enum_Literal (Enum : in out Gen.Model.Enums.Enum_Definition'Class;
                                      Item : in Gen.Model.XMI.Model_Element_Access);

      --  Register the enum in the model for the generation.
      procedure Prepare_Enum (Pkg  : in out Gen.Model.Packages.Package_Definition'Class;
                              Item : in Gen.Model.XMI.Model_Element_Access);

      use Gen.Model.XMI;
      use Gen.Model.Tables;
      use Gen.Model.Beans;

      procedure Prepare_Model (Key   : in Ada.Strings.Unbounded.Unbounded_String;
                               Model : in out Gen.Model.XMI.Model_Map.Map);

      --  ------------------------------
      --  Register the column definition in the table
      --  ------------------------------
      procedure Prepare_Attribute (Table  : in out Gen.Model.Tables.Table_Definition'Class;
                                   Column : in Model_Element_Access) is
         C    : Column_Definition_Access;
--           G    : constant DOM.Core.Node := Gen.Utils.Get_Child (Column, "generator");
      begin
         Log.Info ("Prepare class attribute {0}", Column.Name);

         Table.Add_Column (Column.Name, C);
         C.Set_Comment (Column.Get_Comment);
         if Column.all in Attribute_Element'Class then
            declare
               Attr : Attribute_Element_Access := Attribute_Element'Class (Column.all)'Access;
            begin
               if Attr.Data_Type /= null then
                  C.Type_Name := To_Unbounded_String (Attr.Data_Type.Get_Qualified_Name);
               end if;
               C.Not_Null := Attr.Multiplicity_Lower > 0;
            end;
         end if;

--
--           C.Is_Inserted := Gen.Utils.Get_Attribute (Column, "insert", True);
--           C.Is_Updated  := Gen.Utils.Get_Attribute (Column, "update", True);
--           if G /= null then
--              C.Generator := Gen.Utils.Get_Attribute (Column, "class");
--           end if;

         --  Get the SQL mapping from an optional <column> element.
--           declare
--              N : DOM.Core.Node := Gen.Utils.Get_Child (Column, "column");
--              T : constant DOM.Core.Node := Gen.Utils.Get_Child (Column, "type");
--           begin
--              if T /= null then
--                 C.Type_Name := To_Unbounded_String (Gen.Utils.Get_Normalized_Type (T, "name"));
--              else
--                 C.Type_Name := To_Unbounded_String (Gen.Utils.Get_Normalized_Type (Column, "type"));
--              end if;
--
--              Log.Debug ("Register column {0} of type {1}", Name, To_String (C.Type_Name));
--              if N /= null then
--                 C.Sql_Name := Gen.Utils.Get_Attribute (N, "name");
--                 C.Sql_Type := Gen.Utils.Get_Attribute (N, "sql-type");
--              else
--                 N := Column;
--                 C.Sql_Name := Gen.Utils.Get_Attribute (N, "column");
--                 C.Sql_Type := C.Type_Name;
--              end if;
--              C.Not_Null := Gen.Utils.Get_Attribute (N, "not-null");
--              C.Unique   := Gen.Utils.Get_Attribute (N, "unique");
--           end;
      end Prepare_Attribute;

      --  ------------------------------
      --  Register the column definition in the table
      --  ------------------------------
      procedure Prepare_Attribute (Bean   : in out Gen.Model.Beans.Bean_Definition'Class;
                                   Column : in Model_Element_Access) is
         C    : Column_Definition_Access;
      begin
         Log.Info ("Prepare class attribute {0}", Column.Name);

         Bean.Add_Attribute (Column.Name, C);
         C.Set_Comment (Column.Get_Comment);
         if Column.all in Attribute_Element'Class then
            declare
               Attr : Attribute_Element_Access := Attribute_Element'Class (Column.all)'Access;
            begin
               if Attr.Data_Type /= null then
                  C.Type_Name := Attr.Data_Type.Name;
               end if;
               C.Not_Null := Attr.Multiplicity_Lower > 0;
            end;
         end if;
      end Prepare_Attribute;

      --  ------------------------------
      --  Register the column definition in the table
      --  ------------------------------
      procedure Prepare_Association (Table  : in out Gen.Model.Tables.Table_Definition'Class;
                                     Node   : in Model_Element_Access) is
         A    : Association_Definition_Access;
         Assoc : Association_End_Element_Access := Association_End_Element'Class (Node.all)'Access;
      begin
         Log.Info ("Prepare class association {0}", Assoc.Name);

         Table.Add_Association (Assoc.Name, A);
         A.Set_Comment (Assoc.Get_Comment);
         A.Type_Name := To_Unbounded_String (Assoc.Source_Element.Get_Qualified_Name);
      end Prepare_Association;

      --  Prepare a UML/XMI class:
      --   o if the class has the <<Dynamo.ADO.table>> stereotype, create a table definition.
      procedure Prepare_Class (Pkg  : in out Gen.Model.Packages.Package_Definition'Class;
                               Item : in Gen.Model.XMI.Model_Element_Access) is
         Class : constant Class_Element_Access := Class_Element'Class (Item.all)'Access;
         Name  : Unbounded_String := Gen.Utils.Qualify_Name (Pkg.Name, Class.Name);
      begin
         Log.Info ("Prepare class {0}", Name);

         if Item.Has_Stereotype (Handler.Table_Stereotype) then
            Log.Debug ("Class {0} recognized as a database table", Name);
            declare
               Table : constant Table_Definition_Access := Gen.Model.Tables.Create_Table (Name);
            begin
               Table.Set_Comment (Item.Get_Comment);
               Model.Register_Table (Table);
               Table.Target := Name;
               Iterate_For_Table (Table.all, Class.Attributes, Prepare_Attribute'Access);
               Iterate_For_Table (Table.all, Class.Associations, Prepare_Association'Access);
            end;

         elsif Item.Has_Stereotype (Handler.Bean_Stereotype) then
            Log.Debug ("Class {0} recognized as a bean", Name);
            declare
               Bean : constant Bean_Definition_Access := Gen.Model.Beans.Create_Bean (Name);
            begin
               Model.Register_Bean (Bean);
               Bean.Set_Comment (Item.Get_Comment);
               Bean.Target := Name;
               Iterate_For_Bean (Bean.all, Class.Attributes, Prepare_Attribute'Access);
            end;

         else
            Log.Warn ("UML class {0} not generated: no <<Bean>> and no <<Table>> stereotype",
                       To_String (Name));
         end if;
      exception
         when E : others =>
            Log.Error ("Exception", E);
      end Prepare_Class;

      --  ------------------------------
      --  Collect the enum literal for the enum definition.
      --  ------------------------------
      procedure Prepare_Enum_Literal (Enum : in out Gen.Model.Enums.Enum_Definition'Class;
                                      Item : in Gen.Model.XMI.Model_Element_Access) is
         Value : Gen.Model.Enums.Value_Definition_Access;
      begin
         Log.Info ("Prepare enum literal {0}", Item.Name);

         Enum.Add_Value (To_String (Item.Name), Value);
      end Prepare_Enum_Literal;

      --  ------------------------------
      --  Register the enum in the model for the generation.
      --  ------------------------------
      procedure Prepare_Enum (Pkg  : in out Gen.Model.Packages.Package_Definition'Class;
                              Item : in Gen.Model.XMI.Model_Element_Access) is
         Name  : constant String := Item.Get_Qualified_Name;
         Enum  : Gen.Model.Enums.Enum_Definition_Access;
      begin
         Log.Info ("Prepare enum {0}", Name);

         Enum := Gen.Model.Enums.Create_Enum (To_Unbounded_String (Name));
         Enum.Set_Comment (Item.Get_Comment);
         Model.Register_Enum (Enum);

         Iterate_For_Enum (Enum.all, Item.Elements, Prepare_Enum_Literal'Access);
      end Prepare_Enum;

      procedure Prepare_Package (Id   : in Ada.Strings.Unbounded.Unbounded_String;
                                 Item : in Gen.Model.XMI.Model_Element_Access) is
         pragma Unreferenced (Id);

         Pkg : constant Package_Element_Access := Package_Element'Class (Item.all)'Access;
         Name : constant String := Pkg.Get_Qualified_Name;
         P   : Gen.Model.Packages.Package_Definition_Access
           := new Gen.Model.Packages.Package_Definition;
      begin
         Log.Info ("Prepare package {0}", Name);
         P.Name := To_Unbounded_String (Name);

         if Item.Has_Stereotype (Handler.Data_Model_Stereotype) then
            Log.Info ("Package {0} has the <<DataModel>> stereotype", Name);

         else
            Log.Info ("Package {0} does not have the <<DataModel>> stereotype.", Name);
         end if;

         P.Set_Comment (Pkg.Get_Comment);
         Iterate_For_Package (P.all, Pkg.Enums, Prepare_Enum'Access);
         Iterate_For_Package (P.all, Pkg.Classes, Prepare_Class'Access);
      end Prepare_Package;

      procedure Prepare_Model (Key   : in Ada.Strings.Unbounded.Unbounded_String;
                               Model : in out Gen.Model.XMI.Model_Map.Map) is
      begin
         Log.Info ("Preparing model {0}", Key);

         Gen.Model.XMI.Iterate (Model   => Model,
                                On      => Gen.Model.XMI.XMI_PACKAGE,
                                Process => Prepare_Package'Access);
      end Prepare_Model;

      Iter : Gen.Model.XMI.UML_Model_Map.Cursor := Handler.Nodes.First;
   begin
      Log.Debug ("Preparing the XMI model for generation");

      Gen.Model.XMI.Reconcile (Handler.Nodes,
                               Context.Get_Parameter (Gen.Configs.GEN_DEBUG_ENABLE));

      --  Get the Dynamo stereotype definitions.
      Handler.Table_Stereotype := Find_Stereotype (Handler.Nodes,
                                                   "Dynamo.xmi",
                                                   "ADO.Table",
                                                   Gen.Model.XMI.BY_NAME);
      Handler.PK_Stereotype := Find_Stereotype (Handler.Nodes,
                                                "Dynamo.xmi",
                                                "ADO.PK",
                                                Gen.Model.XMI.BY_NAME);
      Handler.FK_Stereotype := Find_Stereotype (Handler.Nodes,
                                                "Dynamo.xmi",
                                                "ADO.FK",
                                                Gen.Model.XMI.BY_NAME);
      Handler.Data_Model_Stereotype := Find_Stereotype (Handler.Nodes,
                                                        "Dynamo.xmi",
                                                        "ADO.DataModel",
                                                        Gen.Model.XMI.BY_NAME);
      Handler.Bean_Stereotype := Find_Stereotype (Handler.Nodes,
                                                  "Dynamo.xmi",
                                                  "AWA.Bean",
                                                  Gen.Model.XMI.BY_NAME);
      Handler.Has_List_Tag := Find_Tag_Definition (Handler.Nodes,
                                                   "Dynamo.xmi",
                                                   "dynamo.table.hasList",
                                                   Gen.Model.XMI.BY_NAME);

      while Gen.Model.XMI.UML_Model_Map.Has_Element (Iter) loop
         Handler.Nodes.Update_Element (Iter, Prepare_Model'Access);
         Gen.Model.XMI.UML_Model_Map.Next (Iter);
      end loop;

      if Model.Has_Packages then
         Context.Add_Generation (Name => GEN_PACKAGE_SPEC, Mode => ITERATION_PACKAGE,
                                 Mapping => Gen.Model.Mappings.ADA_MAPPING);
         Context.Add_Generation (Name => GEN_PACKAGE_BODY, Mode => ITERATION_PACKAGE,
                                 Mapping => Gen.Model.Mappings.ADA_MAPPING);
      end if;
   end Prepare;

   --  ------------------------------
   --  Read the UML configuration files that define the pre-defined types, stereotypes
   --  and other components used by a model.  These files are XMI files as well.
   --  All the XMI files in the UML config directory are read.
   --  ------------------------------
   procedure Read_UML_Configuration (Handler : in out Artifact;
                                     Context : in out Generator'Class) is
      use Ada.Directories;

      Path    : constant String := Context.Get_Parameter (Gen.Configs.GEN_UML_DIR);
      Filter  : constant Filter_Type := (Ordinary_File => True, others => False);
      Search  : Search_Type;
      Ent     : Directory_Entry_Type;
   begin
      Log.Info ("Reading the UML configuration files from {0}", Path);

      Handler.Has_Config  := True;
      Handler.Initialized := True;
      Start_Search (Search, Directory => Path, Pattern => "*.xmi", Filter => Filter);

      --  Collect the files in the vector array.
      while More_Entries (Search) loop
         Get_Next_Entry (Search, Ent);

         Handler.Read_Model (Full_Name (Ent), Context);
      end loop;
   end Read_UML_Configuration;

   --  ------------------------------
   --  Read the UML/XMI model file.
   --  ------------------------------
   procedure Read_Model (Handler : in out Artifact;
                         File    : in String;
                         Context : in out Generator'Class) is
      procedure Read (Key   : in Ada.Strings.Unbounded.Unbounded_String;
                      Model : in out Gen.Model.XMI.Model_Map.Map);

      type Parser is new Util.Serialize.IO.XML.Parser with null record;

      --  Report an error while parsing the input stream.  The error message will be reported
      --  on the logger associated with the parser.  The parser will be set as in error so that
      --  the <b>Has_Error</b> function will return True after parsing the whole file.
      overriding
      procedure Error (Handler : in out Parser;
                       Message : in String);

      --  ------------------------------
      --  Report an error while parsing the input stream.  The error message will be reported
      --  on the logger associated with the parser.  The parser will be set as in error so that
      --  the <b>Has_Error</b> function will return True after parsing the whole file.
      --  ------------------------------
      overriding
      procedure Error (Handler : in out Parser;
                       Message : in String) is
      begin
         if Ada.Strings.Fixed.Index (Message, "Invalid absolute IRI") > 0
           and then Ada.Strings.Fixed.Index (Message, "org.omg.xmi.namespace.UML") > 0 then
            return;
         end if;
         Context.Error ("{0}: {1}",
                        Parser'Class (Handler).Get_Location,
                        Message);
      end Error;

      procedure Read (Key   : in Ada.Strings.Unbounded.Unbounded_String;
                      Model : in out Gen.Model.XMI.Model_Map.Map) is
         pragma Unreferenced (Key);

         Info   : aliased XMI_Info;
         Reader : Parser;
         N      : constant Natural := Util.Strings.Rindex (File, '.');
      begin
         Info.Model := Model'Unchecked_Access;
         Reader.Add_Mapping ("XMI", XMI_Mapping'Access);
         if Context.Get_Parameter (Gen.Configs.GEN_DEBUG_ENABLE) then
            Reader.Dump (Log);
         end if;
         XMI_Mapper.Set_Context (Reader, Info'Unchecked_Access);

         if N > 0 and then File (N .. File'Last) = ".zargo" then
            declare
               Name   : constant String := Ada.Directories.Base_Name (File);
               Pipe   : aliased Util.Streams.Pipes.Pipe_Stream;
               Buffer : Util.Streams.Buffered.Buffered_Stream;
            begin
               Pipe.Open ("unzip -cq " & File & " " & Name & ".xmi",
                          Util.Processes.READ);
               Buffer.Initialize (null, Pipe'Unchecked_Access, 4096);
               Reader.Parse (Buffer);
               Pipe.Close;
            end;
         else
            Reader.Parse (File);
         end if;
      end Read;

      UML  : Gen.Model.XMI.Model_Map.Map;
      Name : constant Ada.Strings.Unbounded.Unbounded_String
        := Ada.Strings.Unbounded.To_Unbounded_String (Ada.Directories.Simple_Name (File));
   begin
      Log.Info ("Reading XMI {0}", File);

      if not Handler.Has_Config then
         Handler.Has_Config := True;
         Handler.Read_UML_Configuration (Context);
      end if;
      Handler.Nodes.Include (Name, UML);
      Handler.Nodes.Update_Element (Handler.Nodes.Find (Name),
                                    Read'Access);
   end Read_Model;

begin

   --  Define the XMI mapping.
   XMI_Mapping.Add_Mapping ("**/Package/@name", FIELD_PACKAGE_NAME);
   XMI_Mapping.Add_Mapping ("**/Package/@xmi.id", FIELD_PACKAGE_ID);
   XMI_Mapping.Add_Mapping ("**/Package", FIELD_PACKAGE_END);
   XMI_Mapping.Add_Mapping ("**/Namespace.ownedElement", FIELD_NAMESPACE);

   XMI_Mapping.Add_Mapping ("**/Class/@name", FIELD_CLASS_NAME);
   XMI_Mapping.Add_Mapping ("**/Class/@xmi.id", FIELD_CLASS_ID);
   XMI_Mapping.Add_Mapping ("**/Class/@visibility", FIELD_CLASS_VISIBILITY);
   XMI_Mapping.Add_Mapping ("**/Class", FIELD_CLASS_END);

   --  Class attribute mapping.
   XMI_Mapping.Add_Mapping ("**/Attribute/@name", FIELD_ATTRIBUTE_NAME);
   XMI_Mapping.Add_Mapping ("**/Attribute/@xmi.id", FIELD_ATTRIBUTE_ID);
   XMI_Mapping.Add_Mapping ("**/Attribute/@visibility", FIELD_ATTRIBUTE_VISIBILITY);
   XMI_Mapping.Add_Mapping ("**/Attribute/@changeability", FIELD_ATTRIBUTE_CHANGEABILITY);
   XMI_Mapping.Add_Mapping ("**/Attribute.initialValue/Expression/@body",
                            FIELD_ATTRIBUTE_INITIAL_VALUE);
   XMI_Mapping.Add_Mapping ("**/Attribute", FIELD_ATTRIBUTE);

   --  Field multiplicity.
   XMI_Mapping.Add_Mapping ("**/MultiplicityRange/@lower", FIELD_MULTIPLICITY_LOWER);
   XMI_Mapping.Add_Mapping ("**/MultiplicityRange/@upper", FIELD_MULTIPLICITY_UPPER);

   --  Operation mapping.
   XMI_Mapping.Add_Mapping ("**/Operation/@name", FIELD_OPERATION_NAME);
   XMI_Mapping.Add_Mapping ("**/Operation/@xmi.id", FIELD_ATTRIBUTE_ID);
   XMI_Mapping.Add_Mapping ("**/Operation", FIELD_OPERATION_END);
   XMI_Mapping.Add_Mapping ("**/Parameter/@xname", FIELD_PARAMETER_NAME);

--     XMI_Mapping.Add_Mapping ("Package/*/Class/*/Attribute/*/MultiplicityRange/@lower",
--                              FIELD_MULTIPLICITY_LOWER);
--     XMI_Mapping.Add_Mapping ("Package/*/Class/*/Attribute/*/MultiplicityRange/@upper",
--                              FIELD_MULTIPLICITY_UPPER);
--     XMI_Mapping.Add_Mapping ("Package/*/Class/*/Operation/@name",
--                              FIELD_OPERATION_NAME);
--     XMI_Mapping.Add_Mapping ("Package/*/Association/*/@name",
--                              FIELD_ASSOCIATION_NAME);
--     XMI_Mapping.Add_Mapping ("Package/*/Association/*/@visibility",
--                              FIELD_ASSOCIATION_VISIBILITY);
--     XMI_Mapping.Add_Mapping ("Package/*/Association/*/@aggregation",
--                              FIELD_ASSOCIATION_AGGREGATION);

   --  Association mapping.
   XMI_Mapping.Add_Mapping ("**/Association/@name", FIELD_ASSOCIATION_NAME);
   XMI_Mapping.Add_Mapping ("**/Association/@xmi.id", FIELD_ASSOCIATION_ID);
   XMI_Mapping.Add_Mapping ("**/Association", FIELD_ASSOCIATION);

   --  Association end mapping.
   XMI_Mapping.Add_Mapping ("**/AssociationEnd/@name", FIELD_ASSOCIATION_END_NAME);
   XMI_Mapping.Add_Mapping ("**/AssociationEnd/@xmi.id", FIELD_ASSOCIATION_END_ID);
   XMI_Mapping.Add_Mapping ("**/AssociationEnd/@visibility", FIELD_ASSOCIATION_END_VISIBILITY);
   XMI_Mapping.Add_Mapping ("**/AssociationEnd/@isNavigable", FIELD_ASSOCIATION_END_NAVIGABLE);
   XMI_Mapping.Add_Mapping ("**/AssociationEnd", FIELD_ASSOCIATION_END);
   XMI_Mapping.Add_Mapping ("**/AssociationEnd.participant/Class/@xmi.idref",
                            FIELD_ASSOCIATION_CLASS_ID);

   --  Comment mapping.
   XMI_Mapping.Add_Mapping ("**/Comment/@xmi.id", FIELD_COMMENT_ID);
   XMI_Mapping.Add_Mapping ("**/Comment/@body", FIELD_VALUE);
   XMI_Mapping.Add_Mapping ("**/Comment/Comment.annotatedElement/Class/@xmi.idref", FIELD_ID_REF);
   XMI_Mapping.Add_Mapping ("**/Comment/Comment.annotatedElement/Attribute/@xmi.idref", FIELD_ID_REF);
   XMI_Mapping.Add_Mapping ("**/Comment/Comment.annotatedElement/Enumeration/@xmi.idref",
                            FIELD_ID_REF);
   XMI_Mapping.Add_Mapping ("**/Comment", FIELD_COMMENT);

   --  Tagged value mapping.
   XMI_Mapping.Add_Mapping ("**/TaggedValue/@xmi.id", FIELD_ID);
   XMI_Mapping.Add_Mapping ("**/TaggedValue/TaggedValue.dataValue", FIELD_VALUE);
   XMI_Mapping.Add_Mapping ("**/TaggedValue/TaggedValue.type/@xmi.idref", FIELD_ID_REF);
   XMI_Mapping.Add_Mapping ("**/TaggedValue/TaggedValue.type/TagDefinition/@xmi.idref",
                            FIELD_ID_REF);
   XMI_Mapping.Add_Mapping ("**/TaggedValue/TaggedValue.type/TagDefinition/@href", FIELD_HREF);
   XMI_Mapping.Add_Mapping ("**/TaggedValue", FIELD_TAGGED_VALUE);

   --  Tag definition mapping.
   XMI_Mapping.Add_Mapping ("**/TagDefinition/@xmi.id", FIELD_TAG_DEFINITION_ID);
   XMI_Mapping.Add_Mapping ("**/TagDefinition/@name", FIELD_TAG_DEFINITION_NAME);
   XMI_Mapping.Add_Mapping ("**/TagDefinition", FIELD_TAG_DEFINITION);

   --  Stereotype mapping.
   XMI_Mapping.Add_Mapping ("**/Stereotype/@href", FIELD_STEREOTYPE_HREF);
   XMI_Mapping.Add_Mapping ("**/Stereotype/@xmi.id", FIELD_STEREOTYPE_ID);
   XMI_Mapping.Add_Mapping ("**/Stereotype/@name", FIELD_STEREOTYPE_NAME);
   XMI_Mapping.Add_Mapping ("**/Stereotype", FIELD_STEREOTYPE);

   --  Enumeration mapping.
   XMI_Mapping.Add_Mapping ("**/Enumeration/@xmi.id", FIELD_ID);
   XMI_Mapping.Add_Mapping ("**/Enumeration/@name", FIELD_ENUMERATION);
   XMI_Mapping.Add_Mapping ("**/Enumeration/Enumeration.literal/EnumerationLiteral/@xmi.id",
                            FIELD_ID);
   XMI_Mapping.Add_Mapping ("**/Enumeration/Enumeration.literal/EnumerationLiteral/@name",
                            FIELD_NAME);
   XMI_Mapping.Add_Mapping ("**/Enumeration/Enumeration.literal/EnumerationLiteral",
                            FIELD_ENUMERATION_LITERAL);
   XMI_Mapping.Add_Mapping ("**/Enumeration/@href", FIELD_ENUMERATION_HREF);
   XMI_Mapping.Add_Mapping ("**/Enumeration/@xmi.idref", FIELD_ENUMERATION_HREF);

   XMI_Mapping.Add_Mapping ("**/Classifier/@xmi.idref", FIELD_CLASSIFIER_HREF);
   XMI_Mapping.Add_Mapping ("**/Classifier/@href", FIELD_CLASSIFIER_HREF);

   --  Data type mapping.
   XMI_Mapping.Add_Mapping ("**/DataType/@xmi.id", FIELD_ID);
   XMI_Mapping.Add_Mapping ("**/DataType/@name", FIELD_NAME);
   XMI_Mapping.Add_Mapping ("**/DataType", FIELD_DATA_TYPE);
   XMI_Mapping.Add_Mapping ("**/DataType/@href", FIELD_DATA_TYPE_HREF);
   XMI_Mapping.Add_Mapping ("**/DataType/@xmi.idref", FIELD_DATA_TYPE_HREF);
   XMI_Mapping.Add_Mapping ("**/StructuralFeature.type/Class/@xmi.idref",
                            FIELD_DATA_TYPE_HREF);

end Gen.Artifacts.XMI;
