% close all;
clear;clc;format compact;fclose all;
set(groot,'defaulttextinterpreter','latex');
set(groot, 'defaultAxesTickLabelInterpreter','latex');
set(groot, 'defaultLegendInterpreter','latex');

% create sample design
Partdsgn1 = avlDesignGeometryClass;

%% modify design
% wing parameters
% Input file names
Partdsgn1.input_file_name        = 'partDsgn1.avl'; % File name for .avl file
Partdsgn1.run_file_name          = 'testRunFile.run';
Partdsgn1.exe_file_name          = 'exeFile';
% Output file names
Partdsgn1.result_file_name       = 'partDsgn1_results';
Partdsgn1.lookup_table_file_name = 'partDsgn1_lookupTables';

% Name for design in the input file
Partdsgn1.design_name            = 'partDsgn1'; % String at top of input file defining the name

Partdsgn1.reference_point = [1.0;0;0];

Partdsgn1.wing_chord = 1;
Partdsgn1.wing_AR = 10;
Partdsgn1.wing_sweep = 2;
Partdsgn1.wing_dihedral = 0;
Partdsgn1.wing_TR = 0.8;
Partdsgn1.wing_incidence_angle = 0;
Partdsgn1.wing_naca_airfoil = '4412';
Partdsgn1.wing_airfoil_ClLimits = [-1.75 1.75];

Partdsgn1.wing_Nspanwise = 20;
Partdsgn1.wing_Nchordwise = 5;

Partdsgn1.h_stab_LE = 6;
Partdsgn1.h_stab_chord = 0.6;
Partdsgn1.h_stab_AR = 8;
Partdsgn1.h_stab_sweep = 5;
Partdsgn1.h_stab_dihedral = 0;
Partdsgn1.h_stab_TR = 0.8;
Partdsgn1.h_stab_naca_airfoil = '0012';
Partdsgn1.h_stab_airfoil_ClLimits = [-1.75 1.75];

Partdsgn1.v_stab_LE = 6;
Partdsgn1.v_stab_chord = 0.75;
Partdsgn1.v_stab_AR = 3.5;
Partdsgn1.v_stab_sweep = 10;
Partdsgn1.v_stab_TR = 0.8;
Partdsgn1.v_stab_naca_airfoil = '0012';
Partdsgn1.v_stab_airfoil_ClLimits = [-1.75 1.75];

%% run AVL
alpha_range = [-55 55];
n_steps = 75;

avlPartitioned(Partdsgn1,alpha_range,n_steps)

%% plot polars
plotPartitionedPolars(Partdsgn1.lookup_table_file_name)

