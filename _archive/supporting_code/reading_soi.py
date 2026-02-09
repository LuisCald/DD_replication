import os

os.chdir(r"C:\Dropbox\Distributional_Dynamics\1_Data\SOI")
with open("1960.Y60", "rt", "cp500") as ebcdic:
    a = ebcdic.read()
    