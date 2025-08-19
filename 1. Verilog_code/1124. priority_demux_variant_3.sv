//SystemVerilog
module priority_demux (
    input wire data_in,                  // Input data
    input wire [2:0] pri_select,         // Priority selection
    output reg [7:0] dout                // Output channels
);
    always @(*) begin
        // 默认所有输出为0
        dout = 8'b0;
        
        // 使用优化后的布尔表达式实现相同功能
        // 使用位掩码和条件赋值，减少冗余的表达式
        case (1'b1)
            pri_select[2]: dout[7:4] = {4{data_in}};
            pri_select[1]: dout[3:2] = {2{data_in}};
            pri_select[0]: dout[1] = data_in;
            default:       dout[0] = data_in;
        endcase
    end
endmodule