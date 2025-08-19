//SystemVerilog
module tmds_encoder (
    input [7:0] pixel_data,
    input hsync, vsync, active,
    output reg [9:0] encoded
);
    // 计算1的个数更高效的实现
    wire [3:0] ones = pixel_data[0] + pixel_data[1] + pixel_data[2] + pixel_data[3] +
                      pixel_data[4] + pixel_data[5] + pixel_data[6] + pixel_data[7];
    
    // 简化决策逻辑
    wire use_inverted = (ones > 4'd4) || (ones == 4'd4 && !pixel_data[0]);
    
    // 预计算可能的输出值
    wire [9:0] active_data = use_inverted ? 
                {1'b1, ~pixel_data[7], pixel_data[6:0] ^ {7{~pixel_data[7]}}} :
                {1'b0, pixel_data[7], pixel_data[6:0] ^ {7{pixel_data[7]}}};
    
    wire [9:0] control_data = {2'b01, hsync, vsync, 6'b000000};
    wire [9:0] idle_data = 10'b1101010100;
    
    // 简化选择逻辑
    always @(*) begin
        if (active)
            encoded = active_data;
        else
            encoded = control_data;
    end
endmodule