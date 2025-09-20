# Experiments for DEDSDA article.
using FlexSketch


S = Sketch()

for data in readlines("data/stream_14_1.csv")
    update!(S, parse(Float64, data))
end

println(S)

