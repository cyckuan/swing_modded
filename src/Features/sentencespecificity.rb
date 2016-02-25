#/usr/bin/ruby
require 'rubygems'
require 'json'
require 'pp'
require 'parseconfig'

## Charles Kuan

conf = ParseConfig.new(File.dirname(__FILE__)+'/../../configuration.conf')
sentence_file = conf.params['general']['sentence file']
sentence_map = conf.params['general']['sentence map']
sentence_scores = conf.params['general']['sentence scores']

fsm = File.open(sentence_map,'r')
fss = File.open(sentence_scores,'r')

$specificity_scores = Hash.new
fss.each.zip(fsm.each).each do |ss, sm|
    sm.gsub!("\n",'').strip()
    $specificity_scores[sm] = ss.to_f
    STDERR.puts sm + " - " + ss
end

fsm.close()
fss.close()


# 
  # Do something with the lines
# end


threshold = 0.9

ARGF.each do |l_JSN|
    l_JSON = JSON.parse l_JSN
    $f_ss = {}
    l_JSON["splitted_sentences"].each do |l_Article|
        tot_sen = l_Article["sentences"].length
        
        sen_num = 0
        l_Article["sentences"].each do |l_senid,l_sentence|
        
            score = 0.0    
            doc_sen_id = l_Article["doc_id"] + "_" + l_senid
            if $specificity_scores.key?(doc_sen_id) then
                score = $specificity_scores[doc_sen_id]
                score = score > threshold ? (score - threshold) / (1 - threshold) : (threshold - score)/threshold
            end
            STDERR.puts score.to_s + " - " + l_sentence
            $f_ss[doc_sen_id]=score
            
            sen_num += 1
        end
    end
    feature={"ss"=>$f_ss}
    l_JSON["features"].push feature
    puts l_JSON.to_json()
end
