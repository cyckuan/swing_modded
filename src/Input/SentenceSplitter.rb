#/usr/bin/ruby
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/..')
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../..')
require 'rubygems'
require 'pp'
require 'parseconfig'
require 'json'
require 'fileutils'
## Praveen Bysani


#Reads JSON from ProcessTopics.rb and adds splitted_sentences field to the json"

def sentence_breaker(text)
    temp_file = '/tmp/temp.'+rand.to_s
    File.open(temp_file, 'w') do |f|
    f.puts text
    end
    `../lib/duc2003.breakSent/breakSent-multi.pl #{temp_file}`
    lines=File.readlines temp_file
    FileUtils.rm(temp_file)
    return lines

end


ARGF.each do |l_JSN|

conf = ParseConfig.new(File.dirname(__FILE__)+'/../../configuration.conf')
sentence_file = conf.params['general']['sentence file']
sentence_map = conf.params['general']['sentence map']

$g_JSON = JSON.parse l_JSN
$g_docArray = []

doc_num=0
$g_JSON["corpus"].each do |l_Article|
	$g_docId = l_Article["id"]
    l_docSent={"doc_id" => doc_num}
    l_docSent["actual_doc_id"] = l_Article["id"]
    l_docSent["headline"]=l_Article["headline"]
    l_docSent["docset"] = l_Article["docset"]
    l_docSent["topic_text"] = l_Article["topic_text"]
    l_docSent["category"] = l_Article["category"]
    doc_sentences={}
    sen_num=0
    doc_num += 1

	open(sentence_file, 'a') do |sf|
	open(sentence_map, 'a') do |sm|
		l_ArticleText = l_Article["text"]
		l_Sentences = sentence_breaker l_ArticleText#.downcase
		l_Sentences.each do |l_Sentence|
			doc_sentences[sen_num]=l_Sentence.strip
			sf.puts doc_sentences[sen_num]
			sm.puts l_docSent["actual_doc_id"] + '_' + sen_num.to_s
			sen_num +=1
		end
		l_docSent["sentences"]=doc_sentences
	end
	end

    $g_docArray.push l_docSent
end
#l_JSON["splitted_sentences"].push l_docSent 
end


$g_JSON["splitted_sentences"]=$g_docArray
$g_JSON["features"]=[]
puts JSON.generate $g_JSON
