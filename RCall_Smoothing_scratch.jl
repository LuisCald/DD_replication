using RCall
@rlibrary kdecopula
@rlibrary cNORM
@rlibrary pracma

u    = rand(1000, 2)
wgts = rand(1000,2)
mesh = create_mesh(10, 2)

R"w <- cNORM::weighted.rank($u, $wgts) / max($u+1)"
# Copula density 
R"""
# some comment 
w <- apply($u, 2, rank) / (nrow($u) + 1)
# w <- cNORM::weighted.rank($u, $wgts) 
# ww <- pracma::Reshape(w, 1000 , 2) 
# ww[,1] <- ww[,1] / (max(ww[, 1]) + 1)
# ww[,2] <- ww[,2] / (max(ww[, 2]) + 1)
kde.fit <- kdecopula::kdecop(w)
b <- kdecopula::dkdecop($mesh, kde.fit) 
"""
@rget b

# copula distribution 
R"""
# some comment 
w <- apply($u, 2, rank) / (nrow($u) + 1)
kde.fit <- kdecopula::kdecop(w)
b <- kdecopula::pkdecop($mesh, kde.fit) 
"""

@rget b

cop = reshape(b, (10,10))

# Generate pdf matrix from cdf matrix 
cop_pdf = zeros(10,10)
c = zeros(100)
c[1] = b[1]
for i in 2:100
    c[i] = b[i] - b[i-1]
end
cop = reshape(c, (10,10))

# Convert this code: - [ ] Estimate DeltaC(h,j) = \hat C(x_{h+1}, y_{j+1}) - \hat C(x_{h+1}, y_{j}) - \hat C(x_{h}, y_{j+1}) + \hat C(x_{h}, y_{j}) in julia 



reshape(cdf_to_pdf(b), (10,10))



v = [prod(mesh[i, :]) for i in 1:100]


reshape(v, (10, 10))



temp       = zeros(10,10)
f(c)       = sum((==(1)).(c.I)) >= length(c.I) - 1
condition1 = filter(!f, CartesianIndices(size(temp)))
condition2 = filter(f, CartesianIndices(size(temp)))


# temp[condition1] = dfs[4][1:81, 16]
# temp[condition2] = [3.464878794331064, -1.5434248453812394, -0.21544793888462235, -0.1592984198378376, -0.07792627740617396, -0.04347037562607649, -0.03008723074239147, -0.015102177917272403, -0.009896908362923996, -0.0038563742911434983, -1.5470299220407495, -0.18509846595866794, -0.12651285200001275, -0.06158196266198346, -0.03290911623655824, -0.029181738330050645, -0.013491430100814706, -0.011448393445045262, -0.0033753238161253456]
for i in [5, 11,16]
    temp= dfs[4][1:100, i]
    temp=reshape(temp, (10,10))
    cop = idct(temp)

    # Generate the density - \hat C(x_{h+1}, y_{j+1}) - \hat C(x_{h+1}, y_{j}) - \hat C(x_{h}, y_{j+1}) + \hat C(x_{h}, y_{j})
    cop_pdf = zeros(10,10)

    for h in 1:10
        for j in 1:10
            if h == 1 && j == 1
                cop_pdf[h,j] = cop[h,j]
            elseif h == 1 && j != 1
                cop_pdf[h,j] = cop[h,j] - cop[h,j-1]
            elseif h != 1 && j == 1
                cop_pdf[h,j] = cop[h,j] - cop[h-1,j]
            else
                cop_pdf[h,j] = cop[h,j] - cop[h-1,j] - cop[h,j-1] + cop[h-1,j-1]
            end
        end
    end

    Plots.surface(
        1:10, 
        1:10, 
        cop_pdf,
        legend=false, 
        camera = (30,10), 
        size=(400,400),
        color=:winter, 
        dpi=500,
        display_option=Plots.GR.OPTION_SHADED_MESH)
        Plots.savefig("test_$i.pdf")
end