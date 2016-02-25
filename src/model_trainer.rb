#!/usr/bin/ruby

### Ziheng
$LOAD_PATH.unshift(File.dirname(__FILE__) )
#$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../..')
require 'rubygems'
require 'pp'
require 'parseconfig'
require 'json'
require 'fileutils'
require 'Input/WordSplitter'
require 'Input/StopList'
require 'Features/FeaturePipeline'
require 'SVR/category_statistics' #unigram stats over collection

def print_instances(dir, model_dir, to_file, which_set,xml_file,features,granularity,clean_data,sentence_file,sentence_map,sentence_scores)
    
    if clean_data == "no"
        l_use_clean_data = false
    elsif clean_data == "yes"
        l_use_clean_data = true
    end    


    ## Computing Category statistics for guided summarization
    
    STDERR.puts "computing category statistics ..."

    `rm #{sentence_file}`
    `rm #{sentence_map}`
    `rm #{sentence_scores}`
    
    if granularity == "sentence"
        cat_stat = CategoryStatistics.new 
        stat_file = cat_stat.json_build_category_statistics dir, xml_file, which_set, l_use_clean_data, sentence_file, sentence_map
    elsif granularity == "NP"
        stat_file =  File.dirname(__FILE__)+'/../data/Phrases/NP_2010.txt'
    elsif granularity == "VP"
        stat_file =  File.dirname(__FILE__)+'/../data/Phrases/VP_2010.txt'
    elsif granularity == "PP"
        stat_file =  File.dirname(__FILE__)+'/../data/Phrases/PP_2010.txt'
    end

    STDERR.puts "\ncategory statistics complete!"
    
    STDERR.puts "calculating sentence specificity scores ..."

    `/data/speciteller/speciteller/speciteller.py --inputfile #{sentence_file} --outputfile /#{sentence_scores}`
    
    STDERR.puts "specificity scores complete!"
    
    STDERR.puts "iterating through cases ..."
    
    fh = File.open(to_file, 'w') 
    
    sets = Dir.glob(dir.to_s+'/*/*-'+which_set).sort
    set_cnt = 1

    STDERR.puts "processing sets : " + sets.count.to_s
    
    sets.each do |set_id|
        
        STDERR.puts "current set " + set_cnt.to_s + " : " + set_id
        
        set_cnt += 1

        feature_pipeline = build_feature_pipeline(features, stat_file)
        
        cmd_process_data = "ruby Input/ProcessCleanDocs.rb -s #{set_id} -x #{xml_file} | ruby Input/SentenceSplitter.rb"

        #str = `cd #{File.dirname(__FILE__)}/..; \
        
        str = `#{cmd_process_data} #{feature_pipeline} | ruby -W0 SVR/importance.rb -m #{model_dir}`

        l_JSON = JSON.parse(str)
        l_JSON['importances'].keys.sort_by {|a| a.split('_').map {|e| e.to_i}} .each do |id|
            instance = l_JSON['importances'][id].to_s
            cnt = 1
            l_JSON['features'].each do |feat|
                feat.each do |feat_name, feat_values|
                    #instance << " #{cnt}:#{feat_values[id]}" if feat_values[id] != 0
                    instance << " #{cnt}:#{feat_values[id]}"
                end
                cnt += 1
            end
            fh.puts instance
        end

        if which_set == "A" then
            set_A_fh = File.open("../data/set_A_text/"+File.basename(set_id), 'w')
            l_JSON["splitted_sentences"].each do |l_Article|
                l_Article["sentences"].sort {|a,b| a[0].to_i<=>b[0].to_i} .each do |l_senid, l_sentence| 
                    set_A_fh.puts "#{l_Article["doc_id"]}_#{l_senid}\t" + l_JSON['importances']["#{l_Article["doc_id"]}_#{l_senid}"].to_s + "\t" + l_sentence 
                end
            end
            set_A_fh.close
        end

    end
    fh.close
    
    STDERR.puts "iterations complete!"
    STDERR.puts "please run summary_generator.rb"
    
end



def svr_train(train_dir, model_dir, model_file, which_set,xml_file,features,granularity,clean_data,sentence_file,sentence_map,sentence_scores)
    train_file = model_file.match(/\.model$/) ? model_file.sub(/\.model$/, '.train') : model_file+'.train'
    print_instances(train_dir, model_dir, train_file, which_set,xml_file,features,granularity,clean_data,sentence_file,sentence_map,sentence_scores)
    svm_dir = File.dirname(__FILE__)+'/../lib/svm_light'
    `#{svm_dir}/svm_learn -z r -t 2 #{train_file} #{model_file} 1>&2`
end



if __FILE__ == $0 then
    train_conf = ParseConfig.new(File.dirname(__FILE__)+'/../configuration.conf')
    train_dir = train_conf.params['train']['documents dir']
    model_dir = train_conf.params['train']['model summaries dir']
    model_file = "../data/"+train_conf.params['train']['model file']
    which_set = train_conf.params['train']['document set']
    xml_file = train_conf.params['train']['xml file']
    features = train_conf.params['general']['features']
    granularity = train_conf.params['general']['scoring granularity']
    clean_data = train_conf.params['general']['clean data']
    sentence_file = train_conf.params['general']['sentence file']
    sentence_map = train_conf.params['general']['sentence map']
    sentence_scores = train_conf.params['general']['sentence scores']
    svr_train(train_dir, model_dir, model_file, which_set,xml_file,features,granularity,clean_data,sentence_file,sentence_map,sentence_scores)
end
