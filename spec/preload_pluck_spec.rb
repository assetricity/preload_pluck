require 'spec_helper'

describe PreloadPluck do
  let!(:comment1) { FactoryGirl.create(:comment) }
  let!(:comment2) { FactoryGirl.create(:comment) }

  let(:results) { Comment.order(:created_at).preload_pluck(*preload_pluck) }

  context 'immediate field' do
    let(:preload_pluck) { :text }

    it 'returns 2-dimensional array' do
      expect { results }.to_not exceed_query_limit(1)
      expect(results[0][0]).to eq comment1.text
      expect(results[1][0]).to eq comment2.text
    end
  end

  context 'nested field - one degree' do
    let(:preload_pluck) { 'post.text' }
    it do
      expect { results }.to_not exceed_query_limit(2)
      expect(results[0][0]).to eq comment1.post.text
      expect(results[1][0]).to eq comment2.post.text
    end
  end

  context 'nested field - two degrees' do
    let(:preload_pluck) { 'post.user.name' }
    it do
      expect { results }.to_not exceed_query_limit(3)
      expect(results[0][0]).to eq comment1.post.user.name
      expect(results[1][0]).to eq comment2.post.user.name
    end
  end

  context 'nested field - three degrees' do
    let(:preload_pluck) { 'post.user.company.name' }
    it do
      expect { results }.to_not exceed_query_limit(4)
      expect(results[0][0]).to eq comment1.post.user.company.name
      expect(results[1][0]).to eq comment2.post.user.company.name
    end
  end

  context 'immediate and nested fields' do
    let(:preload_pluck) { [:text, :created_at,
                           'user.name', 'user.created_at',
                           'post.text', 'post.created_at',
                           'post.user.name', 'post.user.created_at',
                           'post.category.name', 'post.category.created_at',
                           'post.user.company.name', 'post.user.company.created_at'] }
    it do
      expect { results }.to_not exceed_query_limit(6)
      expect(results[0][0]).to eq comment1.text
      expect(results[0][1]).to eq comment1.created_at
      expect(results[0][2]).to eq comment1.user.name
      expect(results[0][3]).to eq comment1.user.created_at
      expect(results[0][4]).to eq comment1.post.text
      expect(results[0][5]).to eq comment1.post.created_at
      expect(results[0][6]).to eq comment1.post.user.name
      expect(results[0][7]).to eq comment1.post.user.created_at
      expect(results[0][8]).to eq comment1.post.category.name
      expect(results[0][9]).to eq comment1.post.category.created_at
      expect(results[0][10]).to eq comment1.post.user.company.name
      expect(results[0][11]).to eq comment1.post.user.company.created_at
      expect(results[1][0]).to eq comment2.text
      expect(results[1][1]).to eq comment2.created_at
      expect(results[1][2]).to eq comment2.user.name
      expect(results[1][3]).to eq comment2.user.created_at
      expect(results[1][4]).to eq comment2.post.text
      expect(results[1][5]).to eq comment2.post.created_at
      expect(results[1][6]).to eq comment2.post.user.name
      expect(results[1][7]).to eq comment2.post.user.created_at
      expect(results[1][8]).to eq comment2.post.category.name
      expect(results[1][9]).to eq comment2.post.category.created_at
      expect(results[1][10]).to eq comment2.post.user.company.name
      expect(results[1][11]).to eq comment2.post.user.company.created_at
    end
  end

  context 'immediate null value in path' do
    before { comment2.update(post: nil) }
    let(:preload_pluck) { 'post.text' }
    it do
      expect(results[0][0]).to eq comment1.post.text
      expect(results[1][0]).to eq nil
    end
  end

  context 'nested null value in path' do
    before { comment2.post.update(user: nil) }
    let(:preload_pluck) { 'post.user.company.name' }
    it do
      expect(results[0][0]).to eq comment1.post.user.company.name
      expect(results[1][0]).to eq nil
    end
  end

  context 'with where clause' do
    let(:results) { Comment.joins(:post).where(posts: {text: comment2.post.text}).preload_pluck('post.text') }

    it do
      expect(results.length).to eq 1
      expect(results[0][0]).to eq comment2.post.text
    end
  end

  context 'with has_many relation' do
    let(:preload_pluck) { 'user.posts.text' }

    it 'raises error' do
      expect { results }.to raise_error(/only supports/)
    end
  end

  describe 'performance', :performance do
    require 'activerecord-import/base'
    require 'benchmark'

    before do
      ActiveRecord::Base.transaction do
        num = 50000
        comments = []
        num.times { comments << FactoryGirl.build(:comment, post: comment1.post, user: comment1.user) }
        num.times { comments << FactoryGirl.build(:comment, post: comment2.post, user: comment1.user) }
        num.times { comments << FactoryGirl.build(:comment, post: comment1.post, user: comment2.user) }
        num.times { comments << FactoryGirl.build(:comment, post: comment2.post, user: comment2.user) }
        Comment.import(comments)
      end
    end

    it do
      Benchmark.bmbm do |bm|
        bm.report(:preload) { Comment.preload(:user, post: [:category, user: :company])
                                     .order(:created_at).limit(1000).to_a }

        bm.report(:pluck) { Comment.includes(:user, post: [:category, user: :company])
                                   .order(:created_at).limit(1000)
                                   .pluck(:text, :created_at,
                                          'users.name', 'users.created_at',
                                          'posts.text', 'posts.created_at',
                                          'users_posts.name', 'users_posts.created_at',
                                          'categories.name', 'categories.created_at',
                                          'companies.name', 'companies.created_at') }

        bm.report(:preload_pluck) { Comment.order(:created_at).limit(1000)
                                           .preload_pluck(:text, :created_at,
                                                          'user.name', 'user.created_at',
                                                          'post.text', 'post.created_at',
                                                          'post.user.name', 'post.user.created_at',
                                                          'post.category.name', 'post.category.created_at',
                                                          'post.user.company.name', 'post.user.company.created_at') }
      end
    end
  end
end
