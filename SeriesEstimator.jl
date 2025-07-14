cd("/Users/lc/Dropbox/Distributional_Dynamics/5_Code")
include("DistributionalDynamics.jl")

using Integrals

# Plan of attack: create 3D object <-> 2D object mapping
# Step 1: estimate the 3D copula
# Step 2: find coefficients for that 
# Step 3: estimate the 2D copula
# Step 4: find coefficients for that
# Step 5: compare coefficients -> figure out mapping 

grid = 10
dom = [1.0, 0.0] # upper bound first -> package says so
p = nodes(grid, :chebyshev_nodes, dom)

# Get PSID data 
@unpack df_vec = obs_data
df = df_vec[1][1]
df = df[df[:, :year].==2019, :]

# Cleaning out NaNs
non_missing = coalesce.(df, NaN)
non_missing = filter("income" => !isnan, select(df, ["income", "wealth", "consum", "weight", "id"]))
filter!("weight" => !isnan, non_missing)
filter!("income" => !isnan, non_missing)
filter!("wealth" => !isnan, non_missing)
filter!("consum" => !isnan, non_missing)

df_3D = select(non_missing, ["consum", "income", "wealth", "weight"])
df_2D = select(non_missing, ["income", "wealth", "weight"])



# Define the orthonormal shifted Legendre polynomials as in the paper 
function legendre_polynomial(m, x)
    if m == 0
        return 1.0
    elseif m == 1
        return x
    else
        P_prev_prev = 1.0
        P_prev = x
        P_current = 0.0

        for n in 2:m
            P_current = ((2n - 1) * x * P_prev - (n - 1) * P_prev_prev) / n
            P_prev_prev, P_prev = P_prev, P_current
        end

        return P_current
    end
end



# Define the Legendre polynomial of degree m
function Q_m(m, x)
    L_m = legendre_polynomial(m, 2x - 1)

    return sqrt(2m + 1) * L_m
end


function integrate_legendre_polynomial(m, u)
    if m == 0
        return u
    else
        integral_cop, _ = quadgk(u -> Q_m(m, u), 0, u, rtol=1e-3)

        return integral_cop
    end
end


# function integral_legendre_polynomial_in(m, x)
#     if m == 0
#         return x
#     else
#         P_m_plus_1 = legendre_polynomial(m + 1, x)
#         P_m_minus_1 = legendre_polynomial(m - 1, x)
#         return (P_m_plus_1 - P_m_minus_1) / (2m + 1)
#     end
# end



# Function to integrate the shifted Legendre polynomial
function I_m(m, u)
    return integrate_legendre_polynomial(m, u)
end




# Estimate the copula coefficients ρ_m
function estimate_rho(R, weights, m)
    n, d = size(R)
    rho_m = 0.0

    if all(iszero, m)
        return 1.0
    end

    # If d-1 elements of m are zero, then the product is zero
    if sum(m .== 0) >= d - 1
        return 0.0
    end

    Threads.@threads for i in 1:n
        product = 1.0

        for j in 1:d
            # product *= weights[i] * Q_m(m[j], R[i, j])
            product *= Q_m(m[j], R[i, j])
        end

        rho_m += weights[i] * product
        # rho_m += product
    end

    return rho_m / sum(weights)
    # return rho_m / n
end

# Helper function to compute ranks
function rankdata(a)
    order = sortperm(a)
    ranks = similar(order)
    ranks[order] .= 1:length(a)
    return ranks
end

# Construct the N-th order estimator for copula density
function copula_density_estimator(X, weights, N, u)
    d = size(X, 2)

    ranges = [(0:N[j]) for j in 1:d]
    cl = length(collect(Iterators.product(ranges...)))
    c_N = 0.0


    # Multi-thread this 
    Threads.@threads for (xx, m) in collect(enumerate(Iterators.product(ranges...)))
        m = Tuple(m)
        rho_m = estimate_rho(X, weights, m)
        product = 1.0

        for j in 1:d
            product *= Q_m(m[j], u[j])
        end

        c_N += rho_m * product
    end

    # Apply positivity correction
    c_N = maximum([0, c_N])

    return c_N
