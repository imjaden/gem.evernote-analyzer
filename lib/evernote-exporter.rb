# encoding=utf-8
require 'csv'
require 'json'
require 'sqlite3'

class Numeric
  def number_to_human_size(shortly = false)
    result = _to_human_size(self.to_i)
    result = result.first(2) if shortly
    result.join.strip
  end

  def _to_human_size(num, result = [], index = 0)
    human_units = ['B ', 'K ', 'M ', 'G ', 'T ', 'P ']

    if num >= 1024
      div, mod = num.divmod(1024)
      result.unshift([mod, human_units[index]])
      _to_human_size(div, result, index + 1)
    else
      result.unshift([num, human_units[index]])
    end
  end
end

class EvernoteExporter
  class << self
    def do
      whoami = `whoami`.strip
      local_account_folder = "/Users/#{whoami}/Library/Application Support/com.yinxiang.Mac/accounts/app.yinxiang.com"

      Dir.glob([local_account_folder, '*'].join('/')) do |local_account_path|
        account_note_exporter(local_account_path)
        puts "\n"
      end
    end

    def account_note_exporter(local_account_path)
      account_id = File.basename(local_account_path)
      sqlite3_db_path = "#{local_account_path}/localNoteStore/LocalNoteStore.sqlite"
      sqlite3_db_connection = SQLite3::Database.new(sqlite3_db_path)

      csv_export_filename = "evernote-#{account_id}-#{Time.now.strftime('%y%m%d%H%M')}.csv"
      CSV.open(csv_export_filename, "wb") do |csv_row|
        csv_row << ['笔记本组', '笔记本', '标题', '更新时间', '笔记大小', '存储大小', '存储大小（格式化）', '存储路径']

        note_index = 1
        note_count = sqlite3_db_connection.execute(sql_note_count).to_a.flatten[0]
        sqlite3_db_connection.prepare(sql_note_list).execute.each_hash do |record|
          filesize_hash = _local_note_filesize(local_account_path, record['uuid'])
          csv_row << [record['zstack'], record['zname'], record['title'], record['updated_at'], record['note_size'], filesize_hash[:local_note_size], filesize_hash[:local_note_size_human], filesize_hash[:local_note_path]]
          set_progress(note_index, note_count, account_id)
          note_index += 1
        end
      end

      puts "Export evernote(#{account_id}) notes to #{csv_export_filename}, Done!"
      puts "Execute `open #{csv_export_filename}`\n"
    end

    protected

    def set_progress(offset, total, account_id, char = '*')
      inx = (1.0*offset/total*100).round(0)
      print "Export evernote(#{account_id}) notes: ", (char * (inx / 2.5).floor).ljust(45, " "), " #{inx}%(#{offset}/#{total})\r"
      sleep 0.005
      $stdout.flush
    end

    def _local_note_path(local_account_path, note_uuid)
      "#{local_account_path}/content/#{note_uuid}"
    end

    def _local_note_filesize(local_account_path, note_uuid)
      filesize_hash = {
        'local_note_path': _local_note_path(local_account_path, note_uuid),
        'local_note_size': 0
      }
      Dir.glob([filesize_hash[:local_note_path], '*'].join('/')) do |path|
        filesize_hash[File.basename(path)] = File.size(path)
        filesize_hash[:local_note_size] += filesize_hash[File.basename(path)] || 0
      end
      filesize_hash[:local_note_size_human] = filesize_hash[:local_note_size].number_to_human_size
      return filesize_hash
    end

    def sql_note_count
      <<-EOF
SELECT 
  count() as cnt
FROM ZENNOTE;
    EOF
    end

    def sql_note_list
      <<-EOF
SELECT 
    note.ZTITLE as title,
    notebook.ZNAME as zname,
    notebook.ZSTACK as zstack,
    date(datetime(note.ZDATEUPDATED, 'unixepoch', 'localtime'), '+31 years') as updated_at, 
    note.ZDATALENGTH as note_size, 
    note.ZLOCALUUID as uuid
FROM ZENNOTE as note
LEFT JOIN ZENNOTEBOOK as notebook on note.ZNOTEBOOK = notebook.Z_PK
ORDER BY note.ZDATEUPDATED DESC;
      EOF
    end
  end
end
