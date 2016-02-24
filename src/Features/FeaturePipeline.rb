#!/usr/bin/ruby

def build_feature_pipeline(features,stat_file)

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
            pipeline += "| ruby -W0 Features/sentencespecificity.rb "
        else
            STDERR.puts "Invalid features"
        end
    end
    
    return pipeline

end