end

function copula_cdf_estimator(X, weights, N, u)
    d = size(X, 2)

    ranges = [(0:N[j]) for j in 1:d]
    C_N = 0.0

    Threads.@threads for m in collect(Iterators.product(ranges...))
        m = Tuple(m)
        rho_m = estimate_rho(X, weights, m)
        product = 1.0
        for j in 1:d
            product *= I_m(m[j], u[j])
        end
        C_N += rho_m * product
    end

    return C_N
end


function copula_function(cop_coefs, N, u)
    d = length(N)

    ranges = [(0:N[j]) for j in 1:d]
    cl = length(collect(Iterators.product(ranges...)))
    c_N = 0.0


    # Multi-thread this 
    Threads.@threads for (xx, m) in collect(enumerate(Iterators.product(ranges...)))
        m = Tuple(m)
        product = 1.0

        for j in 1:d
            product *= Q_m(m[j], u[j])
        end

        c_N += cop_coefs[xx] * product
    end

    # Apply positivity correction
    c_N = maximum([0, c_N])

    return c_N
end


function get_copula_coefficients(X, W, N)
    d = size(X, 2)

    ranges = [(0:N) for j in 1:d] # TODO: can be made more flexible
    cl = length(collect(Iterators.product(ranges...)))
    c_N = 0.0
    rho_m = zeros(cl)

    # Multi-thread this 
    Threads.@threads for (xx, m) in collect(enumerate(Iterators.product(ranges...)))
        tup_m = Tuple(m)
        rho_m[xx] = estimate_phi(X, W, tup_m)
    end

    return rho_m
end


# Example usage with a sample data X
X = Matrix(select(df_3D, ["consum", "income", "wealth"]))  # Example bivariate data
X2 = Matrix(select(df_2D, ["income", "wealth"]))  # Example bivariate data

# rank the data 
for i in 1:size(X, 2)
    X[:, i] = rankdata(X[:, i]) / (size(X, 1) + 1)
end

for i in 1:size(X2, 2)
    X2[:, i] = rankdata(X2[:, i]) / (size(X2, 1) + 1)
end


N = (10, 10, 10)  # Example truncation order
N2 = (10, 10)  # Example truncation order

function copula_cdf_estimator(X, u)
    C_N = 0.0

    # Dimension of copula 
    d = length(size(X))

    # Order of the object 
    N = size(X, 1) - 1

    # Ranges for the object
    ranges = [(0:N) for _ in 1:d]

    # All possible orders of the object
    m_combos = collect(Iterators.product(ranges...))

    # Look over each weight <==> looping over each m_combos 
    Threads.@threads for ci in CartesianIndices(m_combos)
        m = Tuple(m_combos[ci])
        rho_m = X[ci]
        product = 1.0

        for j in 1:d
            product *= I_m(m[j], u[j])
        end
        C_N += rho_m * product
    end

    return C_N
end


d = length(size(X)) - 1

x = select_grid_points(10)
x[end] = x[end] - 1e-6
XX = [[x[i], x[j]] for i in eachindex(x), j in eachindex(x)]



X = Matrix(select(df_3D, ["consum", "income", "wealth", "weight"]))  # Example bivariate data
m_combos = generate_unique_combinations(["income", "consum", "wealth"])
filter!(x -> length(x) == 2, m_combos)

for combo in m_combos
    # Example usage with a sample data X
    X = Matrix(select(df_3D, combo))  # Example bivariate data

    # rank the data 
    for i in 1:size(X, 2)
        X[:, i] = rankdata(X[:, i]) / (size(X, 1))
    end

    rho = get_copula_coefficients(X, df_3D[:, :weight], 20)
    rho_mat = reshape(rho, Int(sqrt(size(rho, 1))), Int(sqrt(size(rho, 1))))
    rho_mat = rho_mat[2:end, 2:end]

    tag = join(combo, "_")

    Plots.surface(1:20, 1:20, rho_mat, xlabel=L"\textrm{Order}", ylabel=L"\textrm{Order}", xformatter=:latex, yformatter=:latex, zformatter=:latex, zlabel=L"\textrm{Legendre \,\, Coefficient}",
        camera=(30, 10),
        size=(400, 400),
        color=:winter,
        legend=false,
        display_option=Plots.GR.OPTION_SHADED_MESH)
    Plots.savefig("copula_weight_$tag.pdf")
