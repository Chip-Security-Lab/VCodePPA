//SystemVerilog
module BarrelShifter #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    input [3:0] shift_ctrl,
    output reg [WIDTH-1:0] data_out
);
    // 使用查找表辅助左移操作
    reg [WIDTH-1:0] shift_lut [0:15];
    
    always @(*) begin
        // 展开的循环，初始化查找表
        shift_lut[0] = data_in << 4'h0;
        shift_lut[1] = data_in << 4'h1;
        shift_lut[2] = data_in << 4'h2;
        shift_lut[3] = data_in << 4'h3;
        shift_lut[4] = data_in << 4'h4;
        shift_lut[5] = data_in << 4'h5;
        shift_lut[6] = data_in << 4'h6;
        shift_lut[7] = data_in << 4'h7;
        shift_lut[8] = data_in << 4'h8;
        shift_lut[9] = data_in << 4'h9;
        shift_lut[10] = data_in << 4'hA;
        shift_lut[11] = data_in << 4'hB;
        shift_lut[12] = data_in << 4'hC;
        shift_lut[13] = data_in << 4'hD;
        shift_lut[14] = data_in << 4'hE;
        shift_lut[15] = data_in << 4'hF;
        
        // 从查找表中选择结果
        data_out = shift_lut[shift_ctrl];
    end
endmodule