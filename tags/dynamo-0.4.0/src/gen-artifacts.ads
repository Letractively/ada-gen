-----------------------------------------------------------------------
--  gen-artifacts -- Artifacts for Code Generator
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
with Ada.Finalization;

with DOM.Core;
with Gen.Model;
with Gen.Model.Packages;
with Gen.Model.Projects;

--  The <b>Gen.Artifacts</b> package represents the methods and process to prepare,
--  control and realize the code generation.
package Gen.Artifacts is

   type Iteration_Mode is (ITERATION_PACKAGE, ITERATION_TABLE);

   type Generator is limited interface;

   --  Report an error and set the exit status accordingly
   procedure Error (Handler : in out Generator;
                    Message : in String;
                    Arg1    : in String := "";
                    Arg2    : in String := "") is abstract;

   --  Tell the generator to activate the generation of the given template name.
   --  The name is a property name that must be defined in generator.properties to
   --  indicate the template file.  Several artifacts can trigger the generation
   --  of a given template.  The template is generated only once.
   procedure Add_Generation (Handler : in out Generator;
                             Name    : in String;
                             Mode    : in Iteration_Mode) is abstract;

   --  ------------------------------
   --  Model Definition
   --  ------------------------------
   type Artifact is abstract new Ada.Finalization.Limited_Controlled with private;

   --  After the configuration file is read, processes the node whose root
   --  is passed in <b>Node</b> and initializes the <b>Model</b> with the information.
   procedure Initialize (Handler : in Artifact;
                         Path    : in String;
                         Node    : in DOM.Core.Node;
                         Model   : in out Gen.Model.Packages.Model_Definition'Class;
                         Context : in out Generator'Class) is abstract;

   --  Prepare the model after all the configuration files have been read and before
   --  actually invoking the generation.
   procedure Prepare (Handler : in Artifact;
                      Model   : in out Gen.Model.Packages.Model_Definition'Class;
                      Context : in out Generator'Class) is null;

   --  After the generation, perform a finalization step for the generation process.
   procedure Finish (Handler : in Artifact;
                     Model   : in out Gen.Model.Packages.Model_Definition'Class;
                     Project : in out Gen.Model.Projects.Project_Definition'Class;
                     Context : in out Generator'Class) is null;

private

   type Artifact is abstract new Ada.Finalization.Limited_Controlled with record
      Node : DOM.Core.Node;
   end record;

end Gen.Artifacts;