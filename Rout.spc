series{
save=(a1 b1)
title="R Output for x12a"
start=1.1
period=4
DECIMALS=5
file = "Rout.dat"
}
transform{
function=auto
}
automdl{
acceptdefault=no
balanced=yes
maxorder=(3,2)
maxdiff=(1,1)
savelog=(adf amd b5m mu)
}
forecast {
save=ftr
maxlead=4
}
x11{
save=(d10 d11 d12)
sigmalim=(1.5,2.5)
final=(user)
appendfcst=yes
savelog=all
}
