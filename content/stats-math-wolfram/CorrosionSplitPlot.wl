(* ::Package:: *)

(* =====================================================================================
   Box, Hunter & Hunter (2nd ed.), Chapter 9: Multiple Sources of Variation
   Table 9.1 -- Corrosion resistance of steel bars, four coatings, split-plot design
   Whole plots = 6 furnace heats (2 reps x 3 temperatures, temperature hard to change)
   Subplots    = 4 coatings, randomized position within each heat (easy to change)
   ===================================================================================== *)

(* ---------- Export directory: same folder as this notebook ---------- *)
exportDir = NotebookDirectory[];
If[exportDir === $Failed, exportDir = Directory[]]; (* fallback if run outside a notebook front end *)

(* ---------- 0. Data, exactly as run (Table 9.1a) ---------- *)
corrData = {
  <|"Heat" -> 1, "Temp" -> 360, "Coating" -> "C2", "Y" -> 73|>, <|"Heat" -> 1, "Temp" -> 360, "Coating" -> "C3", "Y" -> 83|>,
  <|"Heat" -> 1, "Temp" -> 360, "Coating" -> "C1", "Y" -> 67|>, <|"Heat" -> 1, "Temp" -> 360, "Coating" -> "C4", "Y" -> 89|>,
  <|"Heat" -> 2, "Temp" -> 370, "Coating" -> "C1", "Y" -> 65|>, <|"Heat" -> 2, "Temp" -> 370, "Coating" -> "C3", "Y" -> 87|>,
  <|"Heat" -> 2, "Temp" -> 370, "Coating" -> "C4", "Y" -> 86|>, <|"Heat" -> 2, "Temp" -> 370, "Coating" -> "C2", "Y" -> 91|>,
  <|"Heat" -> 3, "Temp" -> 380, "Coating" -> "C3", "Y" -> 147|>, <|"Heat" -> 3, "Temp" -> 380, "Coating" -> "C1", "Y" -> 155|>,
  <|"Heat" -> 3, "Temp" -> 380, "Coating" -> "C2", "Y" -> 127|>, <|"Heat" -> 3, "Temp" -> 380, "Coating" -> "C4", "Y" -> 212|>,
  <|"Heat" -> 4, "Temp" -> 380, "Coating" -> "C4", "Y" -> 153|>, <|"Heat" -> 4, "Temp" -> 380, "Coating" -> "C3", "Y" -> 90|>,
  <|"Heat" -> 4, "Temp" -> 380, "Coating" -> "C2", "Y" -> 100|>, <|"Heat" -> 4, "Temp" -> 380, "Coating" -> "C1", "Y" -> 108|>,
  <|"Heat" -> 5, "Temp" -> 370, "Coating" -> "C4", "Y" -> 150|>, <|"Heat" -> 5, "Temp" -> 370, "Coating" -> "C1", "Y" -> 140|>,
  <|"Heat" -> 5, "Temp" -> 370, "Coating" -> "C3", "Y" -> 121|>, <|"Heat" -> 5, "Temp" -> 370, "Coating" -> "C2", "Y" -> 142|>,
  <|"Heat" -> 6, "Temp" -> 360, "Coating" -> "C1", "Y" -> 33|>, <|"Heat" -> 6, "Temp" -> 360, "Coating" -> "C4", "Y" -> 54|>,
  <|"Heat" -> 6, "Temp" -> 360, "Coating" -> "C2", "Y" -> 8|>, <|"Heat" -> 6, "Temp" -> 360, "Coating" -> "C3", "Y" -> 46|>};