end

# Constructing CDF 
for i in 5:20
    rho = get_copula_coefficients(X2, df_2D[:, :weight], i)
    X = reshape(rho, Int(sqrt(size(rho, 1))), Int(sqrt(size(rho, 1))))

    N = size(X, 1) - 1
    integrals = precompute_integrals(N, x)

    cop_cdf = [copula_cdf_estimator(X, integrals, [XX[i, j][1], XX[i, j][2]]) for i in eachindex(x), j in eachindex(x)]

    Plots.surface(x, x, cdf_to_pdf(cop_cdf), xlabel="u1", ylabel="u2", zlabel="Copula Density", title="Two Dimensional Copula Density",
        camera=(30, 10),
        size=(400, 400),
        color=:winter,
        display_option=Plots.GR.OPTION_SHADED_MESH)
    Plots.savefig("plus1_copula_density_$i.pdf")
end

# Using SCF weights from code 
@unpack estimator = model_options
scf_w = add_multidimensional_immutable(estimator, dfs[5], 11, ["income", "wealth"])
cop_scf_w = reshape(scf_w[1:121, end], (11, 11))


x = collect(1/10:1/10:1)
x[end] = 0.99
x = select_grid_points(10)
XX = [[x[i], x[j]] for i in 1:length(x), j in 1:length(x)]
cop2D = [copula_cdf_estimator(rho2, [XX[i, j][1], XX[i, j][2]]) for i in 1:length(x), j in 1:length(x)]


from_outside = [0.016002553396958802 0.042164780818494764 0.05648421392159279 0.06702412596993496 0.07521347527781347 0.08035209020302646 0.0848627087642792 0.0885501148641274 0.09364706683680978 0.09905244868864348; 0.030774876304340282 0.07600557055133535 0.10469474933634304 0.1265880934461319 0.14428457929599256 0.15726720860919194 0.16825280773975929 0.17682509987267314 0.18677728302374794 0.19815243260122856; 0.045750593546695924 0.1048771089376084 0.14819500540529013 0.1820583962827671 0.2100418593108751 0.23336306958332687 0.25227083674070655 0.26542755479904306 0.28060958610972175 0.2974276797876669; 0.05983426387068944 0.12948509106282227 0.1861267288206412 0.23149500361417197 0.2699258152287022 0.3044733277445832 0.3328077219660651 0.3525004936694248 0.37400875652449656 0.3969082277955685; 0.07020620706864542 0.14677542045037809 0.21421161522626106 0.2713156794293777 0.3216153030188582 0.36799118373067036 0.4072935947239066 0.4369837610837035 0.46606603023462845 0.49619254640260574; 0.07791393063673535 0.15893014808231218 0.23457487935942153 0.3037568344337628 0.36789438041608613 0.42747193204221984 0.4785377534258288 0.5190491721538878 0.557091239212183 0.5952987359296291; 0.084240827013779 0.1683859282502053 0.2500802305191329 0.32979279290810215 0.4073730021331474 0.4810701419810963 0.5459568977426213 0.5989616070789187 0.6470836601905655 0.6944202903345797; 0.08824196497828171 0.17581432739845482 0.2624863159292289 0.3496131025784043 0.43673564318965985 0.5218775538551944 0.6019790217056079 0.672777345173706 0.7347682951706737 0.7932719233451305; 0.09263998704037746 0.1854961432454912 0.2776686964863023 0.3704228838875832 0.4636581600327714 0.555997717217294 0.6469698013066176 0.7353809151484234 0.8183855208561106 0.8916792458077997; 0.09926941997576157 0.1985799401751058 0.2978238924688408 0.3971784240647606 0.49666559852376574 0.5959866818433972 0.6949872573576562 0.7936763370422323 0.8918646110196423 0.9801675299714283]
from_outside ./= maximum(from_outside)



