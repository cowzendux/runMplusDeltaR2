* Generate Mplus syntax to calculate delta R2
* By Jamie DeCoster

* This program takes an Mplus input file as an input, along with an
* optional list of variables from the program's models. The program
* then writes a number of additional Mplus input files that would
* test the same model, each dropping one of the variables in the
* provided list. If no list is given, it uses the list of exogenous 
* variables from the model (those only used as predictors and not ever as 
* outcomes). The program then writes a batch file in the output directory
* (deltaR2.bat) that actually runs the post-hoc analyses in Mplus.

* Usage: writeMplusDeltaR2(input file, output directory, [variable list])
* The input file is an Mplus input file that is to form the basis for the 
* post-hoc analyses. The output directory is the location in which 
* the new Mplus files will be placed. The variable list is the set of
* variables that will be excluded one at a time to perform the post
* hoc analyses.

* Notes: The program currently assumes that references to the subtracted 
* variables are not put anywhere except for the data, variable, and model
* sections. 

************
* Version History
************
* 2013-06-20 Created
* 2013-06-21 Obtained list of exogenous variables
    Pulled target variable out of Model section
* 2013-06-22 Added section to write Mplus file
* 2013-06-22a Added section to read Mplus file
    Tied all sections together
* 2013-06-23 Completed notes
    Wrote batch file

set printback = off.
begin program python.
import os
from subprocess import Popen, PIPE

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

def stripToSemi(checktext):
    for c in range(len(checktext)):
        if (checktext[len(checktext)-c-1] == ";" or checktext[len(checktext)-c-1] == ":"):
            return checktext[:len(checktext)-c]
    return checktext

def splitProgram(programString):
    line = ""
    curtext = ""
    firstsec = 1
    sections = ["TITLE:", "DATA:", "VARIABLE:", "DEFINE:", 
"ANALYSIS:", "MODEL:", "OUTPUT:", "SAVEDATA:",
"PLOT:", "MONTECARLO:"]
    sectext = [None]*10
    programString = programString.upper()

    for c in programString:
        line += c
        if (c == "\n"):
            secnum = 0
            for sec in sections:
                if (sec in line):
                    if (firstsec != 1):
                        sectext[cursec] = curtext
                    else:
                        firstsec = 0
                    cursec = secnum
                    curtext = ""
                secnum+=1
            curtext += line
            line = ""
    sectext[cursec] = curtext

# Removing extra characters at end of all sections except title
    for t in range(10):
        if (sectext[t] != None and t != 0):
            newtext = stripToSemi(sectext[t])
            sectext[t] = newtext

# Removing blank lines at end of title
    if (sectext[0] != None):
        for t in range(len(sectext[0])):
            if (sectext[0][len(sectext[0])-t-1] != " " and sectext[0][len(sectext[0])-t-1] != "\n"):
                break
        sectext[0] = sectext[0][:len(sectext[0])-t]
    return(sectext)

def splitCommands(programString):
    throughHeader = 0
    for c in range(len(programString)):
        if (programString[c] != "\n" and throughHeader == 1):
            break
        if (programString[c] == ":"):
            throughHeader = 1
    curCommand = ""
    commands = []
    for t in programString[c:]:
        curCommand += t
        if (t == ";"):
            for d in range(len(curCommand)):
                if (curCommand[d] != "\n"):
                    commands.append(curCommand[d:])
                    break
            curCommand = ""
    return commands

def commWords(commString):
# Removes ending semicolon
    varlist = commString.split()
    lastvar = varlist[len(varlist)-1] 
    if (lastvar == ";"):
        varlist = varlist[:len(varlist)-1]
    else:
        lastvar = lastvar[:len(lastvar)-1]
        varlist[len(varlist)-1] = lastvar
    return varlist

def getExo(commString):
    commList = splitCommands(commString)
    exolist = []
    endolist = []
    for c in commList:
        varlist = commWords(c)
        if (varlist[1] == "ON"):
            endolist.append(varlist[0])
            exolist += varlist[2:]
    
    exoset = set(exolist) - set(endolist)
    return(list(exoset))

