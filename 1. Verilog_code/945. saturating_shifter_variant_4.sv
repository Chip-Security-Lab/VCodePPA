//SystemVerilog
module saturating_shifter (
    input [7:0] din,
    input [2:0] shift,
    output reg [7:0] dout
);
    wire [7:0] shifted_values [0:5];
    wire [7:0] shifted_result;
    
    // 预计算各种移位值
    assign shifted_values[0] = din;
    assign shifted_values[1] = din << 1;
    assign shifted_values[2] = din << 2;
    assign shifted_values[3] = din << 3;
    assign shifted_values[4] = din << 4;
    assign shifted_values[5] = din << 5;
    
    // 根据shift选择正确的移位值
    assign shifted_result = shifted_values[shift];
    
    // 输出逻辑
    always @* begin
        if (shift > 3'd5) 
            dout = 8'hFF;  // 最大移位限制
        else 
            dout = shifted_result;
    end
endmodule