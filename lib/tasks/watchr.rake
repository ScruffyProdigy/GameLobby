desc "Run Watchr"
task :watchr do
  sh %{bundle exec watchr .watchr}
end