# Generate 10 by 10 grid of points to generate the two dimensional copula
XXX = [[x[i], x[j], x[k]] for i in 1:length(x), j in 1:length(x), k in 1:length(x)]

# Density estimator 
cop2D = [copula_density_estimator(X2, df_3D[:, :weight], N2, [XX[i, j][1], XX[i, j][2]]) for i in 1:length(x), j in 1:length(x)]
cop3D = [copula_density_estimator(X, df_3D[:, :weight], N, [XXX[i, j, k][1], XXX[i, j, k][2], XXX[i, j, k][3]]) for i in 1:length(x), j in 1:length(x), k in 1:length(x)]

# CDF estimator
cop2D_CDF = [copula_cdf_estimator(X2, df_3D[:, :weight], N2, [XX[i, j][1], XX[i, j][2]]) for i in 1:length(x), j in 1:length(x)]

# Computing the integral over some region 
cop_coefs = get_copula_weights(X2, df_3D[:, :weight], N2)
f(u, cop_coefs, N2) = copula_function(cop_coefs, N2, u)

domain = (zeros(2), ones(2) .* 0.1) # (lb, ub)
prob = IntegralProblem(f, domain, cop_coefs, N2)
sol = solve(prob, HCubatureJL(), reltol=1e-3, abstol=1e-3)

rho = [1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0; 0.0 0.3135304774732436 0.04807177760673926 0.06893036805838998 0.1136223118957173 -0.0070486250911043465 0.11759912174460278 0.018701770565902404 0.01521560618049681 0.04929137970975374 -0.015324314180660752; 0.0 0.13539324557380544 0.10807262390497827 0.09378501721437196 0.06515186347834485 0.12341741156804324 -0.010335085594396814 0.08423150838887736 0.036832883102381794 0.015043936786506248 0.08629319727694747; 0.0 0.08285018214766467 0.18359092871562188 0.11133254641135722 0.07459320931768208 0.03939378492555767 0.05439969438417099 0.04422779622533185 0.04743453668395329 0.06180877351157209 0.015643767306967322; 0.0 0.05906398473520167 0.10349787894981066 0.1455209998127323 0.07526611172272378 0.06354736031140715 0.040843259620861015 0.06473587100072788 0.04636386312909535 0.045067170311344155 0.03477523987654971; 0.0 0.05625858362571241 0.09904381289815276 0.08931253448919048 0.10312035334538236 0.06748148826096831 0.06072664276520332 0.06505241378324766 0.046564691691798304 0.04881621923002298 0.07126020772872241; 0.0 0.05370105973117708 0.07518566404597204 0.0838315797595304 0.08862589096808195 0.08133158146185507 0.05609615362590734 0.05002305547210935 0.07801603574571411 0.06965626876547208 0.02332366016321999; 0.0 0.009712833584009279 0.05361011422856876 0.05848591818809532 0.06779840272884521 0.06851226074545565 0.041584417986903835 0.06309093050031576 0.048710456923276614 0.0355892997864725 0.06842214828496207; 0.0 0.07281653499138838 0.02549819273626843 0.04474459380496409 0.055686434897778206 0.042601688518229715 0.0702004909369726 0.061107048320995394 0.019021456885218235 0.06599057165713737 0.05374116170957689; 0.0 0.007251105344103614 0.04007321919975791 0.022040729259745664 0.022374926019805556 0.0717254394563389 0.060643313818991317 0.044800736955749064 0.08446933874718052 0.04211636028878154 0.05141674895813146; 0.0 0.030056176768056254 0.004055406163191999 0.010534086349194387 0.027480451968872943 0.029760134005288968 0.04463413833655391 0.04807340956252969 0.05510107296552824 0.05580775533479475 0.031566063541416424]

# # Comparing coefficients 
# rho_m   = estimate_rho(X2, (3,3))
# rho_m_slice   = estimate_rho(X, (3,3,0))

# Compare first slice of cop3D with cop2D
cop3D_slice = cop3D[:, :, 1]

# The thing is: we want to estimate the copula, since the density doesnt necessarily give us the weights. Though, in practice, the density evaluated at certain points give ok approximations of the weights 