def spaceSplit(splitstring, linelength):
    stringwords = splitstring.split()
    returnstring = ""
    curline = ""
    for word in stringwords:
        if (len(word) > linelength):
            break
        if (len(word) + len(curline) < linelength - 1):
            curline += word + " "
        else:
            returnstring += curline + "\n"
            curline = word + " "
    returnstring += curline
    return returnstring

def subtractPredictorModel(comString, pred):
    comlist = splitCommands(comString)
    pred = pred.upper()
    newcommands = "MODEL:\n"
    for c in comlist:
        cString = ""
        cWords = commWords(c)
        if (len(cWords) == 3):
            if (cWords[1] == "ON"):
                if (cWords[2] == pred):
                    cString = cWords[0] + ";\n"
                else:
                    cString = " ".join(cWords)
                    cString += ";\n"
            else:
                if (cWords[2] != pred):
                    cString = " ".join(cWords)
                    cString += ";\n"
        else:
            firstword = 1
            for w in cWords:
                if (w != pred or firstword == 1):
                    cString += w + " "
                    firstword = 0
            cString = cString[:-1]
            cString += ";\n"
        newcommands += spaceSplit(cString, 80) + "\n"
    return newcommands

def subtractPredictorVariable(comString, pred):
    comList = splitCommands(comString)
    pred = pred.upper()
    newCommands = "VARIABLE:\n"
    for c in comList:
        cWords = commWords(c)
        if (cWords[0] != "NAMES"):
            if (pred in cWords):
                cWords.remove(pred)
        cString = " ".join(cWords)
        cString += ";\n"
        newCommands += spaceSplit(cString, 80) + "\n"
    return newCommands

def writeMplus(textBySec, filename):
    outfile = open(filename, "w")
    for sec in textBySec:
        if (sec != None):
            outfile.write(sec)
            outfile.write("\n\n")
    outfile.close()

def getMplusFile(filename):
    inputfile = open(filename, "r")
    filetext = inputfile.read()
    inputfile.close()
    return filetext

def writeBatch(outDirectory, fileList, outFile):
    batchFile = open(outDirectory + "/" + outFile, "w")
    batchFile.write("cd " + outDirectory + "\n")
    for line in fileList:
        batchFile.write("call mplus \"" + line + "\"\n")
    batchFile.close()

def runBatch(outDirectory, outFile):
    p = Popen(outDirectory + "/" + outFile, cwd=outDirectory)

def runMplusDeltaR2(MplusFile, outDirectory, removeVars = "NONE"):
# Strip / at the end if it is present
    if (outDirectory[-1] == "/"):
            outDirectory = outDirectory[:-1]
            
# Create output directory if it doesn't exist
    if not os.path.exists(outDirectory):
        os.mkdir(outDirectory)

# Find filename
    for t in range(len(MplusFile)):
        if (MplusFile[-t] == "/"):
            break
    fname, fext = os.path.splitext(MplusFile[-(t-1):])

    programString = getMplusFile(MplusFile)
    programString = stripComments(programString)
    programBySec = splitProgram(programString)
    fullVariable = programBySec[2]
    fullModel = programBySec[5]
    if (removeVars == "NONE"):
        removeVars = getExo(fullModel)

# Looping through subtraction variables
    inpList = []
    for var in removeVars:
        programBySec[5] = subtractPredictorModel(fullModel, var)
        if (var + " " in programBySec[5]):
            programBySec[2] = fullVariable
        else:
            programBySec[2] = subtractPredictorVariable(fullVariable, var)
        outfilename = outDirectory + "/" + fname + " minus " + var + ".inp"
        inpList.append(fname + " minus " + var + ".inp")
        writeMplus(programBySec, outfilename)
    outfilename = fname + ".bat"
    writeBatch(outDirectory, inpList, outfilename)
    runBatch(outDirectory, outfilename)

end program python.
set printback = on.
