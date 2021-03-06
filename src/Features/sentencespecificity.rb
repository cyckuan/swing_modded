#/usr/bin/ruby
require 'rubygems'
require 'json'
require 'pp'
require 'parseconfig'
require 'getopt/std'

## Charles Kuan

def load_specificity_scores(sentence_scores,sentence_map)

    fsm = File.open(sentence_map,'r')
    fss = File.open(sentence_scores,'r')

    specificity_scores = Hash.new
    fss.each.zip(fsm.each).each do |ss, sm|
        sm.gsub!("\n",'').strip()
        specificity_scores[sm] = ss.to_f
    end

    fsm.close()
    fss.close()
    
    return specificity_scores

end


opt = Getopt::Std.getopts("s:m:")
sentence_scores = opt['s']
sentence_map = opt['m']

$g_specificity_scores = load_specificity_scores(sentence_scores,sentence_map)

threshold = 0.4


ARGF.each do |l_JSN|
    l_JSON = JSON.parse l_JSN

    $f_ss = {}
    $f_ssnorm = {}
    $f_ssbinhi = {}
    $f_ssbinlow = {}
    
    l_JSON["splitted_sentences"].each do |l_Article|
        tot_sen = l_Article["sentences"].length
        
        sentence_count = 0
        sentence_specificity_total = 0.0
        sentence_specificity_array = []
        
        l_Article["sentences"].each do |l_senid,l_sentence|
        
            sentence_length = l_sentence.split(/ /).count
            score = 0.0    
            
            doc_sen_id = l_Article["actual_doc_id"] + "_" + l_senid.to_s
            
            if $g_specificity_scores.key?(doc_sen_id) then
                score = $g_specificity_scores[doc_sen_id] 
            end

            # score = score / sentence_length
            
            sentence_count += 1
            sentence_specificity_total += score
            sentence_specificity_array.push(score)
            
            ss_id = "#{l_Article["doc_id"]}_#{l_senid}"
            $f_ss[ss_id]=score
        end
        
        sentence_specificity_mean = sentence_specificity_total / sentence_count
        sentence_specificity_array.sort!
        sentence_specificity_median = sentence_specificity_array[(sentence_count/2).floor]
        
        l_Article["sentences"].each do |l_senid,l_sentence|
        
            sentence_length = l_sentence.split(/ /).count
            score = 0.0    
            
            doc_sen_id = l_Article["actual_doc_id"] + "_" + l_senid.to_s
            
            if $g_specificity_scores.key?(doc_sen_id) then
                score = $g_specificity_scores[doc_sen_id]
            end

            # score = score / sentence_length
            
            # mean_normalised_score = (score - sentence_specificity_mean) / sentence_specificity_mean
            mean_normalised_score = (score - sentence_specificity_mean) / sentence_specificity_mean / sentence_length
            median_normalised_score = (score - sentence_specificity_median) / sentence_specificity_median
            
            ss_id = "#{l_Article["doc_id"]}_#{l_senid}"
            
            $f_ssnorm[ss_id] = mean_normalised_score
            $f_ssnorm[ss_id] = $f_ssnorm[ss_id].abs
            
            STDERR.puts $f_ssnorm[ss_id].to_s + " : " + l_sentence
            
            $f_ssbinhi[ss_id] = score >= sentence_specificity_median ? mean_normalised_score : 0
            $f_ssbinlow[ss_id] = score >= sentence_specificity_median ? 0 : mean_normalised_score
        end
        
    end

    # feature = { "ss" => $f_ss }
    # l_JSON["features"].push feature
    
    feature = { "ssnorm" => $f_ssnorm }
    l_JSON["features"].push feature

    # feature = { "ssbinhi" => $f_ssbinhi }
    # l_JSON["features"].push feature
    
    # feature = { "ssbinlow" => $f_ssbinlow }
    # l_JSON["features"].push feature
    
    puts l_JSON.to_json()
end
