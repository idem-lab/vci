# Raw source rasters (not committed)

Drop the large Africa-wide 5 km source rasters here. They are **git-ignored**
(see `.gitignore`): `data-raw/rwanda_inputs.R` crops them to Rwanda, summarises
them to GADM admin-2 districts, and writes the small, committed package dataset
`data/rwanda_inputs.rda`. Nothing here ships with the package
(`data-raw/` is in `.Rbuildignore`).

Expected layers (filenames TBC once added):

- **mosquito abundance** - species_abundance.tif — one layer per species (relative abundance);
- **insecticide resistance** - ir_2024_susceptibility — pyrethroid resistance level;
- **LLIN / ITN use** - net_use_cube — proportion using nets, by year (BAU uses the most recent year).

mosquito_abundance: gives the expected number of bites in a standard human landing catch study
insecticide resistance: gives the 2024 *susceptibility* (fraction of mosquitoes that *died* when exposed to pyrethroid insecticides in a WHO bioassay experiment), not the fraction resistant.
LLIN use: gives the proportion of individuals using nets, by year. Use the 2024 layer (the layers are named) to match the insecticide resistance layer

When you add the files, note their exact filenames, layers/bands, CRS, and units
here so the build script can be wired to them.
