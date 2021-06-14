local rumour = require("rumour")
local config = require("config")

local graphics = {
    elements = {
        evento1 = {color_r = 146/255, color_g = 208/255, color_b = 80/255},
        evento2 = {color_r = 146/255, color_g = 208/255, color_b = 80/255},
        consulta1 = {color_r = 97/255, color_g = 141/255, color_b = 252/255},
        consulta2 = {color_r = 97/255, color_g = 141/255, color_b = 252/255},
        estado = {color_r = 255/255, color_g = 192/255, color_b = 103/255},
        logs = {
            color_r = 96/255, color_g = 96/255, color_b = 96/255,
            log_text = "", log_lines = 0
        },
        title = {},
        mouse_feedback = {
            is_pressed = false,
            x = 0,
            y = 0
        }
    }
}

function love.mousepressed(x, y, button)
    graphics.elements.mouse_feedback.x = x
    graphics.elements.mouse_feedback.y = y
    graphics.elements.mouse_feedback.is_pressed = true
end


function love.mousereleased(x, y, button)

    -- Clique Evento 1
    if (x >= graphics.elements.evento1.position_x and x <= (graphics.elements.evento1.position_x + graphics.elements.evento1.width)) then
        if (y >= graphics.elements.evento1.position_y and y <= (graphics.elements.evento1.position_y + graphics.elements.evento1.height)) then
            rumour.triggerEvento1()
        end
    end

    -- Clique Evento 2
    if (x >= graphics.elements.evento2.position_x and x <= (graphics.elements.evento2.position_x + graphics.elements.evento2.width)) then
        if (y >= graphics.elements.evento2.position_y and y <= (graphics.elements.evento2.position_y + graphics.elements.evento2.height)) then
            rumour.triggerEvento2()
        end
    end

    -- Clique Consulta1
    if (x >= graphics.elements.consulta1.position_x and x <= (graphics.elements.consulta1.position_x + graphics.elements.consulta1.width)) then
        if (y >= graphics.elements.consulta1.position_y and y <= (graphics.elements.consulta1.position_y + graphics.elements.consulta1.height)) then
            rumour.triggerConsulta1()
        end
    end

    -- Clique Consulta2
    if (x >= graphics.elements.consulta2.position_x and x <= (graphics.elements.consulta2.position_x + graphics.elements.consulta2.width)) then
        if (y >= graphics.elements.consulta2.position_y and y <= (graphics.elements.consulta2.position_y + graphics.elements.consulta2.height)) then
            rumour.triggerConsulta2()
        end
    end

    -- Clique Estado
    if (x >= graphics.elements.estado.position_x and x <= (graphics.elements.estado.position_x + graphics.elements.estado.width)) then
        if (y >= graphics.elements.estado.position_y and y <= (graphics.elements.estado.position_y + graphics.elements.estado.height)) then
            rumour.Estado()
        end
    end

    graphics.elements.mouse_feedback.is_pressed = false
 
end

function printLog(message)
    if graphics.elements.logs.log_lines == 10 then
        splitted_string = split_string(graphics.elements.logs.log_text, "\n")
        table.remove(splitted_string, 1)
        graphics.elements.logs.log_text = table.concat(splitted_string, "\n") .. "\n"
        graphics.elements.logs.log_lines = graphics.elements.logs.log_lines - 1
    end
    graphics.elements.logs.log_text = graphics.elements.logs.log_text .. message .. "\n" 
    graphics.elements.logs.log_lines = graphics.elements.logs.log_lines + 1
end


 function love.load(arg)

    -- Rumour
    node_id = tonumber(arg[1])
    rumour.SetUp(node_id, printLog)
    row, column = rumour.getNodePosition()
    rows_columns_num = math.sqrt(config.nodes_num)

    -- Love
    local _, _, flags = love.window.getMode()
    local desktop_width, desktop_height = love.window.getDesktopDimensions(flags.display)
    local window_width = desktop_width/rows_columns_num
    local window_height = desktop_height/rows_columns_num
    love.window.setMode(window_width, window_height)
    love.window.setPosition((desktop_width*(column - 1))/rows_columns_num, (desktop_height*(row - 1))/rows_columns_num + 20, flags.display)

    -- Graphics
    setElementsPositions(window_width, window_height, node_id)

end

