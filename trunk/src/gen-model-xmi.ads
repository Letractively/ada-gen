-----------------------------------------------------------------------
--  gen-model-xmi -- UML-XMI model
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

with Ada.Containers.Hashed_Maps;
with Ada.Strings.Unbounded;
with Ada.Strings.Unbounded.Hash;
with Ada.Containers.Vectors;

with Util.Beans.Objects;

package Gen.Model.XMI is

   use Ada.Strings.Unbounded;

   type Element_Type is (
                         XMI_PACKAGE,
                         XMI_CLASS,
                         XMI_ASSOCIATION,
                         XMI_ASSOCIATION_END,
                         XMI_ATTRIBUTE,
                         XMI_OPERATION,
                         XMI_ENUMERATION,
                         XMI_ENUMERATION_LITERAL,
                         XMI_TAGGED_VALUE,
                         XMI_TAG_DEFINITION,
                         XMI_DATA_TYPE,
                         XMI_STEREOTYPE,
                         XMI_COMMENT);

   type Visibility_Type is (VISIBILITY_PUBLIC,
                            VISIBILITY_PACKAGE,
                            VISIBILITY_PROTECTED,
                            VISIBILITY_PRIVATE);

   type Model_Element;
   type Tagged_Value_Element;
   type Model_Element_Access is access all Model_Element'Class;
   type Tagged_Value_Element_Access is access all Tagged_Value_Element'Class;

   --  Define a list of model elements.
   package Model_Vectors is
      new Ada.Containers.Vectors (Index_Type   => Positive,
                                  Element_Type => Model_Element_Access);

   subtype Model_Vector is Model_Vectors.Vector;

   subtype Model_Cursor is Model_Vectors.Cursor;

   --  Define a map to search an element from its XMI ID.
   package Model_Map is
     new Ada.Containers.Hashed_Maps (Key_Type        => Unbounded_String,
                                     Element_Type    => Model_Element_Access,
                                     Hash            => Ada.Strings.Unbounded.Hash,
                                     Equivalent_Keys => "=");

   subtype Model_Map_Cursor is Model_Map.Cursor;
   type Model_Map_Access is access all Model_Map.Map;

   --  Returns true if the table cursor contains a valid table
   function Has_Element (Position : in Model_Map_Cursor) return Boolean
                         renames Model_Map.Has_Element;

   --  Returns the table definition.
   function Element (Position : in Model_Map_Cursor) return Model_Element_Access
                     renames Model_Map.Element;

   --  Move the iterator to the next table definition.
   procedure Next (Position : in out Model_Map_Cursor)
                   renames Model_Map.Next;

   --  Iterate on the model element of the type <tt>On</tt> and execute the <tt>Process</tt>
   --  procedure.
   procedure Iterate (Model   : in Model_Map.Map;
                      On      : in Element_Type;
                      Process : not null access procedure (Id : in Unbounded_String;
                                                           Node : in Model_Element_Access));

   --  Iterate over the model elements of the list.
   procedure Iterate (List    : in Model_Vector;
                      Process : not null access procedure (Item : in Model_Element_Access));

   --  Map of UML models indexed on the model name.
   package UML_Model_Map is new
     Ada.Containers.Hashed_Maps (Key_Type        => Unbounded_String,
                                 Element_Type    => Model_Map.Map,
                                 Hash            => Ada.Strings.Unbounded.Hash,
                                 Equivalent_Keys => "=",
                                 "="             => Model_Map."=");
   subtype UML_Model is UML_Model_Map.Map;

   --  Find the model element with the given XMI id.
   --  Returns null if the model element is not found.
   function Find (Model : in Model_Map.Map;
                  Id    : in Ada.Strings.Unbounded.Unbounded_String) return Model_Element_Access;

   --  Find the model element within all loaded UML models.
   --  Returns null if the model element is not found.
   function Find (Model   : in UML_Model;
                  Current : in Model_Map.Map;
                  Id      : in Ada.Strings.Unbounded.Unbounded_String)
                  return Model_Element_Access;

   --  Dump the XMI model elements.
   procedure Dump (Map : in Model_Map.Map);

   --  Reconcile all the UML model elements by resolving all the references to UML elements.
   procedure Reconcile (Model : in out UML_Model);

   --  ------------------------------
   --  Model Element
   --  ------------------------------
   type Model_Element (Model : Model_Map_Access) is abstract new Definition with record
      --  Element XMI id.
      XMI_Id        : Ada.Strings.Unbounded.Unbounded_String;

      --  List of tagged values for the element.
      Tagged_Values : Model_Vector;

      --  Elements contained.
      Elements      : Model_Vector;

      --  Stereotypes associated with the element.
      Stereotypes   : Model_Vector;
   end record;

   --  Get the element type.
   function Get_Type (Node : in Model_Element) return Element_Type is abstract;

   --  Reconcile the element by resolving the references to other elements in the model.
   procedure Reconcile (Node  : in out Model_Element;
                        Model : in UML_Model);

   --  Set the model name.
   procedure Set_Name (Node  : in out Model_Element;
                       Value : in Util.Beans.Objects.Object);

   --  Set the model XMI unique id.
   procedure Set_XMI_Id (Node  : in out Model_Element;
                         Value : in Util.Beans.Objects.Object);

   --  Find the tag value element with the given name.
   --  Returns null if there is no such tag.
   function Find_Tag_Value (Node : in Model_Element;
                            Name : in String) return Tagged_Value_Element_Access;

   --  Returns True if the model element has the stereotype with the given name.
   function Has_Stereotype (Node : in Model_Element;
                            Name : in String) return Boolean;

   --  Get the documentation and comment associated with the model element.
   --  Returns the empty string if there is no comment.
   function Get_Comment (Node : in Model_Element) return String;

   --  ------------------------------
   --  Data type
   --  ------------------------------
   type Data_Type_Element is new Model_Element with null record;
   type Data_Type_Element_Access is access all Data_Type_Element'Class;

   --  Get the element type.
   overriding
   function Get_Type (Node : in Data_Type_Element) return Element_Type;

   --  ------------------------------
   --  Enum
   --  ------------------------------
   type Enum_Element is new Model_Element with null record;
   type Enum_Element_Access is access all Enum_Element'Class;

   --  Get the element type.
   overriding
   function Get_Type (Node : in Enum_Element) return Element_Type;

   procedure Add_Literal (Node : in out Enum_Element;
                          Id   : in Util.Beans.Objects.Object;
                          Name : in Util.Beans.Objects.Object);

   --  ------------------------------
   --  Literal
   --  ------------------------------
   --  The literal describes a possible value for an enum.
   type Literal_Element is new Model_Element with null record;
   type Literal_Element_Access is access all Literal_Element'Class;

   --  Get the element type.
   overriding
   function Get_Type (Node : in Literal_Element) return Element_Type;

   --  ------------------------------
   --  Stereotype
   --  ------------------------------
   type Stereotype_Element is new Model_Element with null record;
   type Stereotype_Element_Access is access all Stereotype_Element'Class;

   --  Get the element type.
   overriding
   function Get_Type (Node : in Stereotype_Element) return Element_Type;

   --  ------------------------------
   --  Comment
   --  ------------------------------
   type Comment_Element is new Model_Element with record
      Text       : Ada.Strings.Unbounded.Unbounded_String;
      Ref_Id     : Ada.Strings.Unbounded.Unbounded_String;
   end record;
   type Comment_Element_Access is access all Comment_Element'Class;

   --  Get the element type.
   overriding
   function Get_Type (Node : in Comment_Element) return Element_Type;

   --  ------------------------------
   --  An operation
   --  ------------------------------
   type Operation_Element is new Model_Element with record
      Visibility : Visibility_Type := VISIBILITY_PUBLIC;
   end record;
   type Operation_Element_Access is access all Operation_Element'Class;

   --  Get the element type.
   overriding
   function Get_Type (Node : in Operation_Element) return Element_Type;

   --  ------------------------------
   --  An attribute
   --  ------------------------------
   type Attribute_Element is new Model_Element with record
      Ref_Id     : Ada.Strings.Unbounded.Unbounded_String;
      Visibility : Visibility_Type := VISIBILITY_PUBLIC;
   end record;
   type Attribute_Element_Access is access all Attribute_Element'Class;

   --  Get the element type.
   overriding
   function Get_Type (Node : in Attribute_Element) return Element_Type;

   --  ------------------------------
   --  An association end
   --  ------------------------------
   type Association_End_Element is new Model_Element with record
      Visibility : Visibility_Type := VISIBILITY_PUBLIC;
   end record;
   type Association_End_Element_Access is access all Association_End_Element'Class;

   --  Get the element type.
   overriding
   function Get_Type (Node : in Association_End_Element) return Element_Type;

   --  ------------------------------
   --  An association
   --  ------------------------------
   type Association_Element is new Model_Element with record
      Visibility : Visibility_Type := VISIBILITY_PUBLIC;
   end record;
   type Association_Element_Access is access all Association_Element'Class;

   --  Get the element type.
   overriding
   function Get_Type (Node : in Association_Element) return Element_Type;

   --  ------------------------------
   --  Tag Definition
   --  ------------------------------
   TAG_DOCUMENTATION : constant String := "documentation";
   TAG_AUTHOR        : constant String := "author";

   type Tag_Definition_Element is new Model_Element with record
      Multiplicity_Lower : Natural := 0;
      Multiplicity_Upper : Natural := 0;
   end record;
   type Tag_Definition_Element_Access is access all Tag_Definition_Element'Class;

   --  Get the element type.
   overriding
   function Get_Type (Node : in Tag_Definition_Element) return Element_Type;

   --  ------------------------------
   --  Tagged value
   --  ------------------------------
   type Tagged_Value_Element is new Model_Element with record
      Value      : Ada.Strings.Unbounded.Unbounded_String;
      Value_Type : Ada.Strings.Unbounded.Unbounded_String;
      Ref_Id     : Ada.Strings.Unbounded.Unbounded_String;
      Tag_Def    : Tag_Definition_Element_Access;
   end record;

   --  Get the element type.
   overriding
   function Get_Type (Node : in Tagged_Value_Element) return Element_Type;

   --  Reconcile the element by resolving the references to other elements in the model.
   overriding
   procedure Reconcile (Node  : in out Tagged_Value_Element;
                        Model : in UML_Model);

   --  ------------------------------
   --  A class
   --  ------------------------------
   type Class_Element is new Model_Element with record
      Operations   : Model_Vector;
      Attributes   : Model_Vector;
      Associations : Model_Vector;
      Visibility   : Visibility_Type := VISIBILITY_PUBLIC;
   end record;
   type Class_Element_Access is access all Class_Element'Class;

   --  Get the element type.
   overriding
   function Get_Type (Node : in Class_Element) return Element_Type;

   --  ------------------------------
   --  A package
   --  ------------------------------
   type Package_Element;
   type Package_Element_Access is access all Package_Element'Class;

   type Package_Element is new Model_Element with record
      Classes      : Model_Vector;
      Parent       : Package_Element_Access;
   end record;

   --  Get the element type.
   overriding
   function Get_Type (Node : in Package_Element) return Element_Type;

end Gen.Model.XMI;
