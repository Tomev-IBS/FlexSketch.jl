# Experiments for DEDSDA article.
using CSV

for data in readlines("data/stream_14_1.csv")
    println(parse(Float64, data))
end