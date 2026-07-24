# Build `rwanda_inputs`: the district-level input object for the Milestone 0
# smoke test (issue #45).
#
# ILLUSTRATIVE ONLY. This assembles a deterministic, committed example from
# ballpark parameters and mocked/cached rasters. Its outputs are NOT a real
# analysis of Rwanda; they exist so the pipeline can be exercised end to end.
#
# Source rasters live (git-ignored) in data-raw/raw/ — see that folder's README.
# GADM admin-2 boundaries are fetched reproducibly with geodata and cached there.
#
# Run from the package root:  Rscript data-raw/rwanda_inputs.R

library(terra)

raw_dir <- "data-raw/raw"
species <- c("gambiae", "arabiensis", "funestus") # primary three (issue #45)
attempted_rate <- 1 / 3 # blood-meal rate a* per day (malariasimulation), all three

# --- district boundaries: GADM admin-2 (Rwanda has 30 districts) --------------
rwanda <- geodata::gadm("RWA", level = 2, path = raw_dir)
district_id <- rwanda$NAME_2

# --- source rasters -----------------------------------------------------------
abundance_r <- rast(file.path(raw_dir, "species_abundance.tif"))[[species]]
susceptibility_r <- rast(file.path(raw_dir, "ir_2024_susceptibility.tif"))
net_use_r <- rast(file.path(raw_dir, "net_use_cube.tif"))[["nets_2024"]] # BAU = latest year

# --- area-weighted district means (exact = TRUE handles coarse cells) ---------
district_mean <- function(r) {
  terra::extract(
    r,
    rwanda,
    fun = "mean",
    na.rm = TRUE,
    exact = TRUE,
    ID = FALSE
  )
}
abundance_d <- district_mean(abundance_r)
susceptibility_d <- district_mean(susceptibility_r)[[1]]
net_use_d <- district_mean(net_use_r)[[1]]

# --- vectors table: one row per district x species ----------------------------
# The abundance raster is proportional to the human biting rate, i.e. to m * a
# (adults per human times the human blood-feeding rate), not to m alone. Recover
# adults per human m by dividing out the feeding rate. At baseline (no
# intervention) the successful rate a is approximately the attempted rate a*, so
# we divide by a* here; this lifts m — and hence vectorial capacity — by ~3x.
vectors <- data.frame(
  location_id = rep(district_id, times = length(species)),
  species = rep(species, each = length(district_id)),
  abundance = as.vector(as.matrix(abundance_d)) / attempted_rate,
  row.names = NULL
)

# --- sites table: one row per district ----------------------------------------
sites <- data.frame(
  location_id = district_id,
  susceptibility = susceptibility_d,
  net_use = net_use_d,
  row.names = NULL
)

# --- bionomics table: one row per species -------------------------------------
# Species biology from the malariasimulation defaults (mrc-ide/malariasimulation,
# R/vector_parameters.R): Q0 (human blood index), phi_indoors, phi_bednets, and
# mum (daily mortality hazard). Blood-meal rate 1/3 per day for all three.
#
# HOST-OPPORTUNITY WEIGHTS — EXPLICIT ASSUMPTION. Q0 is a realised human blood
# index (an output), not a host preference. We have no district host-availability
# data, so for this smoke test we adopt the equal-host-availability simplification
# and treat Q0 as preference: the animal weight is (1 - Q0), and the human weight
# Q0 is split indoor/outdoor by phi_indoors. These are RELATIVE weights (only
# their ratios matter; host_destination() renormalises). When real availability
# data exist, the same host-choice path takes preference and availability
# separately, unchanged. See issues #13 and #16.
malariasim <- data.frame(
  species = species,
  q0 = c(0.92, 0.71, 0.94),
  phi_indoors = c(0.90, 0.86, 0.87),
  phi_bednets = c(0.85, 0.80, 0.78),
  mum = c(0.132, 0.132, 0.112)
)

bionomics <- data.frame(
  species = malariasim$species,
  host_indoor = malariasim$q0 * malariasim$phi_indoors,
  host_outdoor = malariasim$q0 * (1 - malariasim$phi_indoors),
  host_animal = 1 - malariasim$q0,
  net_contact = malariasim$phi_bednets,
  attempted_rate = attempted_rate, # blood_meal_rates
  baseline_hazard = malariasim$mum, # mum is already a daily hazard
  infection_probability = 0.5, # ballpark stub (c)
  eip = 10, # ballpark stub (nu), days
  row.names = NULL
)

# --- district geometry (sf), keyed by location_id, for mapping ----------------
geometry <- sf::st_as_sf(rwanda)["NAME_2"]
names(geometry)[names(geometry) == "NAME_2"] <- "location_id"

# --- assemble + validate ------------------------------------------------------
rwanda_inputs <- vci_inputs(
  vectors = vectors,
  bionomics = bionomics,
  sites = sites,
  geometry = geometry
)

print(rwanda_inputs)
usethis::use_data(rwanda_inputs, overwrite = TRUE)
