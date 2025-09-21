module FlexSketch

using StatsBase

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
    
    # TODO TR: What if there are models?
    return false
end # function diagnose

function majorupdate!(S::Sketch)
    # Ensure there's space for the new model.    
    while length(S.models) >= S.n_models
            pop!(S.models)
            pop!(S.data_lengths)
        return
    end

    bins = computebins(S)
    model = fit(Histogram, bins, S.buffer, closed=:left)

    # Add new model to the front of the models list.
    pushfirst!(S.models, model)
    pushfirst!(S.data_lengths, sum(model.weights))

end # function majorupdate

function computebins(S::Sketch)
    """ Compute bins for the new histogram. """
    bins = []

    for j in 1:S.n_bins
        q = j / (S.n_bins + 2)
        append!(bins, findquantile(S, q))
    end

    return bins
end # function computebins


function findquantile(S::Sketch, q::Real)
    """
        Find quantile q of the data in S.buffer and S.models. 

        This is implemented by searching through previously prepared S.sorted_entries.
    """
    return S.sorted_entries[ceil(Int, length(S.sorted_entries) * q)]
end 

end # module FlexSketch
