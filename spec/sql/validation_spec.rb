class SqlValidatableTask
  include MotionModel::Model
  include MotionModel::FMDBModelAdapter
  include MotionModel::Validatable
  columns       :name => :string,
                :email => :string,
                :some_day => :string,
                :some_float => :float,
                :some_int => :int

  validate      :name, :presence => true
  validate      :name, :length => 2..10
  validate      :email, :email => true
  validate      :some_day, :format => /\A\d?\d-\d?\d-\d\d\Z/
  validate      :some_day, :length => 8..10
  validate      :some_float, :presence => true
  validate      :some_int, :presence => true
end

describe "validations" do
  before do
    MotionModel::Store.config(MotionModel::FMDBAdapter.new('spec.db', reset: true, ns_log: false))
    SqlValidatableTask.create_table
    @valid_tasks = {
      :name => 'bob',
      :email => 'bob@domain.com',
      :some_day => '12-12-12',
      :some_float => 1.080,
      :some_int => 99
    }
  end

  describe "presence" do
    it "is initially false if name is blank" do
      task = SqlValidatableTask.new(@valid_tasks.except(:name))
      task.valid?.should === false
    end

    it "contains correct error message if name is blank" do
      task = SqlValidatableTask.new(@valid_tasks.except(:name))
      task.valid?
      task.error_messages_for(:name).first.should ==
        "incorrect value supplied for name -- should be non-empty."
    end

    it "is true if name is filled in" do
      task = SqlValidatableTask.create(@valid_tasks.except(:name))
      task.name = 'bob'
      task.valid?.should === true
    end

    it "is false if the float is nil" do
      task = SqlValidatableTask.new(@valid_tasks.except(:some_float))
      task.valid?.should === false
    end

    it "contains multiple error messages if name and some_float are blank" do
      task = SqlValidatableTask.new(@valid_tasks.except(:name, :some_float))
      task.valid?
      task.error_messages.length.should == 3
      task.error_messages_for(:name).length.should == 2
      task.error_messages_for(:some_float).length.should == 1

      task.error_messages_for(:name).should.include 'incorrect value supplied for name -- should be non-empty.'
      task.error_messages_for(:name).should.include "incorrect value supplied for name -- should be between 2 and 10 characters long."
      task.error_messages_for(:some_float).should.include "incorrect value supplied for some_float -- should be non-empty."
    end

    it "is true if the float is filled in" do
      task = SqlValidatableTask.new(@valid_tasks)
      task.valid?.should === true
    end

    it "is false if the integer is nil" do
      task = SqlValidatableTask.new(@valid_tasks.except(:some_int))
      task.valid?.should === false
    end

    it "is true if the integer is filled in" do
      task = SqlValidatableTask.new(@valid_tasks)
      task.valid?.should === true
    end

    it "is true if the Numeric datatypes are zero" do
      task = SqlValidatableTask.new(@valid_tasks)
      task.some_float = 0
      task.some_int = 0
      task.valid?.should === true
    end
  end

  describe "length" do
    it "succeeds when in range of 2-10 characters" do
      task = SqlValidatableTask.create(@valid_tasks.except(:name))
      task.name = '123456'
      task.valid?.should === true
    end

    it "fails when length less than two characters" do
      task = SqlValidatableTask.create(@valid_tasks.except(:name))
      task.name = '1'
      task.valid?.should === false
      task.error_messages_for(:name).first.should ==
        "incorrect value supplied for name -- should be between 2 and 10 characters long."
    end

    it "fails when length greater than 10 characters" do
      task = SqlValidatableTask.create(@valid_tasks.except(:name))
      task.name = '123456709AB'
      task.valid?.should === false
      task.error_messages_for(:name).first.should ==
        "incorrect value supplied for name -- should be between 2 and 10 characters long."
    end
  end

  describe "email" do
    it "succeeds when a valid email address is supplied" do
      SqlValidatableTask.new(@valid_tasks).should.be.valid?
    end

    it "fails when an empty email address is supplied" do
      SqlValidatableTask.new(@valid_tasks.except(:email)).should.not.be.valid?
    end

    it "fails when a bogus email address is supplied" do
      SqlValidatableTask.new(@valid_tasks.except(:email).merge({:email => 'bogus'})).should.not.be.valid?
    end
  end

  describe "format" do
    it "succeeds when date is in the correct format" do
      SqlValidatableTask.new(@valid_tasks).should.be.valid?
    end

    it "fails when date is in incorrect format" do
      SqlValidatableTask.new(@valid_tasks.except(:some_day).merge({:some_day => 'a-12-12'})).should.not.be.valid?
    end
  end

  describe "validating one element" do
    it "validates any properly formatted arbitrary string and succeeds" do
      task = SqlValidatableTask.new
      task.validate_for(:some_day, '12-12-12').should == true
    end

    it "validates any improperly formatted arbitrary string and fails" do
      task = SqlValidatableTask.new
      task.validate_for(:some_day, 'a-12-12').should == false
    end
  end
end

class SqlVTask
  include MotionModel::Model
  include MotionModel::FMDBModelAdapter
  include MotionModel::Validatable

  columns :name => :string
  validate :name, :presence => true
end

describe "saving with validations" do

  before do
    MotionModel::Store.config(MotionModel::FMDBAdapter.new('spec.db', reset: true, ns_log: false))
    SqlVTask.create_table
  end

  it "fails loudly" do
    task = SqlVTask.new
    lambda { task.save!}.should.raise
  end

  it "can skip the validations" do
    SqlVTask.count.should == 0
    # task = SqlVTask.new
    # lambda { task.save({:validate => false})}.should.change { SqlVTask.count }
  end

  it "should not save when validation fails" do
    task = SqlVTask.new
    lambda { task.save }.should.not.change{ SqlVTask.count }
    task.save.should == false
  end

  it "saves it when everything is ok" do
    task = SqlVTask.new
    task.name = "Save it"
    lambda { task.save }.should.change { SqlVTask.count }
  end

end
