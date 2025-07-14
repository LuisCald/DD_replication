import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import math
import scipy.stats as st
from matplotlib.colors import LightSource

####--------------------------------####
# This is the corresponing Python code to the paper "A multivariate extension of the Lorenz curve based on copulas and a related multivariate Gini coefficient"
# (https://arxiv.org/abs/2101.04748).

####--------------------------------####
# def gini(X):
#     """
#              Calculates univariate Gini-coeffienct of one dimensional data array

#              Input:
#                  X:        np-array (nxp)-distribution of single feature over people, n observations, p variables

#              Output:
#                 ginivalue: float - univariate Gini coefficient
#              """

#     sorted_X = np.sort(np.array(X)) #np.array(X.copy()).sort()
#     n = X.size

#     scalar1 = 2.0 / n
#     scalar2 = (n + 1.0) / n
#     weighted_sum = sum([(i + 1) * j for i, j in enumerate(sorted_X)])
#     ginivalue = scalar1 * weighted_sum / (sorted_X.sum()) - scalar2
#     return ginivalue

def gini(x, w=None):
    # The rest of the code requires numpy arrays.
    x = np.asarray(x)
    if w is not None:
        w = np.asarray(w)
        sorted_indices = np.argsort(x)
        sorted_x = x[sorted_indices]
        sorted_w = w[sorted_indices]
        # Force float dtype to avoid overflows
        cumw = np.cumsum(sorted_w, dtype=float)
        cumxw = np.cumsum(sorted_x * sorted_w, dtype=float)
        return (np.sum(cumxw[1:] * cumw[:-1] - cumxw[:-1] * cumw[1:]) / 
                (cumxw[-1] * cumw[-1]))
    else:
        sorted_x = np.sort(x)
        n = len(x)
        cumx = np.cumsum(sorted_x, dtype=float)
        # The above formula, with all weights equal to 1 simplifies to:
        return (n + 1 - 2 * np.sum(cumx) / cumx[-1]) / n


def x_star(X):
    """
              Calculates X* out of values from X for arbitrary dimensions, as defined in formula (8)


              Input:
                  X:        np-array (nxp)- distribution of features over people, n observations, p variables

              Output:
                df:         np-array - X^* values


              """

    X1 = np.copy(X)
    df = pd.DataFrame(X1)
    df.reset_index(inplace=True, drop=True)
    columns = list(df)

    for column in columns:
        sorted_arr = np.sort(np.array(df[column].copy()))
        sorted_arr1 = (st.rankdata(np.array(df[column]), method='ordinal') - 1).astype(int)
        column_sum = np.sum(df[column])
        cum_sum = np.cumsum(sorted_arr)
        X_star = cum_sum / column_sum
        X_star_sorted = np.empty(shape=np.size(df[column]))

        for i in range(0, np.size(df[column])):
            X_star_sorted[i] = X_star[sorted_arr1[i]]
        df[column] = X_star_sorted

    return df

def weighted_x_star(X, weights):
    """
    Calculates weighted X* out of values from X for arbitrary dimensions, as defined in formula (8),
    incorporating weights into the calculation.

    Input:
        X: np-array (nxp) - distribution of features over people, n observations, p variables
        weights: np-array (n,) - weights corresponding to each observation in X

    Output:
       df: np-array - Weighted X^* values
    """
    
    # Ensure X is a numpy array and weights is correctly shaped

    X1 = np.copy(X)
    df = pd.DataFrame(X1)
    weights_df = weights.to_frame(name="weight").reset_index()
    df = pd.concat([df, weights_df], axis=1)

    for column in df.columns[:-1]:  # Exclude the weights column
        # Create a DataFrame for sorting values and weights together
        sorted_df = pd.DataFrame({
            'value': df[column],
            'weight': df["weight"]
        }).sort_values(by='value').reset_index(drop=True)

        # Calculate weighted cumulative sum and total using weights

        sorted_df['weighted_value'] = sorted_df['value'] * sorted_df['weight']
        sorted_df['cum_weighted_value'] = sorted_df['weighted_value'].cumsum()
        total_weighted_value = sorted_df['weighted_value'].sum()
        
        # Calculate X* as the ratio of the cumulative sum to the total, for each observation
        X_star = sorted_df['cum_weighted_value'] / total_weighted_value
        
        # Assign calculated X* back to the original DataFrame in the correct order
        df[column] = X_star.values  # This assumes the index aligns; adjust if necessary

    # Drop the weights column to return only the transformed variables
    df.drop(columns=["weight"], inplace=True)

    return df


