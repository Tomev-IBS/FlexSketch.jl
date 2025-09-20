# Experiments for DEDSDA article.
using CSV
using FlexSketch


buffer_size:: Int = 30
buffer::Vector{Real} = []
S = Sketch()

for data in readlines("data/stream_14_1.csv")
    update!(S, parse(Float64, data))
end

println(S)

