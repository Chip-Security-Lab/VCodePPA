//SystemVerilog
module Comparator_DynamicWidth (
    input         [15:0]  data_x,
    input         [15:0]  data_y,
    input         [3:0]   valid_bits, // 有效位配置（1-16）
    output reg            unequal
);
    // 有效位掩码
    reg [15:0] mask;
    // 经过掩码处理的数据
    reg [15:0] masked_x;
    reg [15:0] masked_y;
    
    // 根据有效位生成掩码
    always @(*) begin
        case(valid_bits)
            4'd0:  mask = 16'hFFFF;
            4'd1:  mask = 16'hFFFE;
            4'd2:  mask = 16'hFFFC;
            4'd3:  mask = 16'hFFF8;
            4'd4:  mask = 16'hFFF0;
            4'd5:  mask = 16'hFFE0;
            4'd6:  mask = 16'hFFC0;
            4'd7:  mask = 16'hFF80;
            4'd8:  mask = 16'hFF00;
            4'd9:  mask = 16'hFE00;
            4'd10: mask = 16'hFC00;
            4'd11: mask = 16'hF800;
            4'd12: mask = 16'hF000;
            4'd13: mask = 16'hE000;
            4'd14: mask = 16'hC000;
            4'd15: mask = 16'h8000;
            4'd16: mask = 16'h0000;
            default: mask = 16'h0000;
        endcase
    end
    
    // 应用掩码到输入数据
    always @(*) begin
        masked_x = data_x & ~mask;
        masked_y = data_y & ~mask;
    end
    
    // 比较掩码后的数据
    always @(*) begin
        unequal = (masked_x != masked_y);
    end
endmodule