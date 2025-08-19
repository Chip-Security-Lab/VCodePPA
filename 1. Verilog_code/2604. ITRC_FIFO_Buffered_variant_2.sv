//SystemVerilog
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
    reg [1:0] w_ptr_next, r_ptr_next;
    
    // 条件求和减法器实现
    wire [1:0] w_ptr_inc = w_ptr + 1;
    wire [1:0] w_ptr_inc_ovf = (w_ptr_inc == 2'b00) ? 2'b00 : w_ptr_inc;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            w_ptr <= 2'b00;
            r_ptr <= 2'b00;
        end
        else begin
            if (int_valid) begin
                fifo[w_ptr] <= int_in;
                w_ptr <= w_ptr_inc_ovf;
            end
        end
    end
    
    assign int_out = fifo[r_ptr];
    assign empty = (w_ptr == r_ptr);
endmodule