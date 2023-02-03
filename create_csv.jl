using DataFrames
using CSV
using Dates
using ExperienceAnalysis
using DayCounts

df = CSV.read("census_dat.csv", DataFrame)
df.term_date = [d == "NA" ? missing : Date(d, "yyyy-mm-dd") for d in df.term_date]
study_start = Date(2006,6,15)
study_end = Date(2020,2,29)
df_yearly = copy(df)
continue_exposure = df.status .== "Surrender"
to = [ismissing(d) ? study_end : min(study_end,d) for d in df_yearly.term_date]
df_yearly.exposure = exposure.(
    ExperienceAnalysis.Anniversary(Year(1)),   # The basis for our exposures
    df_yearly.issue_date,                             # The `from` date
    to,                                    # the `to` date array we created above
    continue_exposure
)
df_yearly = flatten(df_yearly,:exposure)
df_yearly = filter(row -> row.exposure.to >= study_start, df_yearly)
df_yearly.exposure = map(e -> (from = max(study_start,e.from),to = e.to), df_yearly.exposure)
df_yearly.exposure_fraction = map(e -> yearfrac(e.from, e.to, DayCounts.Thirty360()), df_yearly.exposure)

# make a new column with exposure.from as column from
df_yearly.from = map(e -> e.from, df_yearly.exposure)
# now with exposure.to as column to
df_yearly.to = map(e -> e.to, df_yearly.exposure)
# subset columns `pol_num`, `from`, `to`, `exposure_fraction`
df_yearly = select(df_yearly, [:pol_num, :from, :to, :exposure_fraction])
# write df_yearly to df_jl.csv
CSV.write("df_jl.csv", df_yearly)