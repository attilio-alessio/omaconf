--- @since 25.2.26

local M = {}

local function lock_text(name)
	return ui.Text({
		ui.Line(""),
		ui.Line("   🔒  Locked by obscure"),
		ui.Line(""),
		ui.Line("   " .. name),
		ui.Line(""),
		ui.Line("   Shoulder-surfing protection: no preview."),
		ui.Line("   Press Enter and enter the system password to view."),
	})
end

function M:peek(job)
	local path = tostring(job.file.url)
	local name = path:match("([^/]+)$") or path
	ya.preview_widget(job, lock_text(name):area(job.area))
end

function M:seek(job)
	ya.preview_widget(job, lock_text("Locked by obscure"):area(job.area))
end

return M
