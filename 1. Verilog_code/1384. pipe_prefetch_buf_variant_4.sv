//SystemVerilog
module pipe_prefetch_buf #(parameter DW=32) (
    input clk, en,
    input [DW-1:0] data_in,
    output [DW-1:0] data_out
);
    reg [DW-1:0] stage[0:2];
    wire [DW-1:0] borrow_out;
    wire [DW-1:0] sub_result;
    
    // 借位减法器实现
    genvar i;
    generate
        wire [DW:0] borrow;
        assign borrow[0] = 1'b0;
        
        for (i = 0; i < DW; i = i + 1) begin : borrow_subtractor
            assign sub_result[i] = data_in[i] ^ stage[0][i] ^ borrow[i];
            assign borrow[i+1] = (~data_in[i] & stage[0][i]) | 
                                 (borrow[i] & ~(data_in[i] ^ stage[0][i]));
        end
        
        assign borrow_out = {borrow[DW], borrow[DW-1:1]};
    endgenerate
    
    always @(posedge clk) 
        if(en) begin
            stage[0] <= data_in;
            stage[1] <= sub_result;  // 使用借位减法结果
            stage[2] <= stage[1];
        end
    
    assign data_out = stage[2];
endmodule