#!/usr/bin/ruby
### Ziheng
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/..')
$LOAD_PATH.unshift(File.dirname(__FILE__) )

require 'rubygems'
require 'pp'
require 'json'
require 'fileutils'
require 'Input/WordSplitter'
require 'Input/StopList'
require 'Features/FeaturePipeline'
require 'SVR/svr_test_one'
require 'SVR/category_statistics'
require 'parseconfig'


if __FILE__ == $0 then

    test_conf = ParseConfig.new(File.dirname(__FILE__)+'/../configuration.conf')
    test_dir = test_conf.params['test']['documents dir']
    model_file = "../data/"+test_conf.params['test']['model file']
    summ_dir = "../data/Summaries/"+test_conf.params['test']['summaries dir']
    which_set = test_conf.params['test']['document set']
    xml_file = test_conf.params['test']['xml file']

    max_len = test_conf.params['general']['summary length']
    
    features = test_conf.params['general']['features']
    granularity = test_conf.params['general']['scoring granularity']
    clean_data = test_conf.params['general']['clean data']

    sentence_file = test_conf.params['general']['sentence file']
    sentence_map = test_conf.params['general']['sentence map']
    sentence_scores = test_conf.params['general']['sentence scores']

    
    if clean_data == "no"
        use_clean_data = false
    elsif clean_data == "yes"
        use_clean_data = true
    end

    STDOUT.puts "computing category statistics ..."

    `rm #{sentence_file}`
    `rm #{sentence_map}`
    `rm #{sentence_scores}`
    
    #Computing category statistics for guided summarization   
    if granularity == "sentence"
        cat_stat = CategoryStatistics.new
        stat_file=cat_stat.json_build_category_statistics test_dir, xml_file, which_set, use_clean_data, sentence_file, sentence_map
    elsif granularity == "NP"
        stat_file=  File.dirname(__FILE__)+'/../data/Phrases/NP_2011.txt'
    elsif granularity == "VP"
        stat_file=  File.dirname(__FILE__)+'/../data/Phrases/VP_2011.txt'
    elsif granularity == "PP"
        stat_file=  File.dirname(__FILE__)+'/../data/Phrases/PP_2011.txt'
    end

    STDOUT.puts "computing category complete!"

    STDOUT.puts "calculating sentence specificity scores"
    
    `/data/speciteller/speciteller/speciteller.py --inputfile #{sentence_file} --outputfile /#{sentence_scores}`
    
    STDOUT.puts "specificity scores complete!"
    
    STDOUT.puts "iterating through cases ..."
    
    sets = Dir.glob(test_dir+'/*/*-'+which_set).sort
    set_cnt = 1
    sets.each do |set_id|
        
        STDOUT.puts "current set " + set_cnt.to_s + " : " + set_id
        
        summary_id = File.basename(set_id)
        
        set_cnt += 1

        feature_pipeline = build_feature_pipeline(features,stat_file)

        cmd_process_data = "ruby Input/ProcessCleanDocs.rb -s #{set_id} -x #{xml_file} | ruby Input/SentenceSplitter.rb"

        conf = ParseConfig.new(File.dirname(__FILE__)+'/../configuration.conf')
        sentence_file = conf.params['general']['sentence file']
        sentence_map = conf.params['general']['sentence map']
        sentence_scores = conf.params['general']['sentence scores']
            
        `/data/speciteller/speciteller/speciteller.py --inputfile #{sentence_file} --outputfile /#{sentence_scores}`

        #str = `cd #{File.dirname(__FILE__)}/..; \

        str = `#{cmd_process_data} #{feature_pipeline} \
        | ruby -W0 SVR/svr_test_one.rb -f #{model_file} \
        | ruby -W0 SentenceSelection/MMRSelectionWithSR.rb -s #{xml_file} --reduction --maxlength #{max_len} \
        | ruby -W0 PostProcessing/ChoptoLength.rb -l #{max_len}` 

        l_JSON = JSON.parse(str)

       if which_set == "A" then
           set_A_fh = File.open("../data/set_A_text/"+File.basename(set_id), 'w')
           l_JSON["splitted_sentences"].each do |l_Article|
               l_Article["sentences"].sort {|a,b| a[0].to_i<=>b[0].to_i} .each do |l_senid, l_sentence| 
                   set_A_fh.puts "#{l_Article["doc_id"]}_#{l_senid}\t" + l_JSON['SVR']["#{l_Article["doc_id"]}_#{l_senid}"].to_s + "\t" + l_sentence 
               end
           end
           set_A_fh.close
       end

        Dir.mkdir(summ_dir) if not File::exists?( summ_dir )

        File.open(summ_dir + '/' + summary_id, 'w') do |fh|
            fh.puts l_JSON["summary"]
        end

        if which_set == 'A' then
            `cp -f #{summ_dir + '/' + summary_id} ../data/set_A_summaries/`
        end
    end
    
    STDOUT.puts "iterations complete!"
    
end
