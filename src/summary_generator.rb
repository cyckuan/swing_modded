#!/usr/bin/ruby
### Ziheng
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/..')
$LOAD_PATH.unshift(File.dirname(__FILE__) )

require 'rubygems'
require 'pp'
require 'json'
require 'fileutils'
require 'parseconfig'

require 'Input/WordSplitter'
require 'Input/StopList'
require 'Features/FeaturePipeline'
require 'SVR/svr_test_one'
require 'SVR/category_statistics'

if __FILE__ == $0 then

    test_conf = ParseConfig.new(File.dirname(__FILE__)+'/../configuration.conf')
    test_dir = test_conf.params['test']['documents dir']
    model_file = "../data/"+test_conf.params['test']['model file']
    summ_dir = "../data/Summaries/"+test_conf.params['test']['summaries dir']
    which_set = test_conf.params['test']['document set']
    xml_file = test_conf.params['test']['xml file']
    category_stat_file = test_conf.params['test']['category stat file']
    sentence_file = test_conf.params['test']['sentence file']
    sentence_map = test_conf.params['test']['sentence map']
    sentence_scores = test_conf.params['test']['sentence scores']
    
    max_len = test_conf.params['general']['summary length']
    
    features = test_conf.params['general']['features']

    STDERR.puts "computing category statistics ..."
    
    if File.exist?(category_stat_file)
        stat_file = category_stat_file
    else
        cat_stat = CategoryStatistics.new 
        stat_file = cat_stat.json_build_category_statistics test_dir, xml_file, which_set, sentence_file, sentence_map, category_stat_file
    end

    STDERR.puts "computing category complete!"

    STDERR.puts "calculate sentence specificity scores ..."    
    
    if not File.exist?(sentence_scores)
        `/data/speciteller/speciteller/speciteller.py --inputfile #{sentence_file} --outputfile /#{sentence_scores}`
    end
    
    STDERR.puts "sentence specificity scoring complete!"    
    
    STDERR.puts "iterating through cases ..."

    feature_pipeline = build_feature_pipeline('test',features,stat_file)
    
    sets = Dir.glob(test_dir+'/*/*-'+which_set).sort
    set_cnt = 1
    sets.each do |set_id|
        
        # STDERR.puts "current set " + set_cnt.to_s + " : " + set_id
        
        summary_id = File.basename(set_id)
        
        set_cnt += 1

        cmd_process_data = "ruby Input/ProcessCleanDocs.rb -s #{set_id} -x #{xml_file} | ruby Input/SentenceSplitter.rb"
        
        #str = `cd #{File.dirname(__FILE__)}/..; \

        str = `#{cmd_process_data} #{feature_pipeline} \
        | ruby -W0 SVR/svr_test_one.rb -f #{model_file} \
        | ruby -W0 SentenceSelection/MMRSelectionWithSR.rb -s #{xml_file} --reduction --maxlength #{max_len} \
        | ruby -W0 PostProcessing/ChoptoLength.rb -l #{max_len} ` 
        
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
    
    STDERR.puts "iterations complete!"

    # STDERR.puts "commencing evaluations ..."
    #     `ruby -W0 eval.rb`
    # STDERR.puts "evaluations complete!"
end
