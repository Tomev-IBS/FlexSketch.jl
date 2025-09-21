module FlexSketch

using StatsBase
using LinearAlgebra

export Sketch
export update!

@kwdef struct Sketch
    λ :: Float64 = 2.5  # TODO TR: What's that?
    γ :: Float64 = 0.4  # Diagnose threshold.
    
    buffer_size :: Int = 30
    n_models :: Int = 3
    n_bins :: Int = 10   # Not specified in the paper
    
    buffer :: Vector{Real} = []
    models :: Vector{Histogram} = []
    data_lengths :: Vector{Int} = []

    # Auxiliary
    sorted_entries :: Vector{Real} = []  # For quantule computation
    ε_steps :: Int = 100

end # struct Sketch

function update!(S::Sketch, val::Real)

    minorupdate!(S, [val])
    prepend!(S.buffer, val)

    # If buffer is not yet filled, do nothing.
    if length(S.buffer) < S.buffer_size
        return
    end

    sortinputs!(S)

    if diagnose(S)
        majorupdate!(S)
    end   
    
    empty!(S.sorted_entries)
    empty!(S.buffer)

end # function update!

function minorupdate!(S::Sketch, substream::Vector{<:Real})
    """ Minor update function from the paper. """
    for i in 1:length(S.models) - 1  # Last model is not updated.
        singleupdate!(S.models[i], substream)
        S.data_lengths[i] += length(substream)
    end
end # function minorupdate!

function singleupdate!(h::Histogram, substream::Vector{<:Real})
    for v in substream
        push!(h, v)  # push! for histogram behaves exactly as algorithm needs.
    end
end # function singleupdate!

function sortinputs!(S::Sketch)
    """ Sort inputs for quantile computation. """
    append!(S.sorted_entries, S.buffer)

    for m in S.models
        for i in 1:length(m.weights)
            append!(S.sorted_entries, [m.edges[1][i + 1] for _ in 1:length(m.weights)])
        end
    end
    sort!(S.sorted_entries)
end # function sortinputs!

function diagnose(S::Sketch)
    """ """
    # If there are no models, then major update is required.
    if length(S.models) == 0
        return true
    end 

    ε = computeε(S)
    δ = ε / (1 - ε)

    shouldupdate = δ > S.γ

    return shouldupdate
end # function diagnose

function computeε(S::Sketch)
    """ 
    Computes ε value of the diagnose method.

    We implement the empirical max Δ(x) version of ε.
    """
    # For this function to be reached, at least one model is required. We only use the first.
    m = S.models[1]
    hcdf(x) = cdf(m)(x)
    edf(x) = ecdf(S.buffer)(x)
    Δ(x) = abs(edf(x) - hcdf(x))

    ε = 0
    min_x = min(minimum(S.buffer), m.edges[1][1])
    step = (max(maximum(S.buffer), last(m.edges[1])) - min_x) / S.ε_steps
    
    for n in 0:S.ε_steps
        ε = max(ε, Δ(min_x + n * step))
    end

    return ε
end # function computeε

function majorupdate!(S::Sketch)
    # Ensure there's space for the new model.    
    while length(S.models) >= S.n_models
        pop!(S.models)
        pop!(S.data_lengths)
    end

    bins = computebins(S)
    model = fit(Histogram, S.buffer, bins, closed=:left)
    
    edf(x) = ecdf(S.buffer)(x)
    model.weights = [ceil(edf((bins[j+1]) - edf(bins[j])) * length(S.buffer)) for j in 1:length(bins)-1]

    # Add new model to the front of the models list.
    pushfirst!(S.models, model)
    pushfirst!(S.data_lengths, sum(model.weights))

end # function majorupdate

function computebins(S::Sketch)
    """ Compute bins for the new histogram. """
    bins = []

    for j in 1:S.n_bins + 1
        q = j / (S.n_bins + 2)
        append!(bins, ppf(S)(q))
    end

    return bins
end # function computebins

function cdf(S::Sketch)
    """ """
    cdfs = []

    for h in S.models
        push!(cdfs, cdf(h))
    end

    function f(x)
        return sum([f(x) for f in cdfs]) / length(S.models)
    end

    return f
end # end cdf(Sketch)

function cdf(h::Histogram)
    """ """
    norm_h = normalize(h, mode=:probability)
    cdf_p = cumsum(norm_h.weights)

    function f(x::Real)
        i = 1
        for _ in 1:length(h.weights)
            i += 1
            if x < norm_h.edges[1][i]
                break
            end
        end
        return cdf_p[i - 1]
    end

    return f
end

function ppf(S::Sketch)
    """ Percent point (quantile) funciton """

    function cumdistf(x)
        if length(S.models) == 0
            return ecdf(S.buffer)(x)
        else
            return (cdf(S)(x) + ecdf(S.buffer)(x)) / 2
        end
    end 

    vals = []

    append!(vals, S.buffer)

    for m in S.models
        for v in m.edges[1]
            push!(vals, v)
        end
    end

    # eppf according to https://www.statisticshowto.com/inverse-distribution-function-point-quantile/
    function f(q::Real)
        X = []
        for v in vals
            cdf_v = cumdistf(v)
            if cdf_v >= q
                push!(X, v)
            end
            # X = [x for x in vals if cumdistf(x) >= q]
        end
        return minimum(X)
    end

    return f
end

end # module FlexSketch
