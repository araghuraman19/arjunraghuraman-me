(* ::Package:: *)

(* ============================================================
   Alpha-Pinene Multiresponse Parameter Estimation
   Method: determinant criterion + rotated responses (Bates & Watts)
   No Bayesian / Cholesky-based likelihood machinery included --
   just the WLS-style determinant criterion and QR-based rotation.
   ============================================================ *)

(* ---- 0. Export directory: same folder as this notebook ---- *)
exportDir = NotebookDirectory[];
If[exportDir === $Failed, exportDir = Directory[]]; (* fallback if run outside a notebook front end *)

(* ---- 1. Data (8 time points, 5 responses, 189.5C run) ---- *)
Xcond = {1230, 3060, 4920, 7800, 10680, 15030, 22620, 36420};
data = {
  {88.35, 7.3, 2.3, 0.4, 1.75},
  {76.4, 15.6, 4.5, 0.7, 2.8},
  {65.1, 23.1, 5.3, 1.1, 5.8},
  {50.4, 32.9, 6.0, 1.5, 9.3},
  {37.5, 42.7, 6.0, 1.9, 12.0},
  {25.9, 49.1, 5.9, 2.2, 17.0},
  {14.0, 57.4, 5.1, 2.6, 21.0},
  {4.5, 63.1, 3.8, 2.9, 25.7}
};
n = Length[Xcond]; m = 5;
labels = {"\[Alpha]-pinene", "Dipentene", "Allo-ocimene", "Pyronene", "Dimer"};

(* ---- 2. Linear kinetics ODE model, log-parameterized rates ---- *)
odeSol[phi1_?NumericQ, phi2_?NumericQ, phi3_?NumericQ, phi4_?NumericQ, phi5_?NumericQ] :=
  NDSolve[{
     f1'[t] == -(Exp[phi1] + Exp[phi2]) f1[t],
     f2'[t] ==  Exp[phi1] f1[t],
     f3'[t] ==  Exp[phi2] f1[t] - (Exp[phi3] + Exp[phi4]) f3[t] + Exp[phi5] f5[t],
     f4'[t] ==  Exp[phi3] f3[t],
     f5'[t] ==  Exp[phi4] f3[t] - Exp[phi5] f5[t],
     f1[0] == 100, f2[0] == 0, f3[0] == 0, f4[0] == 0, f5[0] == 0
   }, {f1, f2, f3, f4, f5}, {t, 0, 40000}][[1]];

(* ---- 3. Rotation matrix: orthonormal basis orthogonal to the
   known dependencies (imputed response y4, and the mass-balance
   direction, i.e. the all-ones vector) ---- *)
Dmat = Transpose[{{0, 0, 0, 1, 0}, {1, 1, 1, 1, 1}}];
Bmat = Transpose[Orthogonalize[NullSpace[Transpose[Dmat]]]]; (* 5 x 3 *)

(* ---- 4. Determinant criterion on the 3 rotated responses, via QR
   decomposition of Z itself (Bates & Watts' recommended computational
   device, Section 4.2) rather than forming Z^T Z directly -- forming
   Z^T Z squares the condition number of Z before you even try to take
   a determinant of it, which is exactly the instability QR avoids. *)