function love.draw()

    -- Background
    love.graphics.setBackgroundColor(212/255, 212/255, 212/255)

    -- Draw buttons
    love.graphics.setColor(graphics.elements.evento1.color_r, graphics.elements.evento1.color_g, graphics.elements.evento1.color_b) -- Green
    love.graphics.rectangle("fill", graphics.elements.evento1.position_x, graphics.elements.evento1.position_y, graphics.elements.evento1.width, graphics.elements.evento1.height)
    love.graphics.rectangle("fill", graphics.elements.evento2.position_x, graphics.elements.evento2.position_y, graphics.elements.evento2.width, graphics.elements.evento2.height)
    
    love.graphics.setColor(graphics.elements.consulta1.color_r, graphics.elements.consulta1.color_g, graphics.elements.consulta1.color_b) -- Blue
    love.graphics.rectangle("fill", graphics.elements.consulta1.position_x, graphics.elements.consulta1.position_y, graphics.elements.consulta1.width, graphics.elements.consulta1.height)
    love.graphics.rectangle("fill", graphics.elements.consulta2.position_x, graphics.elements.consulta2.position_y, graphics.elements.consulta2.width, graphics.elements.consulta2.height)
    love.graphics.setColor(graphics.elements.estado.color_r, graphics.elements.estado.color_g, graphics.elements.estado.color_b) -- Orange
    love.graphics.rectangle("fill", graphics.elements.estado.position_x, graphics.elements.estado.position_y, graphics.elements.estado.width, graphics.elements.estado.height)

    -- Draw logs window
    love.graphics.setColor(graphics.elements.logs.color_r, graphics.elements.logs.color_g, graphics.elements.logs.color_b) -- Black
    love.graphics.rectangle("fill", graphics.elements.logs.position_x, graphics.elements.logs.position_y, graphics.elements.logs.width, graphics.elements.logs.height)
    
    -- -- Draw text
    love.graphics.setColor(0/255, 0/255, 0/255) -- Black
    love.graphics.print("evento1", graphics.elements.evento1.text_x, graphics.elements.evento1.text_y)
    love.graphics.print("evento2", graphics.elements.evento2.text_x, graphics.elements.evento2.text_y)
    love.graphics.print("consulta\nevento1", graphics.elements.consulta1.text_x, graphics.elements.consulta1.text_y)
    love.graphics.print("consulta\nevento2", graphics.elements.consulta2.text_x, graphics.elements.consulta2.text_y)
    love.graphics.print("estado", graphics.elements.estado.text_x, graphics.elements.estado.text_y)
    love.graphics.print("logs", graphics.elements.logs.text_x, graphics.elements.logs.text_y)
    love.graphics.print(graphics.elements.title.text, graphics.elements.title.position_x, graphics.elements.title.position_y)
    love.graphics.setColor(255/255, 255/255, 255/255) -- White
    love.graphics.print(graphics.elements.logs.log_text, graphics.elements.logs.text_x + 10, graphics.elements.logs.text_y + 20)

    if graphics.elements.mouse_feedback.is_pressed then
        love.graphics.setColor(255/255, 0/255, 0/255) -- Red
        love.graphics.circle("fill", graphics.elements.mouse_feedback.x, graphics.elements.mouse_feedback.y, 15)
    end
    -- love.graphics.setBackgroundColor(0, 255, 0)
    --  love.graphics.rectangle(mode(fill ou line), x, y, width, height)
    --  love.graphics.draw(image, x, y)
    --  love.graphics.setColor(R, G, B)
    --  love.graphics.print(text, x, y)
end

-- function drawEventsWindow()

-- end

function love.update(dt)
  rumour.HandleMqtt()
end


function setElementsPositions(window_width, window_height, node_id)

    local button_width = window_width * 0.18
    local button_height = window_height * 0.2
    local space_between_width = (window_width * 0.1) / 6
    local space_between_height = window_height * 0.05
    local logs_width = window_width - 2 * space_between_width
    local logs_height = window_height - 3 * space_between_height - button_height


    -- Button Evento1
    graphics.elements.evento1.position_x = space_between_width
    graphics.elements.evento1.position_y = space_between_height
    graphics.elements.evento1.width = button_width
    graphics.elements.evento1.height = button_height
    graphics.elements.evento1.text_x = space_between_width + 10
    graphics.elements.evento1.text_y = space_between_height + 10

    -- Button Evento2
    graphics.elements.evento2.position_x = space_between_width * 2 + button_width
    graphics.elements.evento2.position_y = space_between_height
    graphics.elements.evento2.width = button_width
    graphics.elements.evento2.height = button_height
    graphics.elements.evento2.text_x = space_between_width * 2 + button_width + 10
    graphics.elements.evento2.text_y = space_between_height + 10

    -- Button Consulta1
    graphics.elements.consulta1.position_x = space_between_width * 3 + button_width * 2
    graphics.elements.consulta1.position_y = space_between_height
    graphics.elements.consulta1.width = button_width
    graphics.elements.consulta1.height = button_height
    graphics.elements.consulta1.text_x = space_between_width * 3 + button_width * 2 + 5
    graphics.elements.consulta1.text_y = space_between_height + 10

    -- Button Consulta2
    graphics.elements.consulta2.position_x = space_between_width * 4 + button_width * 3
    graphics.elements.consulta2.position_y = space_between_height
    graphics.elements.consulta2.width = button_width
    graphics.elements.consulta2.height = button_height
    graphics.elements.consulta2.text_x = space_between_width * 4 + button_width * 3 + 5
    graphics.elements.consulta2.text_y = space_between_height + 10

    -- Button Estado
    graphics.elements.estado.position_x = space_between_width * 5 + button_width * 4
    graphics.elements.estado.position_y = space_between_height
    graphics.elements.estado.width = button_width
    graphics.elements.estado.height = button_height
    graphics.elements.estado.text_x = space_between_width * 5 + button_width * 4 + 10
    graphics.elements.estado.text_y = space_between_height + 10

    -- Logs
    graphics.elements.logs.position_x = space_between_width
    graphics.elements.logs.position_y = space_between_height * 2 + button_height + 5
    graphics.elements.logs.width = logs_width
    graphics.elements.logs.height = logs_height
    graphics.elements.logs.text_x = space_between_width + 10
    graphics.elements.logs.text_y = space_between_height + button_height

    -- Title
    graphics.elements.title.position_x = space_between_width
    graphics.elements.title.position_y = 1
    graphics.elements.title.text = "Node " .. tostring(node_id)

end

function split_string (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end