def mult_gini(X_star_values):
    """
             Calculates multivariate Gini coefficient, calculated by formula (9)

             Input:
                 X_star_values:        Matrix (nxp) with X^* values, n observations, p variables

             Output:
                megc:                    multivariate extension of the Gini coefficient


             """
    d = np.size(X_star_values, axis=1)
    n = np.size(X_star_values, axis=0)

    X_star_values = np.array(X_star_values)
    outer_value = 0

    for i in range(0, n):
        inner_value = 0
        # Move on if X_star == 1 in one dimension
        if (len(list(filter (lambda x : x == 1.0, X_star_values[i, :]))) > 0):
            continue
        for j in range(0, d):
            if inner_value == 0:
                inner_value = (1 - X_star_values[i, j])
            else:
                inner_value = inner_value * (1 - X_star_values[i, j])

        outer_value = outer_value + inner_value

    outer_value = outer_value / n
    megc = (outer_value * math.factorial(d + 1) - 1) / (math.factorial(d + 1) - 1)
    return megc


def emp_dist(C, Y, X_star):
    """
             Calculates the empirical distribution of X^* in given grid to draw the MEILC

             Input:
                 C:        grid positions in first direction
                 Y:        grid positions in second direction
                 X:        values of X^*

             Output:
                T:          np array - empirical distribution fuction of X^*


             """

    grid = np.size(C, axis=0)
    T = np.empty(shape=(grid, grid))
    X_copy = np.copy(X_star)
    n = np.size(X_copy, axis=0)
    X_helper = np.copy(X_star)
    for i in range(0, grid):
        for j in range(0, grid):
            X_helper[:, 0] = np.where(X_copy[:, 0] < C[i], 1, 0)
            X_helper[:, 1] = np.where(X_copy[:, 1] < Y[j], 1, 0)
            X_helper1 = np.where(np.sum(X_helper, axis=1) == 2, 1, 0)
            T[i, j] = np.sum(X_helper1) / n
    return T


def mult_lorenz(datamult, w=None):
    """
                Draw 2-dimensional Lorenz curve and safe it to working directory as .png

                Input:
                    data:        Input data

                Output:
                    -

                """
    # check dimensions
    if np.size(datamult, axis=1) != 2:
        raise ValueError('Data should be 2 dimsional to plot MEILC')

    # calculate X^* values
    if w is None:
        X_star_values = x_star(datamult)
        # calculate MEGC and univariate Ginis
        megc = mult_gini(X_star_values)
        gini_x = gini(datamult.iloc[:, 0])
        gini_y = gini(datamult.iloc[:, 1])
        
    else:
        X_star_values = weighted_x_star(datamult, w) 
        # calculate MEGC and univariate Ginis
        megc = mult_gini(X_star_values)
        gini_x = gini(datamult.iloc[:, 0], w)
        gini_y = gini(datamult.iloc[:, 1], w)



    # create grid and calculate cdf of X*
    X_star = np.array(X_star_values)
    C = np.linspace(0, 1, num=100)
    Y = np.linspace(0, 1, num=100)
    C, Y = np.meshgrid(C, Y)
    Z = np.array(emp_dist(C[0, :], Y[:, 0], X_star))

    # curve starts at 0
    Z[:, 0] = 0
    Z[0, :] = 0

    # plot MEILC
    white = np.ones((Z.shape[0], Z.shape[1], 3))
    blue = white * np.array([0.01, 0.01, 0.01])
    light = LightSource(132, -20)
    illuminated_surface = light.shade_rgb(blue, Z * 10, fraction=1)
    fig = plt.figure(figsize=(11, 7))
    fig.patch.set_facecolor('white')
    ax = plt.axes(projection='3d')
    ax.patch.set_facecolor('white')
    surf = ax.plot_surface(C, Y, Z, rstride=1, cstride=1, linewidth=0, antialiased=False,
                           facecolors=illuminated_surface)
    ax.set_zlim3d(0, 1)
    ax.set_xlim3d(0, 1)
    ax.set_ylim3d(0, 1)
    ax.view_init(elev=20, azim=232)
    hfont = {'fontname': 'Times New Roman'}
    ax.set_xlabel('\nFeature 2'+'\n Gini=' + str(round(gini_y,2)))
    ax.set_ylabel('\nFeature 1 ' +'\n Gini=' + str(round(gini_x,2)))
    ax.set_zlabel('Proportion', fontsize=10,**hfont)
    ax.set_title('MEILC with MEGC = '+str(round(megc,2)),fontsize=10,**hfont)
    plt.savefig('Mult_Lorenz.png', format='png',bbox_inches="tight", dpi=1200)
    plt.show()


