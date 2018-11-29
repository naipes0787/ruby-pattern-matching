require 'rspec'
require_relative '../src/matcher'
include Matchers

describe 'Pattern matching tests' do
  ################# Matchers #################
  describe 'Matchers' do
    let(:psyduck) do
      psyduck = Object.new

      def psyduck.cuack
        'psy..duck?'
      end

      def psyduck.fly
        '(headache)'
      end

      psyduck
    end

    let(:a_dragon) do
      class Dragon
        def fly
          'do some flying'
        end
      end
      a_dragon = Dragon.new
    end

    context 'variable matcher' do
      it 'Mandar un mensaje call a un Symbol devuelve true' do
        expect(:soy_un_symbol.call('anything')).to be true
        expect(:soy_un_symbol.methods).to include(:call)
      end
    end

    context 'value matcher' do
      it 'Debe devolver true solo si los objetos son iguales' do
        expect(val(5).call(5)).to be true
        expect(val(5).call('5')).to be false
        expect(val(5).call(4)).to be false
      end
    end

    context 'type matcher' do
      it 'Debe devolver true solo si el objeto es del tipo indicado' do
        expect(type(Integer).call(5)).to be true
        expect(type(Symbol).call('Trust me, I am a Symbol...')).to be false
        expect(type(Symbol).call(:a_real_symbol)).to be true
      end
    end

    context 'list matcher' do
      it 'Debe devolver true si el objeto es una lista que coincide con la indicada, por default deben ser del mismo tamaño
           y matchear con variables' do
        an_array = [1, 2, 3, 4]
        expect(list([1, 2, 3, 4], true).call(an_array)).to be true
        expect(list([1, 2, 3, 4], false).call(an_array)).to be true
        expect(list([1, 2, 3, 4, 5], false).call(an_array)).to be false
        expect(list([1, 2, 3], true).call(an_array)).to be false
        expect(list([1, 2, 3], false).call(an_array)).to be true
        expect(list([2, 1, 3, 4], true).call(an_array)).to be false
        expect(list([2, 1, 3, 4], false).call(an_array)).to be false
        expect(list([1, 2, 3]).call(an_array)).to be false
        expect(list([:a, :b, :c, :d]).call(an_array)).to be true
      end
    end

    context 'duck matcher' do
      it 'Cuando el objeto entiende los metodos retorna true' do
        expect(duck(:cuack, :fly).call(psyduck)).to be true
        expect(duck(:+).call(5)).to be true
        expect(duck(:to_s).call(Object.new)).to be true
        expect(duck(:fly).call(a_dragon)).to be true
      end

      it 'Cuando el objeto no entiende los metodos retorna false' do
        expect(duck(:cuack, :fly).call(Object.new)).to be false
        expect(duck(:downcase).call(35)).to be false
        expect(duck(:cuack, :fly).call(a_dragon)).to be false
      end
    end
  end
  ################# Fin Matchers #################

  #################### Combinators ####################
  describe 'Combinators' do
    context 'AND' do
      context 'Cuando se cumplen todos los matchers' do
        it 'retorna true' do
          expect(duck(:+).and(val(5)).call(5)).to eq true
        end
      end
      context 'Cuando no se cumplen todos los matchers' do
        it 'retorna false' do
          expect(duck(:+).and(val(6)).call(5)).to eq false
        end
      end
      context 'Cuando se utilizan más de dos AND' do
        it 'retorna true' do
          expect(duck(:+).and(val(5)).and(duck(:-)).call(5)).to eq true
        end
      end
    end

    context 'OR' do
      context 'Cuando se cumple alguno de los matchers' do
        it 'retorna true' do
          expect(duck(:+).or(val(25)).call(5)).to eq true
        end
      end
      context 'Cuando no se cumple ningun matcher' do
        it 'retorna false' do
          expect(duck(:metodo_falso).and(val(6)).call(5)).to eq false
        end
      end
      context 'Cuando se utilizan más de dos OR' do
        it 'retorna true' do
          expect(duck(:metodo_falso).or(val(6)).or(val(5)).call(5)).to eq true
        end
      end
    end

    context 'Not' do
      context 'Cuando el matcher cumple' do
        it 'retorna false' do
          expect(duck(:+).not.call(5)).to eq false
        end
      end
      context 'Cuando el matcher no cumple' do
        it 'retorna true' do
          expect(duck(:metodo_falso).not.call(5)).to eq true
        end
      end
    end
  end
  ################## Fin Combinators ###################


  ################## Patterns ###################

  describe 'Patterns' do
    context 'With' do
      it 'Ejecuta el bloque que matchea con una lista y no ejecuta los demas bloques' do
        x = [1, 2, 3, 4]
        result = 2
        matches?(x) do
          with(list(x)) {result = 0}
          with(list(x)) {result = 1}
        end
        expect(result).to eq 0
      end

      it 'Matchea un entero con type y val matchers y corre el bloque correspondiente' do
        x = 5
        result = nil
        matches?(x) do
          with(type(Symbol)) {result = 'Fail'}
          with(type(Integer).and(val(5))) {result = 'Pass'}
          with(type(Integer)) {result = 'Fail'}
        end
        expect(result).to eq 'Pass'
      end


      it 'No matchea con ningun patron y corre el bloque otherwise' do
        x = 5
        result = nil
        matches?(x) do
          with(type(Symbol)) {result = 'Fail'}
          with(type(String).and(val(5))) {result = 'Fail'}
          otherwise {result = 'Pass'}
        end
        expect(result).to eq 'Pass'
      end

      it 'Matchea con una lista con enteros' do
        x = [1, 2, 3, 4]
        result = nil
        matches?(x) do
          with(list([1, 2, 3, 4, 5], true)) { result = 1 }
          with(list([1, 2, 3], false)) { result = 2 }
          otherwise { result = 3 }
        end
        expect(result).to eq 2
      end

      it 'Prueba del bind de la lista en matches, particularmente el get' do
        x = [3,5,7]
        result = nil
        matches?(x) do
          with(list([:a, :b, :c])) { result = a + b + c }
          otherwise { result = 'acá no llego' }
        end
        expect(result).to eq 15
      end

      it 'Prueba del bind de la lista en matches, tanto el get como el set' do
        x = [3,5,7]
        result = nil
        matches?(x) do
          with(list([:a, :b, :c])) do
            self.a = 25
            result = 25
          end
          otherwise { result = 'acá no llego' }
        end
        expect(result).to eq 25
      end

      it 'Prueba de la evaluación de un variable matcher' do
        x = 4
        result = nil
        matches?(x) do
          with(:a) do
            self.a = 10
            result = a
          end
          otherwise { result = 'acá no llego' }
        end
        expect(result).to eq 10
      end

      it 'Prueba de la evaluación de una lista de matchers' do
        x = [3,5,7]
        result = nil
        matches?(x) do
          with(list([val(3), val(5), val(7)])) { result = 'acá llego' }
          otherwise { result = 'acá no llego' }
        end
        expect(result).to eq 'acá llego'
      end

      it 'Matchea con una lista que contiene simbolos y matchers dentro' do
        x = [1,2,3]
        result = nil
        matches?(x) do
          with(list([:a, val(2), duck(:+)])) { result = a + 2 }
          with(list([1, 2, 3])) { result = 'acá no llego' }
          otherwise { result = 'acá tampoco llego' }
        end
        expect(result).to eq 3
      end

      it 'Matchea con una lista y bindea la variable' do
        x = [1,2,3]
        result = nil
        matches?(x) do
          with(list([1,2,3]), :mi_lista) { result = mi_lista.inject(:+) }
          with(list([1, 2, 3])) { result = 'acá no llego' }
          otherwise { result = 'acá tampoco llego' }
        end
        expect(result).to eq 6
      end

      it 'Matchea con multiples listas y bindea la variable de la segunda' do
        x = [1,2,3,4]
        result = nil
        matches?(x) do
          with(list([1,2,3], false), list([1,2,3,:a])) { result = a }
          with(list([1, 2, 3])) { result = 'acá no llego' }
          otherwise { result = 'acá tampoco llego' }
        end
        expect(result).to eq 4
      end

      it 'Define un singleton method a un objeto, matchea con duck si ese objeto tiene ese metodo' do
        x =  Object.new
        x.send(:define_singleton_method, :hola) { 'hola' }
        result = nil
        matches?(x) do
          with(duck(:hola)) { result = 'Pass' }
          with(type(Object)) { result =  'acá no llego' }
        end
        expect(result).to eq 'Pass'
      end

      it 'Un entero no es un string ni una lista, debería entrar por el otherwise' do
        x = 2
        result = nil
        matches?(x) do
          with(type(String)) { result = 3 }
          with(list([1, 2, 3])) { result = 'acá no llego' }
          otherwise { result = 'acá sí llego' }
        end
        expect(result).to eq 'acá sí llego'
      end
      it 'Un matches devuelve un valor' do
        x = ["hola", "chau"]
        result = matches?(x) do
          with(type(Integer)) { 3 }
          with(list([:a, val("otra cosa")])) { a }
          with(list([:c, :b])) { nil }
          otherwise { 'acá sí llego' }
        end
        expect(result).to eq nil
      end
    end
  end
  ################## Fin Patterns ###################

end
