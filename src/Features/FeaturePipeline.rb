#!/usr/bin/ruby

require 'parseconfig'

def build_feature_pipeline(train_test,features,stat_file)

    conf = ParseConfig.new(File.dirname(__FILE__)+'/../../configuration.conf')
    sentence_file = conf.params[train_test]['sentence file']
    sentence_map = conf.params[train_test]['sentence map']
    sentence_scores = conf.params[train_test]['sentence scores']        

    feature_list = features.split(",")
    feature_list = feature_list.map{ |feature| feature.strip}
    pipeline =''
    feature_list.each do |feature|
        case feature
        when 'dfs'
            pipeline += "| ruby -W0 Features/dfs_bigram.rb "
        when 'sp'
            pipeline += "| ruby -W0 Features/sentenceposition.rb "
        when 'crs'
            pipeline += "| ruby -W0 Features/gfs.rb -s #{stat_file} "
        when 'ckld'
            pipeline += "| ruby -W0 Features/ckld.rb -s #{stat_file} "
        when 'sl'
            pipeline += "| ruby -W0 Features/sentencelength.rb "
        when 'ss'
            pipeline += "| ruby -W0 Features/sentencespecificity.rb -s #{sentence_scores} -m #{sentence_map} "
        when 'sshl'
            pipeline += "| ruby -W0 Features/sentencespecificity_hilo_cutoff.rb -s #{sentence_scores} -m #{sentence_map} "
        else
            STDERR.puts "Invalid features"
        end
    end
    
    return pipeline

end