//SystemVerilog
module Comparator_DynamicWidth (
    input         [15:0]  data_x,
    input         [15:0]  data_y,
    input         [3:0]   valid_bits, // 有效位配置（1-16）
    output reg            unequal
);
    // 动态掩码生成 - 优化掩码生成逻辑
    reg [15:0] effective_mask;
    
    // 生成更精确的有效位掩码
    always @(*) begin
        case(valid_bits)
            4'd0:  effective_mask = 16'h0000;
            4'd1:  effective_mask = 16'h0001;
            4'd2:  effective_mask = 16'h0003;
            4'd3:  effective_mask = 16'h0007;
            4'd4:  effective_mask = 16'h000F;
            4'd5:  effective_mask = 16'h001F;
            4'd6:  effective_mask = 16'h003F;
            4'd7:  effective_mask = 16'h007F;
            4'd8:  effective_mask = 16'h00FF;
            4'd9:  effective_mask = 16'h01FF;
            4'd10: effective_mask = 16'h03FF;
            4'd11: effective_mask = 16'h07FF;
            4'd12: effective_mask = 16'h0FFF;
            4'd13: effective_mask = 16'h1FFF;
            4'd14: effective_mask = 16'h3FFF;
            4'd15: effective_mask = 16'h7FFF;
            4'd16: effective_mask = 16'hFFFF;
            default: effective_mask = 16'hFFFF;
        endcase
    end
    
    // 比较有效位
    wire [15:0] masked_x = data_x & effective_mask;
    wire [15:0] masked_y = data_y & effective_mask;
    
    always @(*) begin
        unequal = (masked_x != masked_y);
    end
endmodule