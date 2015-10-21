require 'spec_helper'
require "#{Rails.root}/lib/item/download_items_helper.rb"

DOCUMENT_FILENAMES = ['document.txt', 'document.wav', 'sample-plain.txt', 'sample-raw.txt', 'audio-doc.mp3']

def test_document_filter(glob_pattern, expected_files)
  expect(Item::DownloadItemsHelper.filter_item_files(DOCUMENT_FILENAMES, glob_pattern)).to eq expected_files
end

describe 'filter_item_files' do
  describe 'filter item files using a specific glob pattern' do
    it 'should return all files with the glob *' do
      test_document_filter('*', DOCUMENT_FILENAMES)
    end

    it 'should only return files matching an ending with glob pattern' do
      test_document_filter('*.txt', ['document.txt', 'sample-plain.txt', 'sample-raw.txt'])
      test_document_filter('*.wav', ['document.wav'])
    end

    it  'should only return files matching a starting with glob pattern' do
      test_document_filter('sample-*', ['sample-plain.txt', 'sample-raw.txt'])
    end

    it 'should only return files matching a glob union pattern' do
      test_document_filter('{*.wav}', ['document.wav'])
      test_document_filter('{*.mp3,*.wav}', ['document.wav', 'audio-doc.mp3'])
    end

    it 'should return files corresponding to an exact filename' do
      test_document_filter('document.txt', ['document.txt'])
    end
  end
end
