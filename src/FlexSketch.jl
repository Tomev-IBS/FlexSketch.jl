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
end # struct Sketch


function update!(S::Sketch, val::Real)
    
    prepend!(S.buffer, val)

    # If buffer is not yet filled, do nothing.
    if length(S.buffer) < S.buffer_size
        return
    end

    
    # The magic happens here
    
    # 
    println("\tClearing the buffer of size: $(length(S.buffer))")
    empty!(S.buffer)
    println("\t\tCurrent buffer length: $(length(S.buffer))")

end # function update!

function add_model!(S::Sketch, model::Histogram)
    """ Adds new model. """

    # Ensure there's space for the new model.
    while length(S.models) >= n_models
            pop!(S.models)
            pop!(S.data_lengths)
        return
    end

    # Add new model to the front of the models list.
    prepend!(S.models, model)
    # TODO TR: prepend!(S.data_lengths, DATA_LENGTH_FROM_MODEL)
end # function add_model!

function build_model(data::Vector{float})
    """ """
    println("Got vector of length ")

end # build_model


end # module FlexSketch
