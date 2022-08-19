local _M = {}

local errors_map = {
    ["default"] = {
        title = "Something went wrong",
        message = "We're very sorry for any inconvenience, our service team has been notified."
    },
    [502] = {
        title = "Something went wrong",
        message = "We're very sorry for any inconvenience, our service team has been notified."
    },
    [503] = {
        title = "Something went wrong",
        message = "We're very sorry for any inconvenience, our service team has been notified."
    },
    [504] = {
        title = "Something went wrong",
        message = "We're very sorry for any inconvenience, our service team has been notified."
    },
    [404] = {
        title = "That site doesn't seem to exist",
        message = "Sorry, but there's nothing to see."
    }
}

local function getResponse(code)
    if errors_map[code] then
        return errors_map[code]
    else
        return errors_map["default"]
    end
end

function _M.go(err_code)
    local template = require "resty.template"
    template.render("error_page/error.html", { title = errors_map[err_code]["title"], message = errors_map[err_code]["message"] })
end

return _M

