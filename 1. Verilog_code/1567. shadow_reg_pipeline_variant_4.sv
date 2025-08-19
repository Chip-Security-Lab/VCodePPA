//SystemVerilog
module shadow_reg_pipeline #(parameter DW=8) (
    input clk, en,
    input [DW-1:0] data_in,
    input [DW-1:0] subtrahend,  // 被减数
    output reg [DW-1:0] data_out
);
    reg [DW-1:0] shadow, pipe_reg;
    wire [DW-1:0] subtraction_result;
    wire [DW:0] borrow;
    
    // 使用条件求和减法算法实现减法器
    assign borrow[0] = 1'b0;
    
    genvar i;
    generate
        for(i = 0; i < DW; i = i + 1) begin: sub_loop
            assign subtraction_result[i] = data_in[i] ^ subtrahend[i] ^ borrow[i];
            assign borrow[i+1] = (~data_in[i] & subtrahend[i]) | (~data_in[i] & borrow[i]) | (subtrahend[i] & borrow[i]);
        end
    endgenerate
    
    always @(posedge clk) begin
        if(en) shadow <= subtraction_result;
        pipe_reg <= shadow;
        data_out <= pipe_reg;
    end
endmodule