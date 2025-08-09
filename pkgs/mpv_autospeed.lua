target_buffer_min = 5
target_buffer_max = 15
overbuffer_factor = 0.05

function main_loop(name, value)
  speed = 1
  if value ~= nil then
    if value > target_buffer_max then
      -- buffer is too large
      speed = 1 + ((value / target_buffer_max - 1) * overbuffer_factor)
    elseif value < target_buffer_min then
      -- running out of buffer
      speed = value / target_buffer_min
    end
  end
  mp.set_property_number("speed", speed)
end

mp.observe_property("demuxer-cache-duration", "number", main_loop)