detCriterion[phi1_?NumericQ, phi2_?NumericQ, phi3_?NumericQ, phi4_?NumericQ, phi5_?NumericQ] :=
  Module[{soln, fpred, eps, r},
    soln = odeSol[phi1, phi2, phi3, phi4, phi5];
    fpred = Table[Through[{f1, f2, f3, f4, f5}[Xcond[[u]]]] /. soln, {u, 1, n}];
    eps = data . Bmat - fpred . Bmat;
    {q, r} = QRDecomposition[eps]; (* q unused, kept only for the destructuring *)
    (* |Z^T Z| = |R|^2 = (product of R's diagonal)^2, so log|Z^T Z| = 2 * sum(log|R_ii|) *)
    2*Total[Log[Abs[Diagonal[r]]]]
  ];

sol = FindMinimum[
   {detCriterion[phi1, phi2, phi3, phi4, phi5],
    -15 < phi1 < -5, -15 < phi2 < -5, -15 < phi3 < -5, -15 < phi4 < -5, -15 < phi5 < -5},
   {{phi1, -10}, {phi2, -10}, {phi3, -10}, {phi4, -10}, {phi5, -10}}
];
phiOpt = {phi1, phi2, phi3, phi4, phi5} /. sol[[2]];
thetaOpt = Exp[phiOpt];
Print["phi (log-scale rates): ", phiOpt];
Print["theta (rate constants): ", thetaOpt];

(* ---- 5. Fitted curves at the optimum, over the full time range ---- *)
solnOpt = odeSol @@ phiOpt;
fpredOpt = Table[Through[{f1, f2, f3, f4, f5}[Xcond[[u]]]] /. solnOpt, {u, 1, n}];

(* ---- 6. Approximate parameter standard errors (Fisher-information
   sandwich, using the estimated 3x3 rotated-response covariance) ---- *)
epsOpt = data . Bmat - fpredOpt . Bmat;
ZtZOpt = Transpose[epsOpt] . epsOpt;
SigmaHat = ZtZOpt/n;
VinvHat = Inverse[SigmaHat];

rotatedFittedAt[phiVec_] := Module[{soln, fpred},
   soln = odeSol @@ phiVec;
   fpred = Table[Through[{f1, f2, f3, f4, f5}[Xcond[[u]]]] /. soln, {u, 1, n}];
   fpred . Bmat
];
h = 1*^-5;
baseFit = rotatedFittedAt[phiOpt];
jacByParam = Table[(rotatedFittedAt[phiOpt + h UnitVector[5, k]] - baseFit)/h, {k, 1, 5}];
FInfo = Sum[
   Table[Sum[jacByParam[[p, u, i]] VinvHat[[i, j]] jacByParam[[q, u, j]], {i, 3}, {j, 3}], {p, 5}, {q, 5}],
   {u, 1, n}];
covPhi = Inverse[FInfo];
sePhi = Sqrt[Diagonal[covPhi]];
corrPhi = covPhi/Outer[Times, sePhi, sePhi];
Print["approx. std. errors (log scale): ", sePhi];

(* ---- 6b. Table 4.5-style summary (own reproduction, own numbers --
   this is our own asymptotic approximation, not a claim to reproduce
   Bates & Watts' exact numerical method or degrees-of-freedom
   correction) ---- *)
pathLabels = {"1 \[Rule] 2", "1 \[Rule] 3", "3 \[Rule] 4", "3 \[Rule] 5", "5 \[Rule] 3"};
table45 = Grid[
   Prepend[
    Table[
     {pathLabels[[k]], NumberForm[thetaOpt[[k]]*10^5, {5, 2}], NumberForm[phiOpt[[k]], {5, 3}],
       NumberForm[sePhi[[k]], {4, 3}]}~Join~
      Table[If[j <= k, NumberForm[corrPhi[[k, j]], {4, 2}], ""], {j, 1, 5}],
     {k, 1, 5}],
    {"Path", "\[Theta] (\[Times]10\[Wedge]-5)", "\[Phi]=ln\[Theta]", "Std.Error",
      "\[Rho]1", "\[Rho]2", "\[Rho]3", "\[Rho]4", "\[Rho]5"}],
   Frame -> All, Alignment -> Center, Background -> {None, {LightGray, None}}];
Print["Reproduction of Table 4.5 (own asymptotic approximation):"];
Print[table45];

(* ---- 7. Model criticism: singular values of the centered data
   matrix and of the residual matrix (detects dependencies) ---- *)
Ybar = Mean[data];
Ycentered = # - Ybar & /@ data;
svdCentered = SingularValueList[Ycentered];
svdResidual = SingularValueList[data - fpredOpt];
Print["singular values, centered data: ", svdCentered];
Print["singular values, residuals: ", svdResidual];

(* ---- 8. Plots (export at high resolution for the website) ---- *)
tgrid = Range[0, 40000, 200];
curves = Table[Table[{t, (Through[{f1, f2, f3, f4, f5}[t]] /. solnOpt)[[k]]}, {t, tgrid}], {k, 1, 5}];
obsPoints = Table[Table[{Xcond[[u]], data[[u, k]]}, {u, 1, n}], {k, 1, 5}];
fitPlot = ListLinePlot[curves,
   PlotStyle -> Dashed, PlotLegends -> labels,
   PlotRange -> {{0, 40000}, {0, 100}}, Frame -> True,
   FrameLabel -> {"Time (min)", "Concentration (%)"},
   PlotLabel -> "Alpha-pinene pyrolysis: fitted vs observed", ImageSize -> 640];
allPoints = Flatten[MapIndexed[
    Function[{pts, idx}, {PointSize[0.012], ColorData[97][idx[[1]]], Point /@ pts}], obsPoints], 1];
fitVsObservedPlot = Show[fitPlot, Graphics[allPoints]];
Export[FileNameJoin[{exportDir, "alpha_pinene_fit_vs_observed.png"}], fitVsObservedPlot, ImageResolution -> 300];

residRotated = data . Bmat - fpredOpt . Bmat;
residPlot = ListPlot[
   Table[Transpose[{Xcond, residRotated[[All, k]]}], {k, 1, 3}],
   PlotLegends -> {"rotated resp 1", "rotated resp 2", "rotated resp 3"},
   Frame -> True, FrameLabel -> {"Time (min)", "Residual"},
   GridLines -> {None, {0}}, PlotLabel -> "Rotated-response residuals vs time",
   ImageSize -> 500];
Export[FileNameJoin[{exportDir, "rotated_residuals_vs_time.png"}], residPlot, ImageResolution -> 300];

svdPlot = ListLogPlot[{svdCentered, svdResidual},
   PlotMarkers -> {Automatic, 10}, PlotStyle -> Thick,
   PlotLegends -> {"centered data matrix", "residual matrix (5-response fit)"},
   Frame -> True, FrameLabel -> {"Singular value index", "Singular value (log scale)"},
   PlotLabel -> "Singular values: detecting response dependencies",
   Joined -> True, ImageSize -> 520];
Export[FileNameJoin[{exportDir, "singular_values_diagnostic.png"}], svdPlot, ImageResolution -> 300];

Print["Done. PNGs exported to: ", exportDir];
