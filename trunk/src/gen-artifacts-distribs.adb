-----------------------------------------------------------------------
--  gen-artifacts-distribs -- Artifact for distributions
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
with Ada.Directories;
with Ada.Exceptions;

with Util.Files;
with Util.Log.Loggers;

with Gen.Utils;
with Gen.Artifacts.Distribs.Copies;
with Gen.Artifacts.Distribs.Exec;
with Gen.Artifacts.Distribs.Concat;

--  The <b>Gen.Artifacts.Distribs</b> package is an artifact for the generation of
--  application distributions.
package body Gen.Artifacts.Distribs is

   use Util.Log;

   Log : constant Loggers.Logger := Loggers.Create ("Gen.Artifacts.Distribs");

   --  ------------------------------
   --  Create a distribution rule identified by <b>Kind</b>.
   --  The distribution rule is configured according to the DOM tree whose node is <b>Node</b>.
   --  ------------------------------
   function Create_Rule (Kind : in String;
                         Node : in DOM.Core.Node) return Distrib_Rule_Access is
   begin
      Log.Debug ("Creating distribution rule {0}", Kind);

      if Kind = "copy" or Kind = "" then
         return Gen.Artifacts.Distribs.Copies.Create_Rule (Node);
      elsif Kind = "exec" then
         return Gen.Artifacts.Distribs.Exec.Create_Rule (Node);
      elsif Kind = "concat" then
         return Gen.Artifacts.Distribs.Concat.Create_Rule (Node);
      else
         return null;
      end if;
   end Create_Rule;

   --  ------------------------------
   --  After the configuration file is read, processes the node whose root
   --  is passed in <b>Node</b> and initializes the <b>Model</b> with the information.
   --  ------------------------------
   overriding
   procedure Initialize (Handler : in out Artifact;
                         Path    : in String;
                         Node    : in DOM.Core.Node;
                         Model   : in out Gen.Model.Packages.Model_Definition'Class;
                         Context : in out Generator'Class) is

      procedure Register_Rule (O    : in out Gen.Model.Packages.Model_Definition;
                               Node : in DOM.Core.Node);

      procedure Register_Mappings (Model : in out Gen.Model.Packages.Model_Definition;
                                   Node  : in DOM.Core.Node);
      procedure Register_Install (Model : in out Gen.Model.Packages.Model_Definition;
                                  Node  : in DOM.Core.Node);

      --  ------------------------------
      --  Register a new type mapping.
      --  ------------------------------
      procedure Register_Rule (O    : in out Gen.Model.Packages.Model_Definition;
                               Node : in DOM.Core.Node) is
         pragma Unreferenced (O);

         use Ada.Strings.Unbounded;

         Dir  : constant String := To_String (Gen.Model.Get_Attribute (Node, "dir"));
         Mode : constant String := To_String (Gen.Model.Get_Attribute (Node, "mode"));
         Rule : Distrib_Rule_Access := Create_Rule (Kind => Mode, Node => Node);

         --  ------------------------------
         --  Collect the include definitions for the distribution rule.
         --  ------------------------------
         procedure Collect_Includes (Rule  : in out Distrib_Rule_Access;
                                     Node  : in DOM.Core.Node) is
            Name : constant String := To_String (Gen.Model.Get_Attribute (Node, "name"));
         begin
            if Name = "" then
               Context.Error ("Invalid include name {0}", Name);
               return;
            end if;
            Rule.Includes.Append (Name);
         end Collect_Includes;

         procedure Iterate is
           new Gen.Utils.Iterate_Nodes (T => Distrib_Rule_Access,
                                        Process => Collect_Includes);

      begin
         Log.Debug ("Install {0}", Dir);

         if Rule /= null then
            Handler.Rules.Append (Rule);
            Iterate (Rule, Node, "include");
         end if;
      end Register_Rule;

      --  ------------------------------
      --  Register the installation rules.
      --  ------------------------------
      procedure Register_Install (Model : in out Gen.Model.Packages.Model_Definition;
                                  Node  : in DOM.Core.Node) is
         procedure Iterate is
           new Gen.Utils.Iterate_Nodes (T => Gen.Model.Packages.Model_Definition,
                                        Process => Register_Rule);
      begin
         Iterate (Model, Node, "install");
      end Register_Install;

      --  ------------------------------
      --  Register a model mapping
      --  ------------------------------
      procedure Register_Mappings (Model : in out Gen.Model.Packages.Model_Definition;
                                   Node  : in DOM.Core.Node) is
         procedure Iterate is
           new Gen.Utils.Iterate_Nodes (T => Gen.Model.Packages.Model_Definition,
                                        Process => Register_Install);
      begin
         Iterate (Model, Node, "dist");
      end Register_Mappings;

      procedure Iterate is new Gen.Utils.Iterate_Nodes (T => Gen.Model.Packages.Model_Definition,
                                                        Process => Register_Mappings);

   begin
      Log.Debug ("Initializing distrib artifact for the configuration");

      Gen.Artifacts.Artifact (Handler).Initialize (Path, Node, Model, Context);
      Iterate (Gen.Model.Packages.Model_Definition (Model), Node, "package");
   end Initialize;

   --  ------------------------------
   --  Prepare the model after all the configuration files have been read and before
   --  actually invoking the generation.
   --  ------------------------------
   overriding
   procedure Prepare (Handler : in out Artifact;
                      Model   : in out Gen.Model.Packages.Model_Definition'Class;
                      Context : in out Generator'Class) is
      pragma Unreferenced (Model);

      procedure Scan_Rule (Pos : in Distrib_Rule_Vectors.Cursor);
      procedure Scan_Directory (Dir : in String);
      procedure Execute_Rule (Pos : in Distrib_Rule_Vectors.Cursor);


      --  ------------------------------
      --  Process the rule by scaning the directory tree and detecting files that are concerned.
      --  ------------------------------
      procedure Scan_Rule (Pos : in Distrib_Rule_Vectors.Cursor) is
         Rule : constant Distrib_Rule_Access := Distrib_Rule_Vectors.Element (Pos);
         Iter : Directory_List_Vector.Cursor := Handler.Trees.First;
      begin
         Log.Debug ("Scanning rule");

         while Directory_List_Vector.Has_Element (Iter) loop
            Rule.Scan (Directory_List_Vector.Element (Iter).all);
            Directory_List_Vector.Next (Iter);
         end loop;
      end Scan_Rule;

      --  ------------------------------
      --  Execute the rules.
      --  ------------------------------
      procedure Execute_Rule (Pos : in Distrib_Rule_Vectors.Cursor) is
         Rule : constant Distrib_Rule_Access := Distrib_Rule_Vectors.Element (Pos);
         Path : constant String := Context.Get_Result_Directory;
      begin
         Log.Debug ("Process rule");

         Rule.Execute (Path, Context);
      end Execute_Rule;

      --  ------------------------------
      --  Scan the directory collecting the files that must be taken into account and
      --  processed by the distribution rules.
      --  ------------------------------
      procedure Scan_Directory (Dir : in String) is
         Tree : Directory_List_Access :=
           new Directory_List '(Length => 1, Name => ".", Rel_Pos => Dir'Length + 2,
                                Path_Length => Dir'Length, Path => Dir, others => <>);
      begin
         Log.Info ("Scanning directory: {0}", Dir);

         Handler.Trees.Append (Tree);
         Scan (Dir, ".", Tree);
      end Scan_Directory;

   begin
      --  Scan each directory used by the dynamo project.
      Context.Scan_Directories (Scan_Directory'Access);

      --  Apply the rules on the directory tree.
      Handler.Rules.Iterate (Process => Scan_Rule'Access);

      --  Apply the rules on the directory tree.
      Handler.Rules.Iterate (Process => Execute_Rule'Access);
   end Prepare;

   --  ------------------------------
   --  Get the relative path of the directory.
   --  ------------------------------
   function Get_Relative_Path (Dir : in Directory_List) return String is
   begin
      return Dir.Path (Dir.Rel_Pos .. Dir.Path'Last);
   end Get_Relative_Path;

   --  ------------------------------
   --  Get the first source path from the list.
   --  ------------------------------
   function Get_First_Path (From : in File_Vector) return String is
      use type Ada.Containers.Count_Type;
   begin
      if From.Length = 0 then
         return "";
      else
         declare
            File : constant File_Record := From.Element (1);
         begin
            return Util.Files.Compose (File.Dir.Path, File.Name);
         end;
      end if;
   end Get_First_Path;

   --  ------------------------------
   --  Returns true if the file name must be ignored.
   --  ------------------------------
   function Is_Ignored (Name : in String) return Boolean is
   begin
      if Name =  ".svn" then
         return True;
      elsif Name = ".git" then
         return True;
      elsif Name = "CVS" then
         return True;
      elsif Name = "." or else Name = ".." then
         return True;
      else
         return False;
      end if;
   end Is_Ignored;

   --  ------------------------------
   --  Scan the directory whose root path is <b>Path</b> and with the relative path
   --  <b>Rel_Path</b> and build in <b>Dir</b> the list of files and directories.
   --  ------------------------------
   procedure Scan (Path     : in String;
                   Rel_Path : in String;
                   Dir      : in Directory_List_Access) is

      use Ada.Directories;

      Full_Path : constant String := Util.Files.Compose (Path, Rel_Path);

      Filter  : constant Filter_Type := (Ordinary_File => True,
                                         Directory     => True,
                                         others        => False);
      Ent     : Ada.Directories.Directory_Entry_Type;
      Search  : Search_Type;
   begin
      Log.Debug ("Scanning {0}", Full_Path);

      Start_Search (Search, Directory => Full_Path,
                    Pattern => "*", Filter => Filter);
      while More_Entries (Search) loop
         Get_Next_Entry (Search, Ent);
         declare
            Name      : constant String := Simple_Name (Ent);
            File_Path : constant String := Util.Files.Compose (Rel_Path, Name);
            Full_Path : constant String := Ada.Directories.Full_Name (Ent);
         begin
            Log.Debug ("Collect {0}", File_Path);

            if Is_Ignored (Name) then
               Log.Debug ("Ignoring {0}", Name);

            --  If this is a directory, recursively scan it and collect its files.
            elsif Ada.Directories.Kind (Full_Path) = Ada.Directories.Directory then
               declare
                  Sub_Dir : constant Directory_List_Access
                    := new Directory_List '(Length      => Name'Length,
                                            Path_Length => Full_Path'Length,
                                            Rel_Pos     => Full_Path'Length - File_Path'Length,
                                            Name        => Name,
                                            Path        => Full_Path,
                                            others      => <>);
               begin
                  Dir.Directories.Append (Sub_Dir);
                  Scan (Path, File_Path, Sub_Dir);
               end;
            else
               Dir.Files.Append (File_Record '(Length => Name'Length,
                                               Name   => Name,
                                               Dir    => Dir));
            end if;
         end;
      end loop;
   end Scan;

   procedure Execute (Rule    : in out Distrib_Rule;
                      Path    : in String;
                      Context : in out Generator'Class) is
      procedure Process (Key : in String;
                         Files : in out File_Vector);

      procedure Process (Key   : in String;
                         Files : in out File_Vector) is
         Name : constant String := Util.Files.Compose (Path, Key);
      begin
         Distrib_Rule'Class (Rule).Install (Name, Files, Context);

      exception
         when Ex : others =>
            Context.Error ("Install of {0} failed: {1}",
                           Name, Ada.Exceptions.Exception_Message (Ex));
      end Process;

      Iter : File_Tree.Cursor := Rule.Files.First;
   begin
      while File_Tree.Has_Element (Iter) loop
         Rule.Files.Update_Element (Iter, Process'Access);
         File_Tree.Next (Iter);
      end loop;
   end Execute;

   --  ------------------------------
   --  Get the target path associate with the given source file for the distribution rule.
   --  ------------------------------
   function Get_Target_Path (Rule : in Distrib_Rule;
                             File : in File_Record) return String is
      Path : constant String := Get_Relative_Path (File.Dir.all);
   begin
      return Util.Files.Compose (Path, File.Name);
   end Get_Target_Path;

   --  ------------------------------
   --  Get the source path of the file.
   --  ------------------------------
   function Get_Source_Path (Rule : in Distrib_Rule;
                             File : in File_Record) return String is
   begin
      return Util.Files.Compose (File.Dir.Path, File.Name);
   end Get_Source_Path;

   --  ------------------------------
   --  Add the file to be processed by the distribution rule.  The file has a relative
   --  path represented by <b>Path</b>.  The path is relative from the base directory
   --  specified in <b>Base_Dir</b>.
   --  ------------------------------
   procedure Add_Source_File (Rule     : in out Distrib_Rule;
                              Path     : in String;
                              File     : in File_Record) is
      procedure Add_File (Key  : in String;
                          Info : in out File_Vector);

      procedure Add_File (Key  : in String;
                          Info : in out File_Vector) is
         pragma Unreferenced (Key);
      begin
         Info.Append (File);
      end Add_File;

      Target_Path : constant String := Distrib_Rule'Class (Rule).Get_Target_Path (File);
      Pos         : constant File_Tree.Cursor := Rule.Files.Find (Target_Path);
   begin
      Log.Debug ("Adding {0}", Target_Path);

      if File_Tree.Has_Element (Pos) then
         Rule.Files.Update_Element (Pos, Add_File'Access);
      else
         declare
            Info : File_Vector;
         begin
            Info.Append (File);
            Rule.Files.Insert (Target_Path, Info);
         end;
      end if;
   end Add_Source_File;

   procedure Scan (Rule : in out Distrib_Rule;
                   Dir  : in Directory_List) is
      procedure Scan_Pattern (Pos : in Util.Strings.Vectors.Cursor);

      procedure Scan_Pattern (Pos : in Util.Strings.Vectors.Cursor) is
         Pattern : constant String := Util.Strings.Vectors.Element (Pos);
      begin
         Rule.Scan (Dir, ".", Pattern);
      end Scan_Pattern;

   begin
      Rule.Includes.Iterate (Scan_Pattern'Access);
   end Scan;

   procedure Scan (Rule     : in out Distrib_Rule;
                   Dir      : in Directory_List;
                   Base_Dir : in String;
                   Pattern  : in String) is

      procedure Collect_Subdirs (Name_Pattern : in String);
      procedure Collect_Files (Name_Pattern : in String);

      --  **/*.xhtml
      --  bin/**
      --  bin/**/test.bin
      N   : constant Natural := Util.Strings.Index (Pattern, '/');
      Pos : Natural := Pattern'First;

      procedure Collect_Files (Name_Pattern : in String) is
         procedure Collect_File (File : in File_Record);

         Ext_Pos : Natural := 0;

         procedure Collect_File (File : in File_Record) is
         begin
            Log.Debug ("Check {0} - {1}", Base_Dir, File.Name);

            if File.Name = Name_Pattern or Name_Pattern = "*" or Name_Pattern = "**" then
               Rule.Add_Source_File (Base_Dir, File);
            elsif Ext_Pos > 0 then
               declare
                  Pos : constant Natural := Util.Strings.Rindex (File.Name, '.');
               begin
                  if Pos > 0 and
                  then File.Name (Pos .. File.Name'Last) = Name_Pattern (Ext_Pos .. Name_Pattern'Last) then
                     Rule.Add_Source_File (Base_Dir, File);
                  end if;
               end;
            end if;
         end Collect_File;

         Iter : File_Record_Vectors.Cursor := Dir.Files.First;
      begin
         if Name_Pattern'Length > 1 and then Name_Pattern (Name_Pattern'First) = '*'
           and then Name_Pattern (Name_Pattern'First + 1) = '.' then
            Ext_Pos := Name_Pattern'First + 1;
         end if;
         while File_Record_Vectors.Has_Element (Iter) loop
            File_Record_Vectors.Query_Element (Iter, Collect_File'Access);
            File_Record_Vectors.Next (Iter);
         end loop;
      end Collect_Files;

      procedure Collect_Subdirs (Name_Pattern : in String) is

         procedure Collect_Dir (Sub_Dir : in Directory_List_Access) is
         begin
            if Name_Pattern = Sub_Dir.Name or else Name_Pattern = "*" then
               Rule.Scan (Sub_Dir.all, Base_Dir,
                          Pattern (Pos .. Pattern'Last));
            end if;
         end Collect_Dir;

         Iter : Directory_List_Vector.Cursor := Dir.Directories.First;
      begin
         while Directory_List_Vector.Has_Element (Iter) loop
            Directory_List_Vector.Query_Element (Iter, Collect_Dir'Access);
            Directory_List_Vector.Next (Iter);
         end loop;
      end Collect_Subdirs;

      Next : Natural;
   begin
      Log.Debug ("Scan {0}/{1} for pattern {2}", Base_Dir, Dir.Name, Pattern);

      if N > 0 then
         if Pattern = "**" then
            Collect_Subdirs (Name_Pattern => "**");
            Collect_Files (Name_Pattern => "*");
            return;

         elsif Pattern (Pattern'First .. N) = "*/" then
            Pos := N + 1;
            Collect_Subdirs (Name_Pattern => "*");

         elsif Pattern (Pattern'First .. N) = "**/" then
            Collect_Subdirs (Name_Pattern => "*");

         else
            Pos := N + 1;
            Collect_Subdirs (Name_Pattern => Pattern (Pattern'First .. N - 1));
            return;
         end if;
         Next := Util.Strings.Index (Pattern, '/', N + 1);
         if Next = 0 then
            Collect_Files (Name_Pattern => Pattern (N + 1 .. Pattern'Last));
         end if;
      end if;
      if N = 0 then
         --  No more directory
         Collect_Files (Name_Pattern => Pattern);
      end if;
   end Scan;

end Gen.Artifacts.Distribs;
