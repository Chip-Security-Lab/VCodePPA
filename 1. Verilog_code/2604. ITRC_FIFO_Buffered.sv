module ITRC_FIFO_Buffered #(
    parameter DW = 8,
    parameter DEPTH = 4
)(
    input clk,
    input rst_n,
    input [DW-1:0] int_in,
    input int_valid,
    output [DW-1:0] int_out,
    output empty
);
    reg [DW-1:0] fifo [0:DEPTH-1];
    reg [1:0] w_ptr, r_ptr;
    
    always @(posedge clk) begin
        if (!rst_n) {w_ptr, r_ptr} <= 0;
        else if (int_valid) begin
            fifo[w_ptr] <= int_in;
            w_ptr <= w_ptr + 1;
        end
    end
    
    assign int_out = fifo[r_ptr];
    assign empty = (w_ptr == r_ptr);
endmodule