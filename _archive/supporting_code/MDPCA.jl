# Moving Dynamic PCA: PCA for high-dimensional non-stationary time series 
    # Does not run on Apple Silicon unfortunately
# X is a T by N matrix 

loadings = R"""
                install.packages(MDPCA)
                ##apply MDPCA with 100 window length and 5 lagged series.
                Analysis = MDPCA(X,100,5)
                U = Analysis$U  ## the projections 
                F = Analysis$F  ## returns the moving cross-covariance matrix of the extended data matrix xdata
                Lambda = Analysis$Lambda  ## Eigenvalues of F

                xdata = Analysis$xdata  ## returns the extended data matrix of x
                ## For example, if we find the first two eigenvalues to be large enough, then we can choose the corresponding two eigenvectors to obtain the final results (i.e. two MDPCs) sum(Lambda[1:2])/sum(Lambda)
                Transform=xdata%*%U[,1:2]  
                ## Final results (i.e. two MDPCs), ts() creates a time series object 
                Transform = ts(Transform) 
"""