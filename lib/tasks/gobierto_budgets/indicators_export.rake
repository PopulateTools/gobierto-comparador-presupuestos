namespace :gobierto_budgets do
  namespace :indicators do
    desc "Export the municipalities indicators and planned budgets as indicators.csv and planned_budgets.csv for datos.gobierto.es"
    task :export, [:directory] => :environment do |_task, args|
      directory = Pathname.new(args[:directory] || ".")
      export = GobiertoBudgets::IndicatorsExport.new

      File.open(directory.join("indicators.csv"), "w") { |file| export.write_indicators(file) }
      File.open(directory.join("planned_budgets.csv"), "w") { |file| export.write_planned_budgets(file) }

      puts "Exported #{directory.join("indicators.csv")} and #{directory.join("planned_budgets.csv")}"
    end
  end
end
