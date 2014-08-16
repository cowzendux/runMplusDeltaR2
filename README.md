#runMplusDeltaR2

SPSS Python Extension function that runs multiple Mplus child models to calculate changes in R2 for all predictors in a parent model. The repository also contains the function "analyzeMplusDeltaR2" that will collect information from the child models and report the change in R2 for each predictor.

##Usage of runMplusDeltaR2
**runMplusDeltaR2(MplusFile, outDirectory, removeVars)**
* "MplusFile" is a required argument indicating Mplus input file that is to form the basis for the analyses.
* "outDirectory" is a required argument providing the directory in which the new Mplus files will be placed.
* "removeVars" is a list of strings indicating the set of variables that will be excluded one at a time to perform the post hoc analyses. This is an optional argument. If it is omitted, then the program will determine the delta R2 for all variables in the model.

Note: The program currently assumes that references to the subtracted variables are not put anywhere except for the data, variable, and model sections. 

##runMplusDeltaR2 example
**runMplusDeltaR2(MplusFile = "C:\Users\Jamie\Dropbox\ICT\Mplus\Model 1.inp",  
outDirectory = "C:\Users\Jamie\Dropbox\ICT\Mplus\Temp",  
removeVars = ["cond1", "cond2", "gender"])**  
* The parent model that will form the basis for the changes in R2 analyses can be found at "C:\Users\Jamie\Dropbox\ICT\Mplus\Model 1.inp".
* The child models that will be created to calculate the changes in R2 will be saved in the directory "C:\Users\Jamie\Dropbox\ICT\Mplus\Temp".
* The model will run the models required to calculate the changes in R2 for the variables "cond1", "cond2", and "gender".

##Usage of analyzeMplusDeltaR2
**analyzeMplusDeltaR2(baseOutputFile, R2directory)**
* "baseOutputFile" is a required argument providing the location of the output from the parent model.
* "R2directory" is a required argument providing the directory where the output from the child models were saved.

##analyzeMplusDeltaR2 example
**analyzeMplusDeltaR2(baseOutputFile = "C:\Users\Jamie\Dropbox\ICT\Mplus\Model 1.out",  
R2directory = "C:\Users\Jamie\Dropbox\ICT\Mplus\Temp")**
* This model would use the model described in "C:\Users\Jamie\Dropbox\ICT\Mplus\Model 1.out" as the baseline for the changes in R2 analyses.
* It would search the directory "C:\Users\Jamie\Dropbox\ICT\Mplus\Temp" for other output files and compare their R2 to that for the parent directory. The results are placed in an SPSS dataset named "deltaR2".
