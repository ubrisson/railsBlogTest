require 'test_helper'

class ResourcesControllerTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:michael)
  end

  test 'should create new post' do
    log_in_as(@user)
    assert_difference 'Resource.count', 1 do
      title = 'ExampleTitle'
      author = 'ExampleAuthor'
      link = 'example.org'
      post resources_path, params:
          { resource:
               { title: title,
                 author: author,
                 link: link,
                 public: false } }
      assert_not flash.empty?
      assert_redirected_to resources_path
    end
  end

  test 'should not create a new post' do
    log_in_as(@user)
    assert is_logged_in?
    assert_no_difference 'Resource.count' do
      title = 'ExampleTitle'
      link = 'example.org'
      post resources_path, params:
          { resource:
               { title: title,
                 link: link } }
      assert_not flash.empty?
      assert_redirected_to resources_path
      assert_select 'a', text: title, href: link, count: 0
    end
  end

  test 'should get tagged resource' do
    @resource = resources(:orange)
    @resource.tag_list = 'example_tag'
    @resource.save
    get resources_path, params: { tag: 'example_tag' }
    assert_select 'a', text: '#example_tag'
  end

  test 'should get searchable resource' do
    get resources_path, params: { q: 'orange' }
    assert_select 'article', count: 1
  end

  test 'should get tagged and searchable resource' do
    @resource = resources(:most_recent)
    @resource.tag_list = 'orange'
    @resource.save
    get resources_path, params: { q: 'orange' }
    assert_select 'article', count: 2
  end
end
