docker pull cdrl/3podr_container:latest

docker run --rm \
  -e R_LIBS_USER=/opt/renv/library \
  -e R_PROFILE_USER=/dev/null \
  -v "$(pwd)/extdata":/project/extdata \
  -v "$(pwd)/configuration.yml":/project/configuration.yml \
  -v "$(pwd)/results":/project/results \
  --entrypoint R \
  cdrl/3podr_container:latest \
  -e 'bookdown::render_book("index.Rmd", output_dir = "results"); saveRDS(global_state, "results/global_state.RDS")'
