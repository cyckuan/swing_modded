#/usr/bin/ruby
require 'rubygems'
require 'json'
require 'pp'
## Charles Kuan

conf = ParseConfig.new(File.dirname(__FILE__)+'/../configuration.conf')
sentence_file = conf.params['general']['sentence file']
sentence_map = conf.params['general']['sentence map']
sentence_scores = conf.params['general']['sentence scores']

fsm = File.open(sentence_map,'r').read.to_enum
fss = File.open(sentence_scores,'r').to_enum

loop do
	sm = fsm.next
	ss = fss.next
	specificity_scores[sm] = ss
end

fsm.close
fss.close

for i in 1..line_total
   specificity_scores[fsm] = fss
end

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
			score = specificity_scores[doc_sen_id]
            $f_ss[doc_sen_id]=score
        end
    end
    feature={"ss"=>$f_ss}
    l_JSON["features"].push feature
    puts l_JSON.to_json()
end
