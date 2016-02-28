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

threshold = 0.9


ARGF.each do |l_JSN|
    l_JSON = JSON.parse l_JSN
    $f_ss = {}
    l_JSON["splitted_sentences"].each do |l_Article|
        tot_sen = l_Article["sentences"].length
        
        l_Article["sentences"].each do |l_senid,l_sentence|
        
            score = 0.0    
            doc_sen_id = l_Article["actual_doc_id"] + "_" + l_senid.to_s
            
            if $g_specificity_scores.key?(doc_sen_id) then
                score = $g_specificity_scores[doc_sen_id]
                score = score > threshold ? (score - threshold) / (1 - threshold) : (threshold - score)/threshold
            end
            # STDERR.puts doc_sen_id + " - " + l_sentence + " - " + score.to_s
            
            $f_ss["#{l_Article["doc_id"]}_#{l_senid}"]=score
        end
    end
    feature ={ "ss" => $f_ss }
    l_JSON["features"].push feature
    puts l_JSON.to_json()
end
