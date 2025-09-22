n_seed = 100

for sid in [0, 13, 14]
    l2_sum = 0.0
    for data in readlines("FlexSketch_l2_avgs_$(sid).txt")
        x = parse(Float64, data)
        l2_sum += x
    end
    println(l2_sum / n_seed)
end