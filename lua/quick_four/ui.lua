local popup = require("plenary.popup")
local QuickFourConfig = require("quick_four").QuickFourConfig
local utils = require("quick_four.utils")

M={}

-- 窗口的id
quick_win_id = nil
-- buffer的id
quick_bufh = nil
-- 启动菜单的类型
menu_type = nil
-- 保存数据，路径、文件路径等
marks ={}

-- 创建窗口，包含窗口相关的设置，以及初始化一个空的buffer
-- 本函数用于所有类型创建窗口，根据传入的参数，设置窗口名称
local function create_window(t_name)
		local width = 60
		local height = 10

		local borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
		--local borderchars = {"*","*","*","*","*","*","*","*"}
		local bufnr = vim.api.nvim_create_buf(false,false)
		local win_config = {
				title = t_name,
				line = math.floor(((vim.o.lines - height) / 2) - 1),
				col = math.floor((vim.o.columns - width) / 2),
				minwidth = width,
				minheight = height,
				borderchars = borderchars,
		}
		local quick_win_id ,win = popup.create(bufnr,win_config)
		-- 最终返回buffer的id，以及窗口的id
		return{
				bufnr = bufnr,
				win_id = quick_win_id
		}
end

-- 关闭窗口，并且对窗口，buffer的id变量进行置空
local function close_win()
		-- 在进行关闭窗口之前，应该进行对应的保存工作
		
		vim.api.nvim_win_close(quick_win_id,true)

		quick_win_id = nil
		quick_bufh = nil
		menu_type = nil
end

-- 获取路径列表
local function get_dir_items()

		return {
				".config/nvim/plugged/quick_four/init.lua",
				"~/space/workspace/battle/mydream/goo.java"
		}
end
-- 获取常访问路径的方法
local function get_freq_dirs()
		return QuickFourConfig.freq_dirs
end
-- 获取最近编辑文件的路径
local function get_oldfiles()
		-- 最大文件数量
		local max_file_num = 4
		local current_files = {}
		for _, file in pairs(vim.v.oldfiles or {}) do
				if file and vim.fn.filereadable(file) == 1 then
						-- 这里进行路径前缀替换，会不会把中间的和home相同的部分替换掉？
						if not utils.is_win then
								file = file:gsub(vim.env.HOME, '~')
						end
						table.insert(current_files,file)
						if #current_files >=max_file_num then
								return current_files
						end
				end
		end
		return current_files
end

-- 写入内容，并且对窗口进行一些配置
local function set_win_buf_options(contents)
		vim.api.nvim_set_option_value("number",true,{win = quick_win_id})
		-- buffer 名称设置
		vim.api.nvim_buf_set_name(quick_bufh,"quick_four-menu")
		vim.api.nvim_buf_set_lines(quick_bufh,0,#contents,false,contents)
		vim.api.nvim_buf_set_option(quick_bufh,"filetype","quick_four")
		vim.api.nvim_buf_set_option(quick_bufh,"buftype","acwrite")
		vim.api.nvim_buf_set_option(quick_bufh,"bufhidden","delete")
		vim.api.nvim_buf_set_option(quick_bufh,"modifiable",false) --设置弹窗无法修改

		--vim.cmd(string.format(":call cursor(2,1)"))
end

-- 切换快捷菜单命令
function M.toggle_quick_menu()
		if quick_win_id ~= nil then
				close_win()
				return
		end
		local win_info = create_window()
		-- 文件设置
		--local contents = get_dir_items()
		local contents = get_oldfiles()
		marks = contents
		quick_win_id = win_info.win_id
		quick_bufh = win_info.bufnr

		set_win_buf_options(contents)
end
-- 绑定按键
-- 绑定思路：根据不同弹窗的filetype不同，进行不同的按键绑定
-- 比如目录的话是进行跳转cd，文件的话是进行edit，类似的思路
local function set_menu_keybindings()
		vim.api.nvim_buf_set_keymap(
		quick_bufh,
		"n",
		"q",
		"<Cmd>lua require('quick_four.ui').close_win()<CR>",
		{}
		)
		vim.api.nvim_buf_set_keymap(
		quick_bufh,
		"n",
		"<ESC>",
		"<Cmd>lua require('quick_four.ui').close_win()<CR>",
		{}
		)
		vim.api.nvim_buf_set_keymap(
		quick_bufh,
		"n",
		"<CR>",
		"<Cmd>lua require('quick_four.ui').select_menu_item()<CR>",
		{}
		)
		vim.cmd(
		"autocmd BufLeave <buffer> ++nested ++once silent"..
		" lua require('quick_four.ui').close_win()"
		)
end
-- 对当前选择项进行操作
function M.select_menu_item(id)
		local idx = id or vim.fn.line(".")
		if menu_type == "files" then
				close_win()
				vim.cmd("edit " .. marks[idx])
		elseif menu_type == "dirs" then
				close_win()
				vim.cmd("cd " .. marks[idx])
		else
				return
		end
end

-- 切换到最近文件菜单
function M.toggle_file_menu()
		if quick_win_id ~= nil then
				close_win()
				return
		end
		local win_info = create_window("recent files")
		local contents = get_oldfiles()
		marks = contents
		quick_win_id = win_info.win_id
		quick_bufh = win_info.bufnr
		menu_type = "files"

		set_win_buf_options(contents)
		set_menu_keybindings()
end

-- 切换经常访问的文件夹
function M.toggle_dir_menu()
		if quick_win_id ~= nil then
				close_win()
				return
		end
		local win_info = create_window("freq dirs")
		local contents = get_freq_dirs()
		marks = contents
		quick_win_id = win_info.win_id
		quick_bufh = win_info.bufnr
		menu_type = "dirs"

		set_win_buf_options(contents)
		set_menu_keybindings()
end

M.close_win = close_win
return M
