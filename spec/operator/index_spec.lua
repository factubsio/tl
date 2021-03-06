local tl = require("tl")

describe("[]", function()
   describe("on records", function()
      it("ok if indexing by string", function()
         local tokens = tl.lex([[
            local x = { foo = "f" }
            print(x["foo"])
         ]])
         local _, ast = tl.parse_program(tokens)
         local errors = tl.type_check(ast)
         assert.same({}, errors)
      end)
      it("ok without declaration if record is homogenous", function()
         -- pass
         local tokens = tl.lex([[
            local x = { foo = 12, bar = 24 }
            local y = "baz"
            local n: number = x[y]
         ]])
         local _, ast = tl.parse_program(tokens)
         local errors = tl.type_check(ast)
         assert.same({}, errors)
         -- fail as expected
         local tokens = tl.lex([[
            local x = { foo = 12, bar = 24 }
            local y = "baz"
            local n: string = x[y]
         ]])
         _, ast = tl.parse_program(tokens)
         errors = tl.type_check(ast)
         assert.same(1, #errors)
         assert.match("got number, expected string", errors[1].msg, 1, true)
      end)
      it("ok without declaration if key is enum and all keys map to the same type", function()
         -- pass
         local tokens = tl.lex([[
            local Keys = enum
               "foo"
               "bar"
            end
            local x = { foo = 12, bar = 24, bla = "something else" }
            local e: Keys = "foo"
            local n: number = x[e]
         ]])
         local _, ast = tl.parse_program(tokens)
         local errors = tl.type_check(ast)
         assert.same({}, errors)
         -- fail as expected
         local tokens = tl.lex([[
            local Keys = enum
               "foo"
               "bar"
            end
            local x = { foo = 12, bar = true, bla = "something else" }
            local e: Keys = "foo"
            local n: number = x[e]
         ]])
         _, ast = tl.parse_program(tokens)
         errors = tl.type_check(ast)
         assert.same(1, #errors)
         assert.match("cannot index, not all enum values map to record fields of the same type", errors[1].msg, 1, true)
         -- fail as expected
         local tokens = tl.lex([[
            local Keys = enum
               "foo"
               "bar"
               "oops"
            end
            local x = { foo = 12, bar = 12, bla = "something else" }
            local e: Keys = "foo"
            local n: number = x[e]
         ]])
         _, ast = tl.parse_program(tokens)
         errors = tl.type_check(ast)
         assert.same(1, #errors)
         assert.match("enum value 'oops' is not a field", errors[1].msg, 1, true)
      end)
      it("fail if indexing by invalid string", function()
         local tokens = tl.lex([[
            local x = { foo = "f" }
            print(x["bar"])
         ]])
         local _, ast = tl.parse_program(tokens)
         local errors = tl.type_check(ast)
         assert.same(1, #errors)
         assert.match("invalid key 'bar' in record 'x'", errors[1].msg, 1, true)
      end)
   end)
end)