# Normalize the density
normalization_factor = sum(cop2D)
cop2D ./= normalization_factor
cop3D_slice ./= sum(cop3D_slice)

# Normalize the CDF
normalization_factor = maximum(cop2D)
cop2D ./= normalization_factor
cop2D_PDF = cdf_to_pdf(cop2D_CDF)

# Plot the two dimensional copula
cop2D[10, 4] = 0.4
cop2D[7, 2] = 0.14
cop2D[8, 2] = 0.16

Plots.surface(x, x, cdf_to_pdf(cop_cdf), xlabel="u1", ylabel="u2", zlabel="Copula Density", title="Two Dimensional Copula Density",
    camera=(30, 10),
    size=(400, 400),
    color=:winter,
    display_option=Plots.GR.OPTION_SHADED_MESH)
Plots.savefig("copula_density.pdf")

Plots.surface(x, x, cop2D_PDF, xlabel="u1", ylabel="u2", zlabel="Copula Density", title="Two Dimensional Copula Density",
    camera=(30, 10),
    size=(400, 400),
    color=:winter,
    display_option=Plots.GR.OPTION_SHADED_MESH)
Plots.savefig("copula_density_fromCDF.pdf")

Plots.surface(x, x, cop2D_CDF, xlabel="u1", ylabel="u2", zlabel="Copula Density", title="Two Dimensional Copula Density",
    camera=(30, 10),
    size=(400, 400),
    color=:winter,
    display_option=Plots.GR.OPTION_SHADED_MESH)
Plots.savefig("copula_CDF2.pdf")

Plots.surface(x, x, cop3D_slice, xlabel="u1", ylabel="u2", zlabel="Copula Density", title="Two Dimensional Copula Density",
    camera=(30, 10),
    size=(400, 400),
    color=:winter,
    display_option=Plots.GR.OPTION_SHADED_MESH)
Plots.savefig("copula_density_slice.pdf")

cop2D = [0.013127305996251748 0.036388743874572305 0.02709768845707935 0.057004901141771515 0.06858713642997788 0.05524482470194332 0.09739292287636007 0.09824766092925022 0.08907154904091986 0.10054906677467858; 0.029727922995688175 0.06576065868762734 0.08797961046986907 0.11021276018218946 0.1266696772584336 0.16301510004296937 0.16796236349347296 0.18980060394958098 0.18840464732758397 0.1989187949187734; 0.025564122034090534 0.08868960168993424 0.08537342820027571 0.1529208398456154 0.18697355900850537 0.1696293127869335 0.2426028086050196 0.26450267966525054 0.291478073576291 0.29617840324594624; 0.036670067123409304 0.11317473805113648 0.11574824403607295 0.1987954287200681 0.2485827146878884 0.2830809133748277 0.31796698142155344 0.29942530309034354 0.3734090908280284 0.39946261555653645; 0.07058606462254982 0.1414935202602454 0.19885324579328137 0.2541419602349938 0.30608993135674273 0.3594313645057426 0.39685641772337504 0.43977479526930013 0.47312983949395665 0.5012952702414019; 0.06460123288943104 0.1225953493478557 0.22669605925870231 0.28923408480337065 0.3563317653362278 0.41851846663942727 0.46652874737381317 0.5163846168951702 0.5620321214322501 0.6011308966869949; 0.09204246525361842 0.13577726433800671 0.2544697632109738 0.3233108882537368 0.3968295282925629 0.4769925105610599 0.530982252721152 0.590081046793075 0.6549128557425985 0.6968721141370287; 0.09550274732266205 0.187044534648416 0.27152285157496375 0.3166499537798894 0.4358755221759982 0.5194226770396757 0.6037997195049352 0.6764076084766322 0.7459914060334839 0.7953427615975149; 0.0901552230816907 0.17868037741156856 0.2981958263157814 0.38066812261149363 0.4786926044751207 0.5642262363235078 0.6622513306320184 0.7557889369941474 0.818206028056432 0.8929560735402242; 0.09989859364882628 0.1978055785005204 0.2996612644531902 0.39784799176319674 0.5008822439899037 0.5982881476981586 0.6984780818342938 0.7973910067789709 0.8945153552460733 0.9820700515739638]
cop2D ./= 0.9820700515739638



