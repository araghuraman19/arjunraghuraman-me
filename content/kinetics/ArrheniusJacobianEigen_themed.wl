(* ::Package:: *)

(* ::Title:: *)
(*Arrhenius: Jacobian, information matrix J^T J, and its eigensystem*)
(*Standard form vs. centered (reference-temperature) form*)


(* ::Text:: *)
(*Steps*)
(*  1. Simulate rate constants over a 40 C range (50-90 C).*)
(*  2. Fit k = A Exp[-Ea/(R T)]  and  k = kref Exp[-(Ea/R)(1/T - 1/Tref)].*)
(*  3. Symbolic Jacobian, then the Jacobian evaluated at the optimum.*)
(*  4. Information matrix J^T J: determinant, eigenvalues, eigenvectors, condition number.*)
(*  5. The same after putting the columns on a common scale (needed for a fair comparison).*)
(*  6. What "singular" and "ill-conditioned" mean.*)
(*  7. Figures (exported at 300 dpi): sensitivity columns, confidence regions with eigenvector axes,*)
(*     condition number vs. Tref, and condition number vs. width of the temperature range.*)
(**)
(*The chain of reasoning: Cov(theta) = sigma^2 Inverse[J^T J]. A small eigenvalue lambda of J^T J becomes a large*)
(*eigenvalue 1/lambda of the covariance along the same eigenvector, so a high condition number means a long, thin*)
(*confidence region and strongly correlated estimates.*)
(**)
(*Ea is in J/mol throughout.*)


ClearAll["Global`*"];


(* ::Section:: *)
(*1. Simulated data*)


Rg = 8.314462618;                     (* J mol^-1 K^-1 *)
EaTrue = 80000.;                       (* J/mol *)
ATrue = 0.01 Exp[EaTrue/(Rg 343.15)];  (* chosen so that k(70 C) = 0.01 s^-1 *)

