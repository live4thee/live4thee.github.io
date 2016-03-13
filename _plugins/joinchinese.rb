# Code taken from:
# http://blog.guorongfei.com/2015/04/25/how-to-fix-the-markdown-newline-blank-problem/
require 'nokogiri'
require 'open-uri'

module Jekyll
	module JoinChineseFilter
		def join_chinese(htmltxt)
			# 生成结构对象
			html_doc = Nokogiri::HTML(htmltxt)

			# 去掉多余的换行
			remove_newline(html_doc.xpath("//body"))
			html_doc.to_html
		end

		private
		def remove_newline(root)
			root.children.each do |child|
				# 跳过 pre 和 code
				next if child.name == 'pre'
				next if child.name == 'code'

				# 如果不是 text 文本节点，递归
				if !child.text?
					remove_newline(child)
				else
					# 如果不是空白文本节点，去掉换行符
					next if child.blank?
					child.content = child.text.gsub(/\n/, '')
				end
			end
		end
	end
end

Liquid::Template.register_filter(Jekyll::JoinChineseFilter)