# For the percentile functions 

# Function to compute Legendre polynomials up to a given order
function legendre_polynomials(x, order)
    P = [1, x]
    for n in 2:order
        Pn = ((2n - 1) * x * P[end] - (n - 1) * P[end-1]) / n
        push!(P, Pn)
    end
    return P
end


function series_estimator(data, weights, order, p_values)
    # Estimate Phi using the legendre polynomials
    Phi = zeros(length(data), order + 1)

    s_weights = cumsum(weights) / sum(weights)

    for i in eachindex(data)
        for j in 0:order
            # Phi[i, j+1]          = Q_m(j, normalize_to_0_1(data[i], min_data, max_data)) # Q_m places [0,1] data internally to [-1, 1]
            Phi[i, j+1] = Q_m(j, s_weights[i]) # Q_m places [0,1] data internally to [-1, 1]
        end
    end
    # Estimate the coefficients, (Phi' * Phi)^(-1) * Phi' * y
    # coefficients = inv(transpose(Phi) * Phi) * transpose(Phi) * data
    # Incorporate weights into the Phi matrix
    W = Diagonal(sqrt.(weights))  # Use square root of weights for correct weighting
    Phi_weighted = W * Phi

    # More stable and efficient way to estimate the coefficients
    # Weighted least squares solution
    # coefficients = (transpose(Phi_weighted) * Phi_weighted) \ (transpose(Phi_weighted) * (W * data))
    # coefficients = (transpose(Phi_weighted) * (W * data))

    coefficients = zeros(order + 1)
    for j in 1:order+1
        for i in 1:length(data)
            coefficients[j] += weights[i] * Phi[i, j] * data[i]
        end
        coefficients[j] /= sum(weights)
    end
    # cdf_est = Phi * coefficients

    basis = zeros(length(p_values), order + 1)
    for (i, p) in enumerate(p_values)
        for j in 0:order
            basis[i, j+1] = Q_m(j, p)
        end
    end

    quants = basis * coefficients

    # return cdf_est
    return quants
end

function get_quantile_weights(data, weights, order)
    # Estimate Phi using the legendre polynomials
    Phi = zeros(length(data), order + 1)
    min_data = nanminimum(data)
    max_data = nanmaximum(data)
    s_weights = cumsum(weights) / sum(weights)

    for i in eachindex(data)
        for j in 0:order
            Phi[i, j+1] = Q_m(j, s_weights[i]) # Q_m places [0,1] data internally to [-1, 1]
        end
    end

    # Incorporate weights into the Phi matrix
    W = Diagonal(sqrt.(weights))  # Use square root of weights for correct weighting
    Phi_weighted = W * Phi

    coefficients = zeros(order + 1)
    for j in 1:order+1
        for i in 1:length(data)
            coefficients[j] += weights[i] * Phi[i, j] * data[i]
        end
        coefficients[j] /= sum(weights)
    end

    return coefficients
end

function eval_quantile_function(coefficients, order, u)

    basis = zeros(1, order + 1)

    for j in 0:order
        basis[j+1] = Q_m(j, u)
    end

    quants = basis * coefficients

    return quants
end

# Example usage:
measure_of_choice = :wealth
sort!(df_3D, measure_of_choice)
data = df_3D[!, measure_of_choice][:]
weights = df_3D[!, :weight][:]

@unpack gdp_series = obs_data
gdp_series[!, "date"] = QuarterlyDate.(gdp_series[!, "time"])
a = filter(x -> x.date == QuarterlyDate(2019, 4), gdp_series)
data = inverse_hyperbolic_sine(data ./ a[1, "$(String(measure_of_choice))_per_hh"])

# Estimate the CDF
p_values = collect(0.02:0.01:1)
p_values[end] = 0.9999

# Generate the quantile function
emp_est = []
s_weights = cumsum(weights) / sum(weights)

