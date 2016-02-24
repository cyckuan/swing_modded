#/usr/bin/ruby

logf = open("logfile.txt","a")

logf.puts Time.now.getutc.to_s + " - experiment started"

`ruby -W0 model_trainer.rb`

logf.puts Time.now.getutc.to_s + " - training completed"

`ruby -W0 summary_generator.rb`

logf.puts Time.now.getutc.to_s + " - summary generated"

`ruby -W0 eval.rb`

logf.puts Time.now.getutc.to_s + " - evaluated results"

logf.close()