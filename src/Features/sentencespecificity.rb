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
fsmenum = fsm.to_enum
fss = File.open(sentence_scores,'r')
fssenum = fss.to_enum

specificity_scores = Hash.new

loop do
    sm = fsmenum.next
    ss = fssenum.next
    specificity_scores[sm] = ss.to_f
end

fsm.close()
fss.close()

# f1 = File.open(...)
# f2 = File.open(...)

# f1.each.zip(f2.each).each do |line1, line2|
  # Do something with the lines
# end
# zip is one 


ARGF.each do |l_JSN|
    l_JSON = JSON.parse l_JSN
    $f_ss = {}
    l_JSON["splitted_sentences"].each do |l_Article|
        STDERR.puts l_Article["actual_doc_id"]
        tot_sen = l_Article["sentences"].length
        
        sen_num = 0
        l_Article["sentences"].each do |l_senid,l_sentence|
            score = 0.0    
            doc_sen_id = "#{l_Article["doc_id"]}_#{l_senid}"
			if specificity_scores.has_key?(doc_sen_id) then
				score = specificity_scores[doc_sen_id]
			end
            $f_ss[doc_sen_id]=score
        end
    end
    feature={"ss"=>$f_ss}
    l_JSON["features"].push feature
    puts l_JSON.to_json()
end