for p in p_values
    est = [meas for (meas, cdf) in zip(df_3D[!, measure_of_choice], s_weights) if cdf >= p][1]
    push!(emp_est, est)
end

emp_est = inverse_hyperbolic_sine(emp_est)
orders_to_estimate = collect(3:20)
mse = zeros(length(orders_to_estimate))
mse_bot = zeros(length(orders_to_estimate))
mse_mid = zeros(length(orders_to_estimate))
mse_top = zeros(length(orders_to_estimate))

# Plot the results
for (mse_i, i) in enumerate(orders_to_estimate)
    Plots.plot()
    q_est = series_estimator(data, weights, i, p_values)
    q_est = inverse_hyperbolic_sine(reverse_inverse_hyperbolic_sine(q_est) .* a[1, "$(String(measure_of_choice))_per_hh"])
    Plots.plot!(axes(q_est), q_est, color=:black, ls=:dash, xlabel="x", ylabel="CDF", title="CDF Estimation using Polynomial Basis")
    # Plots.plot!(axes(data), data, color=:red, ls=:dot, label="Empirical CDF")
    Plots.plot!(axes(emp_est), emp_est, color=:red, ls=:dot, label="Empirical CDF")
    Plots.savefig("cdf_est$i.pdf")
    # Compute the MSE between empirical and estimated quantiles
    mse[mse_i] = mean((emp_est .- q_est) .^ 2)

    # Compute the MSE for the bottom, middle, and top quantiles
    mse_bot[mse_i] = mean((emp_est[1:50] .- q_est[1:50]) .^ 2)
    mse_mid[mse_i] = mean((emp_est[51:90] .- q_est[51:90]) .^ 2)
    mse_top[mse_i] = mean((emp_est[91:end] .- q_est[91:end]) .^ 2)
end

# Concatenate the MSE results
mse_results = hcat(mse, mse_bot, mse_mid, mse_top)

# Plot the MSE
Plots.plot(orders_to_estimate, mse_results, xlabel=L"\textrm{Order}", ylabel=L"\textrm{MSE}",
    xformatter=:latex, yformatter=:latex,
    color=:auto, marker=:circle, markersize=4, label=[L"\textrm{All}" L"\textrm{Bottom}" L"\textrm{Middle}" L"\textrm{Top}"],
    legend=:topright,
    grid=true,
    size=(600, 400))
Plots.savefig("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/order_analysis/mse_qf_$(String(measure_of_choice)).pdf")



# Integration 
q_weights = get_quantile_weights(data, weights, 21)
integral, err = quadgk(u -> reverse_inverse_hyperbolic_sine(eval_quantile_function(q_weights, 21, u)) .* a[1, :income_per_hh], 0.1, 0.2, rtol=1e-8)

to_store = rand(10)
for (i, j) in enumerate(0.0:0.01:0.099)
    to_store[i] = eval_quantile_function(q_weights, 10, j)[1]
end

mean(to_store)
integral / 0.1

# Plotting the coefficients 

for (i, m) in enumerate(sort(["income", "consum", "wealth"]))
    sort!(df_3D, m)
    data = df_3D[!, m][:]
    weights = df_3D[!, :weight][:]

    @unpack gdp_series = obs_data
    gdp_series[!, "date"] = QuarterlyDate.(gdp_series[!, "time"])
    a = filter(x -> x.date == QuarterlyDate(2019, 4), gdp_series)

    data = inverse_hyperbolic_sine(data ./ a[1, m*"_per_hh"])
    w = get_quantile_weights(data, weights, 21)

    Plots.plot(axes(w), w, color=:blue, xformatter=:latex, yformatter=:latex, ls=:dot, label="", xlabel=L"\textrm{Order}", ylabel=L"\textrm{Coefficient}")
    Plots.scatter!(axes(w), w, color=:blue, xformatter=:latex, yformatter=:latex, ls=:dot, markersize=3, label=i == 1 ? L"\textrm{Legendre \,\, Coefficients}" : "", xlabel=L"\textrm{Order}", ylabel=L"\textrm{Coefficient}")
    Plots.savefig("Legendre_coefs_" * "$m" * "_pcfs.pdf")
end
