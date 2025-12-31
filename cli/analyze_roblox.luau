local filesystem = require("@lute/fs")
local fspath = require("@util/fspath")
local luau = require("@lute/luau")
local visitors = require("@util/syntax/visitors")
local analyzer = require("@util/syntax/analyzer")
local styled = require("@util/pretty_print")

-- 1. Read the test file
local test_file_path = "test_src/roblox_test.luau"
local test_file_content = filesystem.readfiletostring(test_file_path)

-- 2. Parse the file
local parse_result = luau.parse(test_file_content)
local ast = parse_result.root
if not ast then
	print("Failed to parse the file.")
	return
end

-- 3. Analyze the AST
local tracked = analyzer.track_variables(ast)
local computer = analyzer.create_from_tracked(tracked)

-- 4. Create a visitor
local visitor = visitors.create()

visitor.vcall = function(node: luau.AstExprCall)
    print("--- Found a function call ---")
    
    local func_expr = node.func
    if func_expr.tag == "indexname" and func_expr.expression.tag == "global" and func_expr.expression.name.text == "Instance" and func_expr.index.text == "new" then
        print(styled("This is an Instance.new call!", { fg = "cyan" }))

        local arg = node.arguments[1]
        if arg and arg.node.tag == "string" then
            print("Argument is: " .. arg.node.text)
        end
    end

    local evaluated = computer:evaluate(node)
    if evaluated.kind ~= "unknown" then
        print("Evaluated type: " .. evaluated.kind)
    else
        print("Could not determine type through simple evaluation.")
    end

    return true
end

visitor.vlocal_declaration = function(node: luau.AstStatLocal)
    for i, var in node.variables do
        local value = node.values[i]
        if value then
            print("--- Found a local declaration ---")
            print("Variable name: " .. var.node.name.text)
            local evaluated = computer:evaluate(value.node)
            print(evaluated.data)
            if evaluated.kind ~= "unknown" then
                 print("Assigned value type: " .. evaluated.kind)
            else
                print("Could not determine assigned value type through simple evaluation.")
            end
        end
    end
    return true
end

-- 5. Visit the AST
visitor:visit_ast_block(ast, nil)