(* sanity check: recreates the six per-heat averages in Table 9.1b (78.00, 82.25, 160.25, 112.75, 138.25, 35.25) *)
GroupBy[corrData, #Heat &, N[Mean[#Y & /@ #]] &]

(* ---------- 1. IGNORE the split-plotting: ordinary LinearModelFit, factors coded as nominal ---------- *)
Ys = #Y & /@ corrData; predRows = {#Temp, #Coating} & /@ corrData;
n = Length[Ys]; grandMean = Mean[Ys]; SSTot = Total[(Ys - grandMean)^2];

lmNaive = LinearModelFit[Transpose[{predRows[[All, 1]], predRows[[All, 2]], Ys}],
   {1, T, C, T*C}, {T, C}, NominalVariables -> {T, C}];
lmNaive["ParameterTable"]   (* individual-coefficient t-tests -- not what Table 9.3 shows *)

(* sequential (Type I) ANOVA decomposition for the naive, single-error-term model *)
lmT  = LinearModelFit[Transpose[{predRows[[All, 1]], Ys}], {1, T}, {T}, NominalVariables -> {T}];
lmTC = LinearModelFit[Transpose[{predRows[[All, 1]], predRows[[All, 2]], Ys}], {1, T, C}, {T, C}, NominalVariables -> {T, C}];
SSR[lm_] := Total[(lm["PredictedResponse"] - grandMean)^2];
SSTemp = SSR[lmT]; SSCoat = SSR[lmTC] - SSR[lmT]; SSInter = SSR[lmNaive] - SSR[lmTC];
SSResidNaive = SSTot - SSR[lmNaive];
dfT = 2; dfC = 3; dfTC = 6; dfResidNaive = n - 1 - dfT - dfC - dfTC;

naiveANOVA = Grid[{
   {"Source", "df", "SS", "MS", "F"},
   {"Temperature (T)", dfT, N[SSTemp], N[SSTemp/dfT], N[(SSTemp/dfT)/(SSResidNaive/dfResidNaive)]},
   {"Coating (C)", dfC, N[SSCoat], N[SSCoat/dfC], N[(SSCoat/dfC)/(SSResidNaive/dfResidNaive)]},
   {"T \[Times] C", dfTC, N[SSInter], N[SSInter/dfTC], N[(SSInter/dfTC)/(SSResidNaive/dfResidNaive)]},
   {"Residual (pooled -- WRONG)", dfResidNaive, N[SSResidNaive], N[SSResidNaive/dfResidNaive], ""}
   }, Dividers -> All, Alignment -> Left];
naiveANOVA
(* NOTE what this gets backwards: pooling whole-plot and subplot error into one residual (MS=1297)
   makes Temperature look spuriously significant (F=10.2, vs the correct F=2.75) and makes Coating
   look non-significant (F=1.10, vs the correct F=11.5) -- the split-plot structure matters, and
   ignoring it can mislead in EITHER direction depending on which stratum's variance dominates. *)

(* ---------- 2. PROPER split-plot decomposition (reproduces Tables 9.2/9.3 exactly) ---------- *)
byHeat = GroupBy[corrData, #Heat &];
heatMeanAssoc = Association[KeyValueMap[#1 -> Mean[#Y & /@ #2] &, byHeat]];
tempOfHeat = Association[KeyValueMap[#1 -> #2[[1, "Temp"]] &, byHeat]];
heats = Sort[Keys[byHeat]];

(* -- whole-plot stratum: one row per heat, response = heat mean -- *)
wpTemp = tempOfHeat /@ heats; wpMean = heatMeanAssoc /@ heats;
lmWP = LinearModelFit[Transpose[{wpTemp, wpMean}], {1, T}, {T}, NominalVariables -> {T}];
grandMeanWP = Mean[wpMean];
SSTempWP = 4 Total[(lmWP["PredictedResponse"] - grandMeanWP)^2];  (* x4: each heat mean averages 4 subplots *)
SSTotalWP = 4 Total[(wpMean - grandMeanWP)^2];
SSEw = SSTotalWP - SSTempWP; dfEw = 6 - 1 - 2;

(* -- subplot stratum: remove each heat's own mean, leaving only C, T*C, Es -- *)
devData = Map[Function[row, <|"Temp" -> row["Temp"], "Coating" -> row["Coating"], "Heat" -> row["Heat"],
     "Ydev" -> row["Y"] - heatMeanAssoc[row["Heat"]]|>], corrData];
Ydev = #Ydev & /@ devData; Tdev = #Temp & /@ devData; Cdev = #Coating & /@ devData;
lmCdev = LinearModelFit[Transpose[{Cdev, Ydev}], {1, C}, {C}, NominalVariables -> {C}];
lmTCdev = LinearModelFit[Transpose[{Tdev, Cdev, Ydev}], {1, T, C, T*C}, {T, C}, NominalVariables -> {T, C}];
SSCoatSub = Total[lmCdev["PredictedResponse"]^2];
SSFullSub = Total[lmTCdev["PredictedResponse"]^2];
SSInterSub = SSFullSub - SSCoatSub;
SSEs = Total[Ydev^2] - SSFullSub; dfEs = 24 - 6 - dfC - dfTC;

MSTempWP = SSTempWP/2; MSEw = SSEw/dfEw; FT = MSTempWP/MSEw;
MSC = SSCoatSub/dfC; MSTC = SSInterSub/dfTC; MSEs = SSEs/dfEs; FC = MSC/MSEs; FTC = MSTC/MSEs;
pT = 1 - CDF[FRatioDistribution[2, dfEw], FT]; pC = 1 - CDF[FRatioDistribution[dfC, dfEs], FC]; pTC = 1 - CDF[FRatioDistribution[dfTC, dfEs], FTC];

(* parallel-column layout, matching Table 9.3 exactly:
   SS_T=26519, SS_Ew=14440 (df=3), SS_C=4289, SS_TxC=3270, SS_Es=1121 (df=9)
   F_2,3=2.75 (p=0.21), F_3,9=11.5** , F_6,9=4.4*  *)
splitPlotANOVA = Grid[{
   {"Heats (Whole Plots)", SpanFromLeft, SpanFromLeft, SpanFromLeft, "", "Coatings (Subplots)", SpanFromLeft, SpanFromLeft, SpanFromLeft, ""},
   {"Source", "df", "SS", "MS", "F (p)", "Source", "df", "SS", "MS", "F (p)"},
   {"Average, I", 1, N[grandMean^2 24], "", "", "C", dfC, N[SSCoatSub], N[MSC], Row[{NumberForm[FC, 4], " (", NumberForm[pC, 3], ")"}]},
   {"Temperature", 2, N[SSTempWP], N[MSTempWP], Row[{NumberForm[FT, 4], " (", NumberForm[pT, 3], ")"}], "T\[Times]C", dfTC, N[SSInterSub], N[MSTC], Row[{NumberForm[FTC, 4], " (", NumberForm[pTC, 3], ")"}]},
   {"Error Ew", dfEw, N[SSEw], N[MSEw], "", "Error Es", dfEs, N[SSEs], N[MSEs], ""}
   }, Dividers -> All, Alignment -> Left];
splitPlotANOVA

(* variance components -- matches book's sigma_W=34.2, sigma_S=11.1 *)
sigW2 = (MSEw - MSEs)/4; sigS2 = MSEs;
<|"sigma_W^2" -> sigW2, "sigma_S^2" -> sigS2, "sigma_W" -> Sqrt[sigW2], "sigma_S" -> Sqrt[sigS2],
  "SE(temperature)" -> Sqrt[MSEw/8.], "SE(coating)" -> Sqrt[MSEs/6.], "SE(interaction cell)" -> Sqrt[MSEs/2.]|>

(* ---------- 3. The punchline plot: noisy whole plots, clean subplots ---------- *)
tempSE = Sqrt[MSEw/8.]; coatSE = Sqrt[MSEs/6.]; coatOrder = {"C1", "C2", "C3", "C4"};
errBarPrims[x_, y_, se_, color_] := {color, Line[{{x, y - se}, {x, y + se}}],
   Line[{{x - 0.08, y - se}, {x + 0.08, y - se}}], Line[{{x - 0.08, y + se}, {x + 0.08, y + se}}],
   PointSize[0.022], Point[{x, y}]};

SeedRandom[3];
heatPts = Table[{tempOfHeat[h] + RandomReal[{-2.5, 2.5}], heatMeanAssoc[h]}, {h, heats}];
tempMeanPts = Table[{t, Mean[Select[heatPts, Abs[#[[1]] - t] < 6 &][[All, 2]]]}, {t, {360, 370, 380}}];
coatDevMeans = GroupBy[devData, #Coating &, Mean[#Ydev & /@ #] &];
rawPts = Table[{Position[coatOrder, devData[[i]]["Coating"]][[1, 1]] + RandomReal[{-0.12, 0.12}], devData[[i]]["Ydev"]}, {i, Length[devData]}];
coatMeanPts = Table[{c, coatDevMeans[coatOrder[[c]]]}, {c, 4}];

p1 = Graphics[{{GrayLevel[0.55], PointSize[0.02], Point /@ heatPts}, Table[errBarPrims[tempMeanPts[[i, 1]], tempMeanPts[[i, 2]], tempSE, Red], {i, 3}]},
   Frame -> True, FrameLabel -> {"Furnace Temperature (\[Degree]C)", "Corrosion Resistance"},
   PlotLabel -> Style["Whole-plot: temperature (SE = 12.1)\nno clear pattern, p = 0.21", 15, Black],
   FrameStyle -> Directive[Black, Thickness[0.002]], LabelStyle -> Directive[Black, 15, FontFamily -> "Helvetica"],
   PlotRange -> {{350, 390}, {0, 220}}, AspectRatio -> 1, ImageSize -> 420, Axes -> False, Background -> White];
p2 = Graphics[{{GrayLevel[0.55], PointSize[0.016], Point /@ rawPts}, Table[errBarPrims[coatMeanPts[[c, 1]], coatMeanPts[[c, 2]], coatSE, Red], {c, 4}]},
   Frame -> True, FrameTicks -> {{Automatic, None}, {Table[{c, coatOrder[[c]]}, {c, 4}], None}},
   FrameLabel -> {"Coating", "Deviation from heat mean"},
   PlotLabel -> Style["Subplot: coating (SE = 4.53)\nC4 clearly wins, p = 0.002", 15, Black],
   FrameStyle -> Directive[Black, Thickness[0.002]], LabelStyle -> Directive[Black, 15, FontFamily -> "Helvetica"],
   PlotRange -> {{0.5, 4.5}, {-60, 60}}, AspectRatio -> 1, ImageSize -> 420, Axes -> False, Background -> White];
(* explicit Background -> White on the panels, the row, and the Export: renders identically in dark- or light-mode notebooks *)
finalFig = GraphicsRow[{p1, p2}, ImageSize -> 900, Spacings -> 60, Background -> White];
finalFig
Export[FileNameJoin[{exportDir, "corrosion_splitplot_summary.png"}], finalFig, ImageResolution -> 300, Background -> White];
Print["Done. PNG exported to: ", exportDir];
