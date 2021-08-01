# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "evernote-analyzer".freeze
  s.version = "0.0.10"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.5".freeze) if s.respond_to? :required_rubygems_version=
  s.authors = ["Jaden Li".freeze]
  s.date = "2021-08-01"
  s.description = "Evernote exporter/analyzer".freeze
  s.email = ["jaden.li@jaden.tech".freeze]
  s.files = ["lib/evernote-analyzer.rb".freeze, "lib/evernote-exporter.rb".freeze, "bin/evernote-analyzer".freeze]
  s.executables << 'evernote-analyzer'
  s.add_dependency "sqlite3"

  s.homepage = "https://github.com/imjaden/EvernoteAnalyzer.git".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.1.0".freeze
  s.summary = "Evernote exporter/analyzer".freeze
end
