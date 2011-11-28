require 'spec_helper'

module OData
  describe Service do
    before(:all) do
      stub_request(:get, /http:\/\/test\.com\/test\.svc\/\$metadata(?:\?.+)?/).
      with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
      to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/sample_service/edmx_categories_products.xml", __FILE__)), :headers => {})

      @cat_prod_service = OData::Service.new "http://test.com/test.svc"
    end
    subject { @cat_prod_service }
    
    context "methods" do
      it { should respond_to :update_object }
      it { should respond_to :delete_object }
      it { should respond_to :save_changes }
      it { should respond_to :load_property }
      it { should respond_to :add_link }
      it { should respond_to :execute }
      it { should respond_to :partial? }
      it { should respond_to :next }
      it { should respond_to :classes }
      it { should respond_to :class_metadata }
      it { should respond_to :collections }
      it { should respond_to :options }
      it { should respond_to :function_imports }
    
      context "after parsing metadata" do
        it { should respond_to :Products }
        it { should respond_to :Categories }
        it { should respond_to :AddToProducts }
        it { should respond_to :AddToCategories }
      end
    end
    context "collections method" do
      subject { @cat_prod_service.collections }
      it { should include 'Products' }
      it { should include 'Categories' }
      it "should expose the edmx type of objects" do
        subject['Products'][:edmx_type].should eq 'RubyODataService.Product'
        subject['Categories'][:edmx_type].should eq 'RubyODataService.Category'
      end
      it "should expose the local model type" do
        subject['Products'][:type].should eq Product
        subject['Categories'][:type].should eq Category                
      end
    end
    context "class metadata" do
      subject { @cat_prod_service.class_metadata }
      it { should_not be_empty}
      it { should have_key 'Product' }
      it { should have_key 'Category' }
      context "should have keys for each property" do
        subject { @cat_prod_service.class_metadata['Category'] }
        it { should have_key 'Id' }
        it { should have_key 'Name' }
        it { should have_key 'Products' }
        it "should return a PropertyMetadata object for each property" do
          subject['Id'].should be_a PropertyMetadata
          subject['Name'].should be_a PropertyMetadata
          subject['Products'].should be_a PropertyMetadata
        end
        it "should have correct PropertyMetadata for Category.Id" do
          meta = subject['Id']
          meta.name.should eq 'Id'
          meta.type.should eq 'Edm.Int32'
          meta.nullable.should eq false
          meta.fc_target_path.should be_nil
          meta.fc_keep_in_content.should be_nil
          meta.nav_prop.should eq false
        end
        it "should have correct PropertyMetadata for Category.Name" do
          meta = subject['Name']
          meta.name.should eq 'Name'
          meta.type.should eq 'Edm.String'
          meta.nullable.should eq false
          meta.fc_target_path.should be_nil
          meta.fc_keep_in_content.should be_nil
          meta.nav_prop.should eq false
        end
        it "should have correct PropertyMetadata for Category.Products" do
          meta = subject['Products']
          meta.name.should eq 'Products'
          meta.type.should be_nil
          meta.nullable.should eq true
          meta.fc_target_path.should be_nil
          meta.fc_keep_in_content.should be_nil
          meta.nav_prop.should eq true
          meta.association.should_not be_nil
        end
      end
    end
    context "function_imports method" do
      subject { @cat_prod_service.function_imports }
      it { should_not be_empty}
      it { should have_key 'CleanDatabaseForTesting' }
      it { should have_key 'EntityCategoryWebGet' }
      it { should have_key 'EntitySingleCategoryWebGet' }
      it "should expose the http method" do
        subject['CleanDatabaseForTesting'][:http_method].should eq 'POST'
        subject['EntityCategoryWebGet'][:http_method].should eq 'GET'
        subject['EntitySingleCategoryWebGet'][:http_method].should eq 'GET'
      end
      it "should expose the return type" do
        subject['CleanDatabaseForTesting'][:return_typo].should be_nil
        subject['EntityCategoryWebGet'][:return_type].should eq Array
        subject['EntityCategoryWebGet'][:inner_return_type].should eq Category
        subject['EntitySingleCategoryWebGet'][:return_type].should eq Category
        subject['EntitySingleCategoryWebGet'][:inner_return_type].should be_nil
        subject['CategoryNames'][:return_type].should eq Array
        subject['CategoryNames'][:inner_return_type].should eq String
      end
      it "should provide a hash of parameters" do
        subject['EntityCategoryWebGet'][:parameters].should be_nil
        subject['EntitySingleCategoryWebGet'][:parameters].should be_a Hash
        subject['EntitySingleCategoryWebGet'][:parameters]['id'].should eq 'Edm.Int32'
      end     
      context "after parsing function imports" do
        subject { @cat_prod_service }
        it { should respond_to :CleanDatabaseForTesting }
        it { should respond_to :EntityCategoryWebGet }
        it { should respond_to :EntitySingleCategoryWebGet }
        it { should respond_to :CategoryNames }
      end
      context "error checking" do
        subject { @cat_prod_service }
        it "should throw an exception if a parameter is passed in to a method that doesn't require one" do
          lambda { subject.EntityCategoryWebGet(1) }.should raise_error(ArgumentError, "wrong number of arguments (1 for 0)")
        end
        it "should throw and exception if more parameters are passed in than required by the function" do
          lambda { subject.EntitySingleCategoryWebGet(1,2) }.should raise_error(ArgumentError, "wrong number of arguments (2 for 1)")
        end
      end
      context "url and http method checks" do
        subject { @cat_prod_service }
        before { stub_request(:any, /http:\/\/test\.com\/test\.svc\/(.*)/) }
        it "should call the correct url with the correct http method for a post with no parameters" do
          subject.CleanDatabaseForTesting
          a_request(:post, "http://test.com/test.svc/CleanDatabaseForTesting").should have_been_made
        end
        it "should call the correct url with the correct http method for a get with no parameters" do
          subject.EntityCategoryWebGet
          a_request(:get, "http://test.com/test.svc/EntityCategoryWebGet").should have_been_made
        end
        it "should call the correct url with the correct http method for a get with parameters" do
          subject.EntitySingleCategoryWebGet(1)
          a_request(:get, "http://test.com/test.svc/EntitySingleCategoryWebGet?id=1").should have_been_made
        end
        it "should call the correct url with the correct http method for a get with parameters" do
          subject.EntitySingleCategoryWebGet(1)
          a_request(:get, "http://test.com/test.svc/EntitySingleCategoryWebGet?id=1").should have_been_made
        end
      end
    end
  end
end