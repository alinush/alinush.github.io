<div style="display: none;">$
%
% Field operations
%
% #1 is the number of field additions
\def\Fadd#1{#1\ \green{\F^+}}
% #1 is the number of field multiplications
\def\Fmul#1{#1\ \red{\F}^\red{\times}}
%
% Abstract group
%
% #1 is the group
% #2 is the # of group additions
\def\Gadd#1#2{#2\ \green{#1}^\green{+}}
% #2 is the # of scalar muls
\def\Gmul#1#2{#2\ \orange{#1}^\orange{\times}}
% #2 is the MSM size
\def\msm#1#2{\red{#1}^{#2}} % do not use directly use either \fmsm or \vmsm
\def\vmsm#1#2{\green{\mathsf{var}}\text{-}\msm{#1}{#2}}
\def\fmsm#1#2{\msm{#1}{#2}}
\def\fmsmSmall#1#2#3{\fmsm{#1}{#2}/{#3}}
% ...#3 is the max scalar size
\def\vmsmSmall#1#2#3{\vmsm{#1}{#2}/{#3}}
%
% \mathbb{G} group
%
\def\GaddG#1{\Gadd{\Gr}{#1}}
\def\GmulG#1{\Gmul{\Gr}{#1}}
\def\msmG#1{\msm{\Gr}{#1}}
\def\vmsmG#1{\vmsm{\Gr}{#1}}
\def\fmsmG#1{\fmsm{\Gr}{#1}}
\def\fmsmGSmall#1#2{\fmsmSmall{\Gr}{#1}/{#2}}
\def\vmsmGSmall#1#2{\vmsmSmall{\Gr}{#1}/{#2}}
%
% G_1 group
%
% Note: replicating the colors here because cannot get subscript to align with superscript (e.g., $\msmOne{n}$ would render akwardly)
\def\GaddOne#1{\Gadd{\Gr}{#1}_\green{1}}
\def\GmulOne#1{\Gmul{\Gr}{#1}_\orange{1}}
\def\msmOne#1{\msm{\Gr}{#1}_\red{1}}
\def\vmsmOne#1{\vmsm{\Gr}{#1}_\red{1}}
\def\fmsmOne#1{\fmsm{\Gr}{#1}_\red{1}}
\def\fmsmOneSmall#1#2{\fmsmSmall{\Gr}{#1}_\red{1}/{#2}}
\def\vmsmOneSmall#1#2{\vmsmSmall{\Gr}{#1}_\red{1}/{#2}}
%
% G_2 group
%
% Note: same replication as for G_1
\def\GaddTwo#1{\Gadd{\Gr}{#1}_\green{2}}
\def\GmulTwo#1{\Gmul{\Gr}{#1}_\orange{2}}
\def\msmTwo#1{\msm{\Gr}{#1}_\red{2}}
\def\vmsmTwo#1{\vmsm{\Gr}{#1}_\red{2}}
\def\fmsmTwo#1{\fmsm{\Gr}{#1}_\red{2}}
\def\fmsmTwoSmall#1#2{\fmsmSmall{\Gr}{#1}_\red{2}/{#2}}
\def\vmsmTwoSmall#1#2{\vmsmSmall{\Gr}{#1}_\red{2}/{#2}}
%
% Target group
%
% Note: same replication as for G_1
\def\GaddTarget#1{\Gadd{\Gr}{#1}_\green{T}}
\def\GmulTarget#1{\Gmul{\Gr}{#1}_\orange{T}}
\def\msmTarget#1{\msm{\Gr}{#1}_\red{T}}
\def\vmsmTarget#1{\vmsm{\Gr}{#1}_\red{T}}
\def\fmsmTarget#1{\fmsm{\Gr}{#1}_\red{T}}
\def\fmsmTargetSmall#1#2{\fmsmSmall{\Gr}{#1}_\red{T}/{#2}}
\def\vmsmTargetSmall#1#2{\vmsmSmall{\Gr}{#1}_\red{T}/{#2}}
%
% A single pairing
\def\pairing{\mathbb{P}}
% #1 is the # of pairings
\def\multipair#1{\mathbb{P}^{#1}}
$</div> <!-- $ -->
