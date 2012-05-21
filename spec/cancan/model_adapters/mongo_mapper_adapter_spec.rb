if ENV["MODEL_ADAPTER"] == "mongo_mapper"
  require "spec_helper"

  MongoMapper.connection = Mongo::Connection.new('localhost', 27017)
  MongoMapper.database = "cancan_mongomapper_spec"

  class MongoMapperProject
    include MongoMapper::Document
  end

  describe CanCan::ModelAdapters::MongoMapperAdapter do
    context "MongoMapper defined" do
      before(:each) do
        @ability = Object.new
        @ability.extend(CanCan::Ability)
      end

      after(:each) do
        MongoMapperProject.destroy_all
      end

      it "is for only MongoMapper classes" do
        CanCan::ModelAdapters::MongoMapperAdapter.should_not be_for_class(Object)
        CanCan::ModelAdapters::MongoMapperAdapter.should be_for_class(MongoMapperProject)
        CanCan::ModelAdapters::AbstractAdapter.adapter_class(MongoMapperProject).should == CanCan::ModelAdapters::MongoMapperAdapter
      end

      it "finds record" do
        project = MongoMapperProject.create
        CanCan::ModelAdapters::MongoMapperAdapter.find(MongoMapperProject, project.id).should == project
      end

      it "compares properties on mongomapper documents with the conditions hash" do
        model = MongoMapperProject.new
        @ability.can :read, :mongo_mapper_projects, :id => model.id
        @ability.should be_able_to(:read, model)
      end

      it "is able to read hashes when field is array" do
        one_to_three = MongoMapperProject.create(:numbers => ['one', 'two', 'three'])
        two_to_five  = MongoMapperProject.create(:numbers => ['two', 'three', 'four', 'five'])

        @ability.can :foo, :mongo_mapper_projects, :numbers => 'one'
        @ability.should be_able_to(:foo, one_to_three)
        @ability.should_not be_able_to(:foo, two_to_five)
      end

      it "returns [] when no ability is defined so no records are found" do
        MongoMapperProject.create
        MongoMapperProject.create
        MongoMapperProject.create

        MongoMapperProject.accessible_by(@ability, :read).entries.should == []
      end

      it "returns the correct records based on the defined ability" do
        @ability.can :read, :mongo_mapper_projects, :title => "Sir"
        sir   = MongoMapperProject.create(:title => 'Sir')
        lord  = MongoMapperProject.create(:title => 'Lord')
        dude  = MongoMapperProject.create(:title => 'Dude')

        MongoMapperProject.accessible_by(@ability, :read).entries.should == [sir]
      end

      it "is able to mix empty conditions and hashes" do
        @ability.can :read, :mongo_mapper_projects, :title => 'Sir'
        @ability.can :read, :mongo_mapper_projects
        sir  = MongoMapperProject.create(:title => 'Sir')
        lord = MongoMapperProject.create(:title => 'Lord')

        MongoMapperProject.accessible_by(@ability, :read).count.should == 2
      end

      it "returns everything when the defined ability is access all" do
        @ability.can :access, :all
        sir   = MongoMapperProject.create(:title => 'Sir')
        lord  = MongoMapperProject.create(:title => 'Lord')
        dude  = MongoMapperProject.create(:title => 'Dude')

        MongoMapperProject.accessible_by(@ability, :read).entries.should == [sir, lord, dude]
      end

      it "calls where with matching ability conditions" do
        obj = MongoMapperProject.create(:foo => {:bar => 1})
        @ability.can :read, :mongo_mapper_projects, :foo => {:bar => 1}
        MongoMapperProject.accessible_by(@ability, :read).entries.first.should == obj
      end

      it "excludes from the result if set to cannot" do
        obj = MongoMapperProject.create(:bar => 1)
        obj2 = MongoMapperProject.create(:bar => 2)
        @ability.can :read, :mongo_mapper_projects
        @ability.cannot :read, :mongo_mapper_projects, :bar => 2
        MongoMapperProject.accessible_by(@ability, :read).entries.should == [obj]
      end

      it "combines the rules" do
        obj = MongoMapperProject.create(:bar => 1)
        obj2 = MongoMapperProject.create(:bar => 2)
        obj3 = MongoMapperProject.create(:bar => 3)
        @ability.can :read, :mongo_mapper_projects, :bar => 1
        @ability.can :read, :mongo_mapper_projects, :bar => 2
        MongoMapperProject.accessible_by(@ability, :read).entries.should =~ [obj, obj2]
      end

    end
  end
end
