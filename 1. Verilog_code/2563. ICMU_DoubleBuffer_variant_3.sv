//SystemVerilog
module ICMU_DoubleBuffer #(
    parameter DW = 32,
    parameter DEPTH = 8
)(
    input clk,
    input rst_sync,
    input buffer_swap,
    input context_valid,
    input [DW-1:0] ctx_in,
    output [DW-1:0] ctx_out
);
    reg [DW-1:0] buffer_A [0:DEPTH-1];
    reg [DW-1:0] buffer_B [0:DEPTH-1];
    reg buf_select;
    wire [1:0] state;
    wire buf_select_next;
    wire [DW-1:0] buffer_A_next;
    wire [DW-1:0] buffer_B_next;

    assign state = {buffer_swap, context_valid};
    
    // Conditional inversion subtractor for buf_select
    assign buf_select_next = (state[1] & ~buf_select) | (~state[1] & buf_select);
    
    // Conditional inversion subtractor for buffer_A
    assign buffer_A_next = (state[1] & ~buf_select & context_valid) ? ctx_in : buffer_A[0];
    
    // Conditional inversion subtractor for buffer_B
    assign buffer_B_next = (state[1] & buf_select & context_valid) ? ctx_in : buffer_B[0];

    always @(posedge clk) begin
        if (rst_sync) begin
            buf_select <= 0;
        end else begin
            buf_select <= buf_select_next;
        end
    end

    always @(posedge clk) begin
        if (~buf_select) begin
            buffer_A[0] <= buffer_A_next;
        end else begin
            buffer_B[0] <= buffer_B_next;
        end
    end

    assign ctx_out = buf_select ? buffer_B[0] : buffer_A[0];
endmodule