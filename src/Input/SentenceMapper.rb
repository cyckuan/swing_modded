#/usr/bin/ruby
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/..')
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../..')
require 'rubygems'
require 'pp'
require 'json'
require 'fileutils'
require 'getopt/std'

## Charles Kuan

if __FILE__ == $0 then
    opt = Getopt::Std.getopts("s:m:")
    sentence_file = opt["s"]
    sentence_map = opt["m"]

    fs = open(sentence_file, 'a')
    fsm = open(sentence_map, 'a')

    # Outputs sentences to file

    ARGF.each do |l_JSN|

        l_JSON = JSON.parse l_JSN

        doc_num = 0
        l_JSON["splitted_sentences"].each do |l_Article|

            l_docId = l_Article["actual_doc_id"]

            l_Article["sentences"].each do |l_sen_num, l_sentence|
                fs.puts l_sentence
                fsm.puts l_docId + '_' + l_sen_num.to_s
            end if l_Article["sentences"]

        end if l_JSON['corpus']

        puts l_JSON.to_json()
        
    end

    fs.close()
    fsm.close()

end