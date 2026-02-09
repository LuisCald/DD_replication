# Plot on PCA

# Base plot
x = [50, 80, 90, 95]

# Baseline 
bl = [3, 4, 5, 7]
tw = [6, 8, 16, 22]
tp = [1, 2, 2, 3]

iw = [4, 17, 29, 40]
tw_iw = [5, 18, 29, 40]
tp_iw = [5, 18, 29, 40]

Plots.plot(x, bl, xformatter=:latex, yformatter=:latex, label=L"\textrm{Baseline}", lw=2, color="black",  ylabel=L"\textrm{\# \,\, of\,\, Factors}", xlabel=L"\textrm{\% \,\, Variation}", marker=:circle, markersize=5)
Plots.plot!(x, tw, xformatter=:latex, yformatter=:latex, label=L"\textrm{TW}", lw=2, color="blue", marker=:circle, markersize=5)
Plots.plot!(x, tp, xformatter=:latex, yformatter=:latex, label=L"\textrm{TP}", lw=2, color="red", marker=:circle, markersize=5)
Plots.savefig("pca1.pdf")

Plots.plot(x, iw, xformatter=:latex, yformatter=:latex, label=L"\textrm{Baseline}", lw=2, color="black", ylabel=L"\textrm{\# \,\, of\,\, Factors}", xlabel=L"\textrm{\% \,\, Variation}", marker=:circle, markersize=5)
Plots.plot!(x, tw_iw, xformatter=:latex, yformatter=:latex, label=L"\textrm{TW}", lw=2, color="blue", marker=:circle, markersize=5)
Plots.plot!(x, tp_iw, xformatter=:latex, yformatter=:latex, label=L"\textrm{TP}", lw=2, color="red", marker=:circle, markersize=5)
Plots.savefig("pca2.pdf")