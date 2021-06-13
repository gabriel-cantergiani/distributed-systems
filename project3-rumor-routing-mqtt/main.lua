local rumour = require("rumour")
local config = require("config")

local graphics = {
    elements = {
        evento1 = {
            position_x = 20, position_y = 20, width = 70, height = 50,
            color_r = 146/255, color_g = 208/255, color_b = 80/255,
            text_x = 30, text_y = 30
        },
        evento2 = {
            position_x = 110, position_y = 20, width = 70, height = 50,
            color_r = 146/255, color_g = 208/255, color_b = 80/255,
            text_x = 120, text_y = 30
        },
        consulta = {
            position_x = 200, position_y = 20, width = 70, height = 50,
            color_r = 97/255, color_g = 141/255, color_b = 252/255,
            text_x = 210, text_y = 30
        },
        estado = {
            position_x = 290, position_y = 20, width = 70, height = 50,
            color_r = 255/255, color_g = 192/255, color_b = 103/255,
            text_x = 300, text_y = 30
        },
        logs = {
            position_x = 20, position_y = 100, width = 350, height = 80,
            color_r = 96/255, color_g = 96/255, color_b = 96/255,
            text_x = 30, text_y = 80
        },
        title = {
            position_x = 20, position_y = 5
        }
    }
}


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

    -- Clique Consulta
    if (x >= graphics.elements.consulta.position_x and x <= (graphics.elements.consulta.position_x + graphics.elements.consulta.width)) then
        if (y >= graphics.elements.consulta.position_y and y <= (graphics.elements.consulta.position_y + graphics.elements.consulta.height)) then
            rumour.triggerConsulta()
        end
    end

    -- Clique Estado
    if (x >= graphics.elements.estado.position_x and x <= (graphics.elements.estado.position_x + graphics.elements.estado.width)) then
        if (y >= graphics.elements.estado.position_y and y <= (graphics.elements.estado.position_y + graphics.elements.estado.height)) then
            rumour.Estado()
        end
    end

 end



 function love.load(arg)

    -- Love
    love.window.setMode(400, 200)

    -- Rumour
    node_id = tonumber(arg[1])
    rumour.SetUp(node_id)

    -- Graphics
    graphics.elements.title.text = "Node " .. tostring(node_id)

end

function love.draw()

    -- Background
    love.graphics.setBackgroundColor(212/255, 212/255, 212/255)

    -- Draw buttons
    love.graphics.setColor(graphics.elements.evento1.color_r, graphics.elements.evento1.color_g, graphics.elements.evento1.color_b) -- Green
    love.graphics.rectangle("fill", graphics.elements.evento1.position_x, graphics.elements.evento1.position_y, graphics.elements.evento1.width, graphics.elements.evento1.height)
    love.graphics.rectangle("fill", graphics.elements.evento2.position_x, graphics.elements.evento2.position_y, graphics.elements.evento2.width, graphics.elements.evento2.height)
    
    love.graphics.setColor(graphics.elements.consulta.color_r, graphics.elements.consulta.color_g, graphics.elements.consulta.color_b) -- Blue
    love.graphics.rectangle("fill", graphics.elements.consulta.position_x, graphics.elements.consulta.position_y, graphics.elements.consulta.width, graphics.elements.consulta.height)
    love.graphics.setColor(graphics.elements.estado.color_r, graphics.elements.estado.color_g, graphics.elements.estado.color_b) -- Orange
    love.graphics.rectangle("fill", graphics.elements.estado.position_x, graphics.elements.estado.position_y, graphics.elements.estado.width, graphics.elements.estado.height)

    -- Draw logs window
    love.graphics.setColor(graphics.elements.logs.color_r, graphics.elements.logs.color_g, graphics.elements.logs.color_b) -- Black
    love.graphics.rectangle("fill", graphics.elements.logs.position_x, graphics.elements.logs.position_y, graphics.elements.logs.width, graphics.elements.logs.height)
    
    -- Draw text
    love.graphics.setColor(0/255, 0/255, 0/255) -- Black
    love.graphics.print("evento1", graphics.elements.evento1.text_x, graphics.elements.evento1.text_y)
    love.graphics.print("evento2", graphics.elements.evento2.text_x, graphics.elements.evento2.text_y)
    love.graphics.print("consulta", graphics.elements.consulta.text_x, graphics.elements.consulta.text_y)
    love.graphics.print("estado", graphics.elements.estado.text_x, graphics.elements.estado.text_y)
    love.graphics.print("logs", graphics.elements.logs.text_x, graphics.elements.logs.text_y)
    love.graphics.print(graphics.elements.title.text, graphics.elements.title.position_x, graphics.elements.title.position_y)

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