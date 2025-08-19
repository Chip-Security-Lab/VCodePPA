//SystemVerilog
module ICMU_BranchPredict #(
    parameter DW = 64,
    parameter PRED_SIZE = 8
)(
    input clk,
    input branch_taken,
    input [DW-1:0] current_ctx,
    output reg [DW-1:0] pred_ctx
);
    reg [DW-1:0] pred_buffer [0:PRED_SIZE-1];
    reg [2:0] pred_index;
    wire [2:0] next_index;
    wire [2:0] wrap_around;
    wire [2:0] borrow;
    wire [2:0] temp_diff;

    // 借位减法器实现
    assign temp_diff[0] = pred_index[0] ^ 1'b1;
    assign borrow[0] = ~pred_index[0];
    
    assign temp_diff[1] = pred_index[1] ^ borrow[0];
    assign borrow[1] = ~pred_index[1] & borrow[0];
    
    assign temp_diff[2] = pred_index[2] ^ borrow[1];
    assign borrow[2] = ~pred_index[2] & borrow[1];

    assign wrap_around = (pred_index == PRED_SIZE-1) ? 3'b0 : temp_diff;
    assign next_index = branch_taken ? 3'b0 : wrap_around;

    always @(posedge clk) begin
        pred_index <= next_index;
        pred_ctx <= pred_buffer[pred_index];
        pred_buffer[pred_index] <= current_ctx;
    end
endmodule