# Experiments for DEDSTA article.
using FlexSketch
using ProgressBars
using Distributions
using StatsFuns
using Plots

function test_stream_mean(t::Int)
    if 1 <= t <= 2000
        return t / 1000
    end 

    if 2001 <= t <= 6000
        return 2 + (t - 2000) / 100
    end

    if 6001 <= t <= 8000
        return 42
    end 

    return 43
end

function unimodal_stream(x::Real, mean::Real)
    return pdf(Normal(mean), x)
end

function bimodal_stream(x::Real, mean::Real)
    return 0.6 * pdf(Normal(mean), x) + 0.6 * pdf(Normal(mean + 5), x)
end

function trimodal_stream(x::Real, mean::Real)
    return 0.3 * pdf(Normal(mean - 5), x) + 0.4 * pdf(Normal(mean), x) + 0.3 * pdf(Normal(mean + 5), x)
end

@kwdef struct Experiment
    name::String = "Unimodal"
    domain_min::Float64 = -5.0
    domain_max::Float64 = 48.0
    stream_id::Int = 0
end

exps :: Vector{Experiment} = [
    Experiment(),
    Experiment("Bimodal", -5.0, 53.0, 13),
    Experiment("Trimodal", -10.0, 53.0, 14)
]

function sumsquareddifferencces(true_pdf, est_pdf)
    result_sum = 0.0

    #for i in 1:length(true_pdf)
    for i in eachindex(true_pdf)
        result_sum += (true_pdf[i] - est_pdf[i]) ^ 2
    end

    return result_sum
end


n_points = 1000  # domain computation
n_seeds = 100
experiment = exps[3]
l2_avgs = []

for seed in 1:n_seeds
    S = Sketch()
    lines = readlines("data/stream_$(experiment.stream_id)/stream_$(experiment.stream_id)_$(seed).csv")
    l2_err_sum = 0
    for i in ProgressBar(1:length(lines))
        x = parse(Float64, lines[i])
        mean = test_stream_mean(i)
        update!(S, x)
        
        # Error calculation
        if i % 10 == 0
            X = experiment.domain_min:(experiment.domain_max - experiment.domain_min)/n_points:experiment.domain_max

            # theoretical(x) = unimodal_stream(x, mean)
            # theoretical(x) = bimodal_stream(x, mean)
            theoretical(x) = trimodal_stream(x, mean)
            estimated(x) = probability(S, x)

            Y_stream = theoretical.(X) 
            Y_est = estimated.(X)
            ssd = sumsquareddifferencces(Y_stream, Y_est)
            l2_err = sqrt(ssd * (X[2] - X[1]))
            l2_err_sum += l2_err
        end 
        """
         # Plots
        if i % 100 == 0
            domain = -5:53/1000:48
            println(domain)
            theoretical(x) = unimodal_stream(x, mean)
            estimated(x) = probability(S, x)
            pl = plot(domain, [theoretical.(domain), estimated.(domain)], fmt = :png)
            savefig(pl, "out_$(i).png")
        end
        """
    end
    push!(l2_avgs, l2_err_sum / 1000)
end

io = open("FlexSketch_l2_avgs_$(experiment.stream_id).txt", "w")

for val in l2_avgs
    write(io, "$(val)\n")
end

close(io)