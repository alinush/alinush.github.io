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
\def\msm#1#2{\red{#1}^{#2}}
\def\vmsm#1#2{\msm{#1}{#2}}
\def\fmsm#1#2{\green{^{[\mathsf{f}]}}\msm{#1}{#2}}
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
\def\GaddOne#1{\Gadd{\Gr_1}{#1}}
\def\GmulOne#1{\Gmul{\Gr_1}{#1}}
\def\msmOne#1{\msm{\Gr_1}{#1}}
\def\vmsmOne#1{\vmsm{\Gr_1}{#1}}
\def\fmsmOne#1{\fmsm{\Gr_1}{#1}}
\def\fmsmOneSmall#1#2{\fmsmSmall{\Gr_1}{#1}/{#2}}
\def\vmsmOneSmall#1#2{\vmsmSmall{\Gr_1}{#1}/{#2}}
%
% G_2 group
%
\def\GaddTwo#1{\Gadd{\Gr_2}{#1}}
\def\GmulTwo#1{\Gmul{\Gr_2}{#1}}
\def\msmTwo#1{\msm{\Gr_2}{#1}}
\def\vmsmTwo#1{\vmsm{\Gr_2}{#1}}
\def\fmsmTwo#1{\fmsm{\Gr_2}{#1}}
\def\fmsmTwoSmall#1#2{\fmsmSmall{\Gr_2}{#1}/{#2}}
\def\vmsmTwoSmall#1#2{\vmsmSmall{\Gr_2}{#1}/{#2}}
%
% Target group
%
\def\GaddTarget#1{\Gadd{\Gr_T}{#1}}
\def\GmulTarget#1{\Gmul{\Gr_T}{#1}}
\def\msmTarget#1{\msm{\Gr_T}{#1}}
\def\vmsmTarget#1{\vmsm{\Gr_T}{#1}}
\def\fmsmTarget#1{\fmsm{\Gr_T}{#1}}
\def\fmsmTargetSmall#1#2{\fmsmSmall{\Gr_T}{#1}/{#2}}
\def\vmsmTargetSmall#1#2{\vmsmSmall{\Gr_T}{#1}/{#2}}
%
% A single pairing
\def\pairing{\mathbb{P}}
% #1 is the # of pairings
\def\multipair#1{\mathbb{P}^{#1}}
$</div> <!-- $ -->
