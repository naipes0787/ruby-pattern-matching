class Symbol
  def call(value)
    true
  end
end

module Combinable
  def and(*matchers)
    AndCombinator.new(self, *matchers)
  end

  def or(*matchers)
    OrCombinator.new(self, *matchers)
  end

  def not
    NotCombinator.new(self)
  end
end

module Matchers
  def val(parameter)
    ValMatcher.new(parameter)
  end

  def type(parameter)
    TypeMatcher.new(parameter)
  end


  def list(array, check_size = true)
    ListMatcher.new(array, check_size)
  end


  def duck(*methods)
    DuckMatcher.new(methods)
  end
end


class Matcher
  include Combinable

  attr_accessor :parameter

  def initialize(parameter)
    self.parameter = parameter
  end
end


class ValMatcher < Matcher
  def call(object)
    parameter.eql?(object)
  end
end


class TypeMatcher < Matcher
  def call(object)
    object.is_a?(parameter)
  end
end


class ListMatcher < Matcher
  attr_accessor :check_size

  def initialize(parameter, check_size)
    super(parameter)
    self.check_size = check_size
  end

  def call(object)
    if !object.is_a?(Array)
      false
    elsif check_size
      lists_match(parameter, object, object.length == parameter.length)
    else
      lists_match(parameter, object, true)
    end
  end

  private
  def lists_match(list1, list2, init_check_value)
    init_check_value and (
      list1.zip(list2).map do
        #Para que matcheen (deben ser iguales) o (y debe ser un símbolo) o (x.call(y) debe dar TRUE)
        |x, y| (x == y or matches(x,y))
      end
    ).all?
  end

  def matches(matcher,value)
    matcher?(matcher) && matcher.call(value)
  end

  def matcher?(obj)
    obj.is_a?(Matcher) || obj.is_a?(Symbol)
  end
end


class DuckMatcher < Matcher
  def call(object)
    parameter.all? { |method| object.respond_to?(method) }
  end
end


class Combinator
  include Combinable

  attr_accessor :matchers

  def initialize(*matchers)
    self.matchers = matchers
  end
end


class AndCombinator < Combinator
  def call(object)
    matchers.all? {|matcher| matcher.call(object)}
  end
end


class OrCombinator < Combinator
  def call(object)
    matchers.any? {|matcher| matcher.call(object)}
  end
end


class NotCombinator < Combinator
  def call(object)
    !matchers.first.call(object)
  end
end

class Pattern
  attr_accessor :matchers, :block

  def initialize(matchers, block)
    self.matchers = matchers
    self.block = block
  end

  def matches(obj)
   self.matchers.all? {|matcher| matcher.call(obj)}
  end

  def bind(contexto, object)
    variableMatcher = matchers.select {|matcher| matcher.is_a? Symbol}
    listMatchers = matchers.select {|matcher| matcher.is_a? ListMatcher}
    contexto.manage_list_matchers(listMatchers) if !listMatchers.empty? and object.is_a? Array
    variableMatcher.each do |variable|
      contexto.bind_variable(variable, object)
    end
  end
end

class OtherwisePattern < Pattern
  def matches(obj)
    true
  end

  def bind(contexto, object)
  end
end


class PatternMatcher
  attr_accessor :object, :patterns

  def initialize(object)
    self.object = object
    self.patterns = []
  end

  def with(*matchers, &block)
    # matches = matchers.all? {|matcher| matcher.call(object)}
    # variableMatcher = matchers.select {|matcher| matcher.is_a? Symbol}
    # listMatchers = matchers.select {|matcher| matcher.is_a? ListMatcher}
    #
    # if matches and result.nil?
    #   manage_list_matchers(listMatchers) if !listMatchers.empty? and object.is_a? Array
    #   variableMatcher.each do |variable|
    #     bind_variable(variable, object)
    #   end
    #   self.result = instance_eval(&block)
    # end
    # self.result
    patterns << Pattern.new(matchers, block)
  end

  def otherwise(&block)
    patterns << OtherwisePattern.new(nil, block)
  end

  def execute
    pattern = self.patterns.find do |pattern|
      pattern.matches(self.object)
    end

    if(pattern.nil?)
      raise 'Match error'
    else
      pattern.bind(self, self.object)
      self.instance_eval(&pattern.block)
    end
  end

    # Crea en self el getter y setter de variable, a la cual luego se le asigna object
    def bind_variable(variable, object)
      self.singleton_class.send(:attr_accessor, variable)
      self.send("#{variable}=", object)
    end

    def manage_list_matchers(list_matchers)
      list_matchers.each do |matcher|
        matcher.parameter.zip(object).each do |variable, object|
          if variable.is_a? Symbol
            bind_variable(variable, object)
          end
        end
      end
    end
end

def matches?(object, &bloque)
  patternMatcher = PatternMatcher.new(object)
  patternMatcher.instance_eval(&bloque)
  patternMatcher.execute
end

