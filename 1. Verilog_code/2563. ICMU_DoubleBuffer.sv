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

    always @(posedge clk) begin
        if (rst_sync) begin
            buf_select <= 0;
        end else if (buffer_swap) begin
            buf_select <= ~buf_select;
        end
    end

    always @(posedge clk) begin
        if (context_valid && !buffer_swap) begin
            if (!buf_select)
                buffer_A[0] <= ctx_in;
            else
                buffer_B[0] <= ctx_in;
        end
    end

    assign ctx_out = buf_select ? buffer_B[0] : buffer_A[0];
endmodule