temps = Flatten[Table[{t, t}, {t, 273.15 + Range[50., 90., 10.]}]];   (* 50, 60, 70, 80, 90 C, duplicates *)
n = Length[temps];
sigma = 0.001;                         (* constant additive error, s^-1 *)
SeedRandom[42];
kObs = (ATrue Exp[-EaTrue/(Rg #)] & /@ temps) + RandomVariate[NormalDistribution[0, sigma], n];
data = Transpose[{temps, kObs}];


(* ::Section:: *)
(*2. Fits*)


(* Standard form. Starting values come from a straight-line fit of ln k vs 1/T. *)
lin = LinearModelFit[Transpose[{1/temps, Log[Clip[kObs, {10^-6, Infinity}]]}], x, x];
{A0, Ea0} = {Exp[#[[1]]], -#[[2]] Rg} &[lin["BestFitParameters"]];

fitStd = NonlinearModelFit[data, A Exp[-Ea/(Rg T)], {{A, A0}, {Ea, Ea0}}, T];
{Ahat, EaHat} = {A, Ea} /. fitStd["BestFitParameters"];
fitStd["ParameterTable"]

(* Optimal Tref. For least squares on k with constant variance, rho(kref, Ea) = 0 when 1/Tref is the
   k^2-weighted mean of 1/T over the runs. *)
wts = fitStd["PredictedResponse"]^2;
Tref = 1/(Total[wts/temps]/Total[wts]);
{"Tref (K)" -> Tref, "Tref (C)" -> Tref - 273.15}

fitRef = NonlinearModelFit[data, kr Exp[-(Ea/Rg) (1/T - 1/Tref)],
   {{kr, Ahat Exp[-EaHat/(Rg Tref)]}, {Ea, EaHat}}, T];
{krHat, EaHat2} = {kr, Ea} /. fitRef["BestFitParameters"];
fitRef["ParameterTable"]

{"rho standard" -> fitStd["CorrelationMatrix"][[1, 2]],
 "rho centered" -> Chop[fitRef["CorrelationMatrix"][[1, 2]]]}


(* ::Section:: *)
(*3. Jacobians*)


(* ::Subsection:: *)
(*3a. Symbolic Jacobian: one row per run, one column per parameter*)


ClearAll[A, Ea, kr, T, R, TR];   (* note: Tr is a built-in (matrix trace), so the symbolic reference temperature is TR *)
modelStd = A Exp[-Ea/(R T)];
modelRef = kr Exp[-(Ea/R) (1/T - 1/TR)];

jacStdSym = D[modelStd, {{A, Ea}}] // Simplify
(* {Exp[-Ea/(R T)],  -A Exp[-Ea/(R T)]/(R T)}   =  {k/A, -k/(R T)} *)

jacRefSym = D[modelRef, {{kr, Ea}}] // Simplify
(* {Exp[-Ea (1/T - 1/TR)/R],  -kr (1/T - 1/TR) Exp[...]/R}  =  {k/kref, -k (1/T - 1/TR)/R} *)

(* Ratio of column 2 to column 1 at each run: nearly constant means nearly proportional columns *)
{Simplify[jacStdSym[[2]]/jacStdSym[[1]]], Simplify[jacRefSym[[2]]/jacRefSym[[1]]]}
(* {-A/(R T),  -kr (1/T - 1/TR)/R} *)


(* ::Subsection:: *)
(*3b. Jacobian at the optimum (n x 2 numeric matrix)*)


Jstd = jacStdSym /. {A -> Ahat, Ea -> EaHat, R -> Rg, T -> #} & /@ temps;
Jref = jacRefSym /. {kr -> krHat, Ea -> EaHat2, R -> Rg, TR -> Tref, T -> #} & /@ temps;

TableForm[Transpose[{temps - 273.15, Jstd[[All, 1]], Jstd[[All, 2]], Jref[[All, 1]], Jref[[All, 2]]}],
 TableHeadings -> {None, {"T (C)", "dk/dA", "dk/dEa", "dk/dkref", "dk/dEa (centered)"}}]
(* Standard: both columns are positive multiples of k (up to sign), so they rise together.
   Centered: dk/dEa changes sign near Tref, but dk/dkref does not. *)


(* ::Section:: *)
(*4. Information matrix J^T J (raw units)*)


Mstd = Transpose[Jstd] . Jstd;
Mref = Transpose[Jref] . Jref;

info[M_] := Module[{vals, vecs},
   {vals, vecs} = Eigensystem[M];                   (* sorted largest to smallest *)
   <|"Matrix" -> MatrixForm[M], "Det" -> Det[M], "Eigenvalues" -> vals,
     "Eigenvectors (rows)" -> MatrixForm[vecs], "Condition number" -> vals[[1]]/vals[[2]]|>];

info[Mstd]
info[Mref]


(* ::Text:: *)
(*Caution: the raw numbers are dominated by units. A is about 10^10 s^-1 and Ea about 10^5 J/mol, so dk/dA and*)
(*dk/dEa differ by many orders of magnitude, and both condition numbers come out enormous (here 5.5 x 10^16 for the*)
(*standard form and 2.2 x 10^13 for the centered form). Each eigenvector is then just the A axis or the Ea axis.*)
(*Det also prints a Det::luc "badly conditioned" warning for both, which is a units effect too. Raw J^T J cannot*)
(*answer "are the parameters confounded?". The columns need to be on a common scale first. The correlation*)
(*matrix already does this, which is why it is scale-free.*)


(* ::Section:: *)
(*5. J^T J on a common scale*)


(* ::Subsection:: *)
(*5a. Unit-length columns: J^T J becomes the matrix of cosines between the sensitivity vectors*)


unitCols[J_] := Transpose[Normalize /@ Transpose[J]];

MstdN = Transpose[unitCols[Jstd]] . unitCols[Jstd];
MrefN = Transpose[unitCols[Jref]] . unitCols[Jref];

info[MstdN]
info[MrefN]
(* With unit columns, J^T J = {{1, c}, {c, 1}}, where c = cos(angle between columns).
   Its eigenvalues are exactly 1 + |c| and 1 - |c|.
   Standard: c = -0.99986, so the eigenvalues are 1.99986 and 0.000137, a condition number of 14,628.
   Centered at the optimal Tref: c = 0, so both eigenvalues are 1, a condition number of 1 (perfectly conditioned).
   The angle between the columns is 0.95 degrees vs. 90 degrees. *)

{"angle std (deg)" -> ArcCos[Abs[MstdN[[1, 2]]]]/Degree, "angle ref (deg)" -> ArcCos[Abs[MrefN[[1, 2]]]]/Degree}


(* ::Subsection:: *)
(*5b. Relative sensitivities: columns are theta_j dk/dtheta_j (the response to a 100 % change in each parameter)*)


MstdS = Transpose[Jstd . DiagonalMatrix[{Ahat, EaHat}]] . (Jstd . DiagonalMatrix[{Ahat, EaHat}]);
MrefS = Transpose[Jref . DiagonalMatrix[{krHat, EaHat2}]] . (Jref . DiagonalMatrix[{krHat, EaHat2}]);
info[MstdS]
info[MrefS]
(* Condition numbers: 2.6 x 10^6 (standard) vs. 5.2 (centered).
   Note that Det is the SAME for both (6.47 x 10^-6). Going from (ln A, ln Ea) to (ln kref, ln Ea) is a shear with
   unit determinant, so the total information (the area of the confidence ellipse) does not change.
   Reparameterization changes the SHAPE, not the amount: a thin diagonal needle becomes an axis-aligned ellipse. *)


(* ::Text:: *)
(*Reading the small-eigenvalue eigenvector of the standard form (5b). Its components are (d ln A, d ln Ea) =*)
(*(0.99929, 0.03780) up to sign. Moving the parameters along this direction changes k the least. So*)
(*   d ln A / d ln Ea = 26.4,   i.e.   d ln A = dEa/(R T* )   with  R T* = Ea/26.4.*)
(*That is the compensation rule from before (raise Ea, raise A by Exp[dEa/(R T)]). It gives T* = 360.2 K, almost*)
(*exactly the optimal Tref of 360.3 K.*)

{vals, vecs} = Eigensystem[MstdS];
vSmall = vecs[[2]];
"T* from small eigenvector (K)" -> EaHat (vSmall[[2]]/vSmall[[1]])/Rg


(* ::Section:: *)
(*6. What "singular" means*)


(* ::Text:: *)
(*A square matrix M is singular if it has no inverse. These statements are all equivalent:*)
(*   Det[M] = 0*)
(*   at least one eigenvalue is 0*)
(*   there is a nonzero vector v with M.v = 0 (the null space is not just {0})*)
(*   the columns are linearly dependent (rank < number of columns)*)
(*For M = J^T J, v.M.v = |J.v|^2, so M.v = 0 exactly when J.v = 0. That means some combination of parameter changes v*)
(*leaves every prediction unchanged to first order. The data carry no information about that direction, and*)
(*Cov = sigma^2 Inverse[M] would be infinite along it.*)
(**)
(*"Nearly singular" (ill-conditioned) means an eigenvalue is tiny compared with the largest one. Det is a poor test*)
(*because it depends on units (rescale A by 10^6 and Det changes by 10^12). Use instead:*)
(*   the condition number  lambda_max/lambda_min,  after putting the columns on a common scale (Section 5)*)
(*   equivalently, |rho| close to 1, or a near-zero angle between the sensitivity columns*)
(*The eigenvector belonging to the small eigenvalue is the poorly determined parameter combination: the long*)
(*axis of the confidence ellipse, along which the variance is proportional to 1/lambda_min.*)

MatrixRank[{{1, 2}, {2, 4}}]   (* tiny exactly-singular example: column 2 = 2 x column 1, so the rank is 1 and Det = 0 *)


(* ::Section:: *)
(*7. Figures*)


(* ::Text:: *)
(*Four figures for the case study, exported at 300 dpi next to this file (or to the notebook folder / working*)
(*directory). Colors: orange = standard form, blue = centered form, green dashed = centered at the midpoint.*)
(*The palette was checked for color-vision-deficiency separation; every series also carries a direct label.*)


exportDir = Which[
   StringQ[$InputFileName] && $InputFileName =!= "", DirectoryName[$InputFileName],
   $FrontEnd =!= Null && Quiet[StringQ[NotebookDirectory[]]], NotebookDirectory[],
   True, Directory[]];
(* Theme switch. "light" reproduces the original figures; "dark" matches the website's dark tokens
   (global.css: background #18191b, text #ece9e3, muted #9a988f, grid #2a2b2f) and adds a "-dark" suffix to
   every exported file name. Set from the command line:  wolframscript -file ArrheniusJacobianEigen.wl dark  *)
theme = If[Length[$ScriptCommandLine] > 1 && MemberQ[{"light", "dark"}, Last[$ScriptCommandLine]],
   Last[$ScriptCommandLine], "light"];
{bgC, ink, inkMuted, gridC, frameC, guideC, bandC, regionOpacity, suffix} = Switch[theme,
   "light", {White, GrayLevel[0.15], GrayLevel[0.45], GrayLevel[0.88], GrayLevel[0.55], GrayLevel[0.35],
     RGBColor[0.93, 0.95, 0.97], 0.12, ""},
   "dark", {RGBColor["#18191b"], RGBColor["#ece9e3"], RGBColor["#9a988f"], RGBColor["#2a2b2f"], RGBColor["#7f7d75"],
     RGBColor["#9a988f"], RGBColor["#212226"], 0.2, "-dark"}];
exportFig[name_String, g_] := Export[FileNameJoin[{exportDir, StringReplace[name, ".png" -> suffix <> ".png"]}], g,
   ImageResolution -> 300, Background -> bgC];

(* Data colors. On #18191b the original blue is only 4:1 against the background, so it is lightened slightly
   (to 5.3:1, in line with the orange 5.5:1 and green 6.3:1). *)
cStd = RGBColor["#eb6834"]; cRef = RGBColor[If[theme == "dark", "#4a8fe7", "#2a78d6"]]; cMid = RGBColor["#1baf7a"];
fl[x_, y_] := {Style[x, 12, ink], Style[y, 12, ink]};
style = {Frame -> {{True, False}, {True, False}}, FrameStyle -> Directive[frameC, AbsoluteThickness[0.8]],
   FrameTicksStyle -> Directive[ink, 11], LabelStyle -> Directive[ink, 12, FontFamily -> "Helvetica"],
   GridLinesStyle -> Directive[gridC, AbsoluteThickness[0.6]], Background -> bgC, ImagePadding -> {{60, 20}, {50, 35}}};
styleNoTicks = style;
style = Append[style, FrameTicks -> {{Automatic, None}, {Range[50, 90, 10], None}}];


(* ::Subsection:: *)
(*Fig. 1  The sensitivity columns of J (each scaled to unit length)*)


(* Each column of J is normalized over the 10 runs, so the two curves can be compared directly.
   Standard form: the curves lie on top of each other (columns 0.95 degrees apart) -> nearly singular J^T J.
   Centered form: -dk/dEa changes sign at Tref, so the columns are 90 degrees apart -> J^T J is diagonal. *)
TC = temps[[;; ;; 2]] - 273.15;
uS = unitCols[Jstd][[;; ;; 2]]; uR = unitCols[Jref][[;; ;; 2]];
angS = ArcCos[Abs[MstdN[[1, 2]]]]/Degree; angR = ArcCos[Abs[MrefN[[1, 2]]]]/Degree;

panel[u_, col_, title_, labs_] := ListLinePlot[{Transpose[{TC, u[[All, 1]]}], Transpose[{TC, -u[[All, 2]]}]},
   PlotStyle -> {Directive[col, AbsoluteThickness[2]], Directive[col, AbsoluteThickness[2], Dashing[{6, 4}]]},
   PlotMarkers -> {{Graphics[{col, Disk[]}], 9}, {Graphics[{bgC, EdgeForm[{col, AbsoluteThickness[1.6]}], Disk[]}], 9}},
   PlotRange -> {{48, 104}, {-0.45, 0.85}}, GridLines -> {None, {0}}, PlotLabel -> Style[title, 13, ink],
   FrameLabel -> fl["Temperature (\[Degree]C)", "Normalized sensitivity"],
   Epilog -> labs, ImageSize -> 440, Evaluate[style]];

fig1 = GraphicsRow[{
   panel[uS, cStd, Row[{"Standard form: columns ", NumberForm[angS, 2], "\[Degree] apart"}],
     {Text[Style["\[PartialD]k/\[PartialD]A and \[Minus]\[PartialD]k/\[PartialD]Ea\nlie on top of each other", 11, ink], {52, 0.5}, {-1, 0}]}],
   panel[uR, cRef, Row[{"Centered form: columns ", Round[angR], "\[Degree] apart"}],
     {Text[Style["\[PartialD]k/\[PartialD]\!\(\*SubscriptBox[\(k\), \(ref\)]\)", 11, ink], {91.5, uR[[-1, 1]]}, {-1, 0}],
      Text[Style["\[Minus]\[PartialD]k/\[PartialD]Ea", 11, ink], {91.5, -uR[[-1, 2]]}, {-1, 0}]}]},
  Spacings -> 10, ImageSize -> 920, Background -> bgC]
exportFig["Fig1_sensitivity_columns.png", fig1];


(* ::Subsection:: *)
(*Fig. 2  Joint 95% confidence regions, with the eigenvectors of J^T J as the axes*)


(* Coordinates are relative changes, delta ln(theta), so both panels use the same units.
   Coloured boundary: exact region  S(theta) <= S_min (1 + p/(n-p) F(p, n-p; 0.95)).
   Grey lines: the eigenvectors of the relative-sensitivity J^T J (Section 5b), drawn as the axes of the
   linear-approximation ellipse. Semi-axis length = Sqrt[p F s^2 / lambda], so a small eigenvalue gives a long axis.
   The exact boundary is traced along rays in eigen-coordinates, because the standard-form region is far too thin
   for ContourPlot's grid. *)
p = 2; s2 = fitStd["EstimatedVariance"]; fCrit = InverseCDF[FRatioDistribution[p, n - p], 0.95];
ssStd[x_?NumericQ, y_?NumericQ] := Total[(kObs - (Ahat Exp[x] Exp[-EaHat Exp[y]/(Rg #)] & /@ temps))^2];
ssRef[x_?NumericQ, y_?NumericQ] := Total[(kObs - (krHat Exp[x] Exp[-(EaHat2 Exp[y]/Rg) (1/# - 1/Tref)] & /@ temps))^2];
ssCrit = ssStd[0, 0] (1 + p/(n - p) fCrit);

axesFor[M_] := Module[{vl, vc}, {vl, vc} = Eigensystem[M]; {Sqrt[p fCrit s2/vl], vc, vl}];
{hStd, vStd, lStd} = axesFor[MstdS]; {hRef, vRef, lRef} = axesFor[MrefS];
condS = lStd[[1]]/lStd[[2]]; condR = lRef[[1]]/lRef[[2]];

boundary[ss_, h_, v_] := Table[Module[{dir = h[[1]] Cos[t] v[[1]] + h[[2]] Sin[t] v[[2]], r},
     r = r /. FindRoot[ss @@ (r dir)/ssCrit - 1, {r, 0.3, 3}, Method -> "Brent"]; r dir], {t, 0, 2 Pi, 2 Pi/360}];
bStd = boundary[ssStd, hStd, vStd]; bRef = boundary[ssRef, hRef, vRef];
{"Max boundary residual" -> Max[Abs[Join[ssStd @@@ bStd, ssRef @@@ bRef]/ssCrit - 1]],
 "Region areas (std, centered)" -> {Area[Polygon[bStd]], Area[Polygon[bRef]]}}
(* The two areas agree to within 1 %: the same information, reshaped (equal Det in Section 5b). *)

axisLines[h_, v_] := {guideC, AbsoluteThickness[1], Line[{-h[[1]] v[[1]], h[[1]] v[[1]]}], Line[{-h[[2]] v[[2]], h[[2]] v[[2]]}]};
regionPanel[b_, xr_, col_, title_, xlab_, h_, v_, ann_] := Graphics[{
    {gridC, AbsoluteThickness[0.6], Line[{{-xr, 0}, {xr, 0}}], Line[{{0, -0.11}, {0, 0.11}}]},
    {Opacity[regionOpacity], col, Polygon[b]}, axisLines[h, v], {col, AbsoluteThickness[2.2], Line[b]},
    {ink, PointSize[0.018], Point[{0, 0}]}},   (* in-plot text annotations (ann) left out for the website version *)
   PlotRange -> {{-xr, xr}, {-0.11, 0.11}}, AspectRatio -> 1, PlotLabel -> Style[title, 13, ink],
   FrameLabel -> fl[xlab, "\[Delta] ln Ea  (relative change in Ea)"], ImageSize -> 440, Evaluate[styleNoTicks]];

fig2 = GraphicsRow[{
   regionPanel[bStd, 2.6, cStd, Row[{"Standard form: condition number ", ScientificForm[condS, 2]}],
     "\[Delta] ln A  (relative change in A)", hStd, vStd,
     {Text[Style["Long axis = eigenvector of \!\(\*SubscriptBox[\(\[Lambda]\), \(min\)]\):\nraising Ea is offset by raising A", 11, ink], {-2.5, 0.088}, {-1, 0}],
      Text[Style[Row[{"long : short axis = ", Round[hStd[[2]]/hStd[[1]]], " : 1"}], 11, ink], {0.3, -0.09}, {-1, 0}]}],
   regionPanel[bRef, 0.065, cRef, Row[{"Centered form: condition number ", NumberForm[condR, 2]}],
     "\[Delta] ln \!\(\*SubscriptBox[\(k\), \(ref\)]\)  (relative change in \!\(\*SubscriptBox[\(k\), \(ref\)]\))", hRef, vRef,
     {Text[Style["Axes lie along the parameters:\nno trade-off", 11, ink], {-0.062, 0.1}, {-1, 0}],
      Text[Style[Row[{"long : short axis = ", NumberForm[hRef[[2]]/hRef[[1]], 2], " : 1"}], 11, ink], {0.005, -0.1}, {-1, 0}]}]},
  Spacings -> 10, ImageSize -> 920, Background -> bgC]
exportFig["Fig2_confidence_regions_eigenvectors.png", fig2];
(* Note the x-axis ranges: the standard-form region spans about +/-240 % in A, the centered one about +/-4 % in kref.
   The long:short ratio is the square root of the condition number (Sqrt[2.6 x 10^6] = 1601). *)


(* ::Subsection:: *)
(*Fig. 3  Condition number as a function of Tref*)


(* For unit columns, cond = (1 + |rho|)/(1 - |rho|), so the condition number and the correlation carry the same
   information. With weights k^2:  rho(Tref) = d/Sqrt[d^2 + s^2],  d = (weighted mean of 1/T) - 1/Tref.
   The open circles are refits with NonlinearModelFit at each Tref. *)
u = 1/temps; mW = Total[wts u]/Total[wts]; sW = Sqrt[Total[wts (u - mW)^2]/Total[wts]];
rhoT[TrC_] := With[{d = mW - 1/(TrC + 273.15)}, d/Sqrt[d^2 + sW^2]];
condT[TrC_] := (1 + Abs[rhoT[TrC]])/(1 - Abs[rhoT[TrC]]);
condStdForm = (1 + Abs[MstdN[[1, 2]]])/(1 - Abs[MstdN[[1, 2]]]);
fitAt[TrC_] := With[{Tr0 = TrC + 273.15}, NonlinearModelFit[data, kr Exp[-(Ea/Rg) (1/T - 1/Tr0)],
    {{kr, Ahat Exp[-EaHat/(Rg Tr0)]}, {Ea, EaHat}}, T]];
pts = Table[With[{r = Abs[fitAt[t]["CorrelationMatrix"][[1, 2]]]}, {t, (1 + r)/(1 - r)}], {t, {20, 40, 60, 70, 80, 90, 110, 140}}];
"Fits vs closed form, max relative difference" -> Max[Abs[pts[[All, 2]]/(condT /@ pts[[All, 1]]) - 1]]
TrC = Tref - 273.15;

fig3 = Show[
   LogPlot[condT[t], {t, 0, 160}, PlotStyle -> Directive[cRef, AbsoluteThickness[2.2]], PlotRange -> {{0, 160}, {0.8, 10^5}}, PlotPoints -> 200,
    Prolog -> {{bandC, Rectangle[{50, Log[0.8]}, {90, Log[10^5]}]},
      {cStd, AbsoluteThickness[2.2], Line[{{0, Log[condStdForm]}, {160, Log[condStdForm]}}]}},
    Epilog -> {
      {If[theme == "light", GrayLevel[0.4], guideC], AbsoluteThickness[0.8], Dashing[{2, 3}], Line[{{TrC, Log[0.8]}, {TrC, Log[10^5]}}]},
      Text[Style["data range\n50\[Dash]90 \[Degree]C", 11, inkMuted], {70, Log[3*10^4]}],
      Text[Style[Row[{"standard form (Tref \[Rule] \[Infinity]): ", Round[condStdForm]}], 11, ink], {100, Log[condStdForm 1.9]}, {-1, 0}],
      Text[Style[Row[{"Tref* = ", NumberForm[TrC, {3, 1}], " \[Degree]C:  condition number 1"}], 11, ink], {96, Log[1.25]}, {-1, 0}],
      Text[Style["midpoint 70 \[Degree]C:\ncondition number " <> ToString[Round[condT[70]]] <> " ", 11, ink], {68, Log[condT[70]]}, {1, 0}],
      Text[Style["centered form\n\[LongDash] closed form   \[EmptyCircle] NonlinearModelFit", 11, ink], {108, Log[17]}, {-1, 0}]},
    FrameLabel -> fl["Reference temperature Tref (\[Degree]C)", "Condition number of J\[Transpose]J (unit columns)"],
    PlotLabel -> Style["The condition number falls to 1 only when Tref sits at the weighted center of the data", 13, ink],
    GridLines -> {None, {1, 10, 100, 1000, 10^4}}, ImageSize -> 700, Evaluate[styleNoTicks]],
   ListLogPlot[pts, PlotStyle -> Directive[cRef], PlotMarkers -> {Graphics[{bgC, EdgeForm[{cRef, AbsoluteThickness[1.6]}], Disk[]}], 10}]]
exportFig["Fig3_condition_number_vs_Tref.png", fig3];


(* ::Subsection:: *)
(*Fig. 4  Does a wider temperature range help?*)


(* Noise-free designs: 5 equally spaced temperatures centered on 70 C, true parameters, weights k^2 (least squares on
   k with constant error variance). Result: the standard form is never better than ~1.5 x 10^4 and gets WORSE
   beyond ~40 C, because the k^2 weights pile the information onto the hottest runs, so the weighted spread of 1/T
   stops growing. Centering at the midpoint also gets worse as the range widens (the weighted center moves away
   from the midpoint). Centering at the weighted center gives 1 for every range.
   With constant RELATIVE error (least squares on ln k, equal weights), widening the range would help the standard
   form monotonically; it still would not approach 1. *)
condDesign[width_, refInvT_] := Module[{Ts, w, uu, m, s, d, r},
   Ts = 343.15 + Subdivide[-width/2, width/2, 4];
   w = (ATrue Exp[-EaTrue/(Rg #)] & /@ Ts)^2; uu = 1/Ts;
   m = Total[w uu]/Total[w]; s = Sqrt[Total[w (uu - m)^2]/Total[w]];
   d = m - refInvT[m]; r = Abs[d]/Sqrt[d^2 + s^2]; (1 + r)/(1 - r)];
cStdW[wd_] := condDesign[wd, 0 &];            (* standard form: reference at 1/T = 0 *)
cMidW[wd_] := condDesign[wd, 1/343.15 &];     (* centered at the midpoint, 70 C *)
cOptW[wd_] := condDesign[wd, # &];             (* centered at the weighted center *)

TableForm[Table[{wd, Round[cStdW[wd]], NumberForm[cMidW[wd], 3], cOptW[wd]}, {wd, {10, 20, 40, 60, 100}}],
 TableHeadings -> {None, {"width (C)", "standard", "centered at 70 C", "centered at weighted center"}}]

fig4 = LogPlot[{cStdW[wd], cMidW[wd], cOptW[wd]}, {wd, 5, 100},
   PlotStyle -> {Directive[cStd, AbsoluteThickness[2.2]], Directive[cMid, AbsoluteThickness[2.2], AbsoluteDashing[{8, 5}]], Directive[cRef, AbsoluteThickness[2.2]]},
   PlotRange -> {{0, 104}, {0.7, 10^6}}, GridLines -> {{40}, {1, 10, 100, 1000, 10^4, 10^5}},
   Epilog -> {
     Text[Style["standard form", 11, ink], {60, Log[cStdW[60] 2.4]}, {-1, 0}],
     Text[Style["centered at the midpoint (70 \[Degree]C)", 11, ink], {50, Log[cMidW[50]/3.2]}, {-1, 0}],
     Text[Style["centered at the k\.b2-weighted center: always 1", 11, ink], {42, Log[1.6]}, {-1, 0}],
     Text[Style["this case study (40 \[Degree]C)", 11, inkMuted], {41, Log[3*10^5]}, {-1, 0}]},
   FrameLabel -> fl["Width of temperature range (\[Degree]C), centered on 70 \[Degree]C", "Condition number of J\[Transpose]J (unit columns)"],
   PlotLabel -> Style["A wider range does not rescue the standard form; centering at the weighted center does", 13, ink],
   ImageSize -> 700, Evaluate[styleNoTicks]]
exportFig["Fig4_condition_number_vs_range.png", fig4];
