-----------------------------------------------------------------------
--  gen-artifacts-docs -- Artifact for documentation
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
with Ada.Containers.Indefinite_Vectors;
with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Strings.Hash;
with Ada.Strings.Unbounded;

with Gen.Model.Packages;

--  with Asis;
--  with Asis.Text;
--  with Asis.Elements;
--  with Asis.Exceptions;
--  with Asis.Errors;
--  with Asis.Implementation;
--  with Asis.Elements;
--  with Asis.Declarations;
--  The <b>Gen.Artifacts.Docs</b> package is an artifact for the generation of
--  application documentation.  Its purpose is to scan the project source files
--  and extract some interesting information for a developer's guide.  The artifact
--  scans the Ada source files, the XML configuration files, the XHTML files.
--
--  The generated documentation is intended to be published on a web site.
--  The Google Wiki style is generated by default.
--
--  1/ In the first step, the project files are scanned and the useful
--     documentation is extracted.
--
--  2/ In the second step, the documentation is merged and reconciled.  Links to
--     documentation pages and references are setup and the final pages are generated.
--
--  Ada
--  ---
--  The documentation starts at the first '== TITLE ==' marker and finishes before the
--  package specification.
--
--  XHTML
--  -----
--  Same as Ada.
--
--  XML Files
--  ----------
--  The documentation is part of the XML and the <b>documentation</b> or <b>description</b>
--  tags are extracted.
package Gen.Artifacts.Docs is

   --  Tag marker (same as Java).
   TAG_CHAR     : constant Character := '@';

   --  Specific tags recognized when analyzing the documentation.
   TAG_AUTHOR   : constant String := "author";
   TAG_TITLE    : constant String := "title";
   TAG_INCLUDE  : constant String := "include";
   TAG_SEE      : constant String := "see";

   --  ------------------------------
   --  Documentation artifact
   --  ------------------------------
   type Artifact is new Gen.Artifacts.Artifact with private;

   --  Prepare the model after all the configuration files have been read and before
   --  actually invoking the generation.
   overriding
   procedure Prepare (Handler : in out Artifact;
                      Model   : in out Gen.Model.Packages.Model_Definition'Class;
                      Context : in out Generator'Class);

private

   type Line_Kind is (L_TEXT, L_LIST, L_LIST_ITEM, L_SEE, L_INCLUDE);

   type Line_Type (Len : Natural) is record
      Kind    : Line_Kind := L_TEXT;
      Content : String (1 .. Len);
   end record;

   package Line_Vectors is
      new Ada.Containers.Indefinite_Vectors (Index_Type   => Positive,
                                             Element_Type => Line_Type);

   type Doc_State is (IN_PARA, IN_SEPARATOR, IN_CODE, IN_CODE_SEPARATOR, IN_LIST);

   type File_Document is record
      Name         : Ada.Strings.Unbounded.Unbounded_String;
      Title        : Ada.Strings.Unbounded.Unbounded_String;
      State        : Doc_State := IN_PARA;
      Line_Number  : Natural := 0;
      Lines        : Line_Vectors.Vector;
      Was_Included : Boolean := False;
   end record;

   package Doc_Maps is
     new Ada.Containers.Indefinite_Hashed_Maps (Key_Type        => String,
                                                Element_Type    => File_Document,
                                                Hash            => Ada.Strings.Hash,
                                                Equivalent_Keys => "=");

   --  Include the document extract represented by <b>Name</b> into the document <b>Into</b>.
   --  The included document is marked so that it will not be generated.
   procedure Include (Docs     : in out Doc_Maps.Map;
                      Into     : in out File_Document;
                      Name     : in String;
                      Position : in Natural);

   --  Generate the project documentation that was collected in <b>Docs</b>.
   --  The documentation is merged so that the @include tags are replaced by the matching
   --  document extracts.
   procedure Generate (Docs : in out Doc_Maps.Map;
                       Dir  : in String);

   --  Returns True if the line indicates a bullet or numbered list.
   function Is_List (Line : in String) return Boolean;

   --  Returns True if the line indicates a code sample.
   function Is_Code (Line : in String) return Boolean;

   --  Append a raw text line to the document.
   procedure Append_Line (Doc  : in out File_Document;
                          Line : in String);

   --  Look and analyze the tag defined on the line.
   procedure Append_Tag (Doc : in out File_Document;
                         Tag : in String);

   --  Analyse the documentation line and collect the documentation text.
   procedure Append (Doc   : in out File_Document;
                     Line  : in String);

   --  After having collected the documentation, terminate the document by making sure
   --  the opened elements are closed.
   procedure Finish (Doc : in out File_Document);

   --  Set the name associated with the document extract.
   procedure Set_Name (Doc  : in out File_Document;
                       Name : in String);

   --  Set the title associated with the document extract.
   procedure Set_Title (Doc   : in out File_Document;
                        Title : in String);

   --  Scan the files in the directory refered to by <b>Path</b> and collect the documentation
   --  in the <b>Docs</b> hashed map.
   procedure Scan_Files (Handler : in out Artifact;
                         Path    : in String;
                         Docs    : in out Doc_Maps.Map);

   --  Read the Ada specification file and collect the useful documentation.
   --  To keep the implementation simple, we don't use the ASIS packages to scan and extract
   --  the documentation.  We don't need to look at the Ada specification itself.  Instead,
   --  we assume that the Ada source follows some Ada style guidelines.
   procedure Read_Ada_File (Handler : in out Artifact;
                            File    : in String;
                            Result  : in out File_Document);

   procedure Read_Xml_File (Handler : in out Artifact;
                            File    : in String;
                            Result  : in out File_Document);

   type Artifact is new Gen.Artifacts.Artifact with record
      Xslt_Command : Ada.Strings.Unbounded.Unbounded_String;
   end record;

end Gen.Artifacts.Docs;
