* Analyze Mplus delta R2 output
* By Jamie DeCoster

* Creates a dataset containing the original full Model R2 values and
* the R2 values after removing individual predictors for all of the 
* outcomes in a model.

* Usage: analyzeMplusDeltaR2(baseOutputFile, R2directory)

*************
* Version History
*************
* 2013-06-23 Created

output close all.
begin program python.
import spss, spssdata, os

def stripComments(programString):
    finalString = ""
    comm = 0
    priorline = 0
    for c in programString:
        if (c != "!"):
            if (comm == 0):
                finalString += c
                if (c == "\n"):
                    priorline = 0
            else:
                if (c == "\n"):
                    if (priorline == 0):
                        finalString += c
                    priorline = 1
                    comm = 0
        else:
            comm = 1
    return(finalString)

def getR2(filename):
    infile = open(filename, "r")
    fileText = infile.read()
    infile.close()
    fileText = stripComments(fileText)
    fileWords = fileText.split()

# Find "R-SQUARE" starting from the end (to avoid Title section)

    for t in range(len(fileWords)):
        if (fileWords[-t] == "R-SQUARE"):
            break
    varList = []
    R2List = []
    i = 8
    while (fileWords[-t+i+1] != "OF"):
        varList.append(fileWords[-t+i])
        R2List.append(float(fileWords[-t+i+1]))
        i = i + 5
    return varList, R2List

def getOutputList(directory, rootname):
    allfiles=[os.path.normcase(f)
        for f in os.listdir(directory)]
    outfiles=[]
    for f in allfiles:
        fname, fext = os.path.splitext(f)
        if (rootname in fname.upper() and fext.upper() == ".OUT"):
            outfiles.append(fname.upper() + ".OUT")
    return outfiles

def analyzeMplusDeltaR2(baseOutputFile, R2directory):
# Make file and directory names uppercase
    baseOutputFile = baseOutputFile.upper()
    R2directory = R2directory.upper()

# Strip / at the end of R2directory if it is present
    if (R2directory[-1] == "/"):
            R2directory = R2directory[:-1]   
# Find filename
    for t in range(len(baseOutputFile)):
        if (baseOutputFile[-t] == "/"):
            break

    basename, baseext = os.path.splitext(baseOutputFile[-(t-1):])
    baseVars, baseR2 = getR2(baseOutputFile)
    dt = []
    for t in range(len(baseVars)):
        dt.append(["FULL MODEL", baseVars[t], baseR2[t]])

    outFiles = getOutputList(R2directory, basename)
    for file in outFiles:
        minusVars, minusR2 = getR2(R2directory + "/" + file)
        filerev = file[::-1]
        minusName = file[-filerev.find(" "):-4]
        for t in range(len(minusVars)):
            dt.append([minusName, minusVars[t], minusR2[t]])
    
    spss.StartDataStep()
    datasetObj = spss.Dataset(name=None)
    dsetname = datasetObj.name
    datasetObj.varlist.append("minusVar", 25)
    datasetObj.varlist.append("outcome", 25)
    datasetObj.varlist.append("R2", 0)

    for line in dt:
       datasetObj.cases.append(line)
    spss.EndDataStep()

    submitstring = """dataset activate %s.
dataset name deltaR2.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=outcome
  /R2_full=FIRST(R2).
compute R2_delta = R2_full - R2.
execute.
alter type r2 r2_full r2_delta (f8.3).""" %(dsetname)
    spss.Submit(submitstring)

end program python. 

