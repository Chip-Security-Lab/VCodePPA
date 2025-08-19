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
    reg [1:0] w_ptr_next;
    reg [1:0] ptr_diff;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_ptr <= 2'b0;
            r_ptr <= 2'b0;
            ptr_diff <= 2'b0;
        end else begin
            w_ptr <= w_ptr_next;
            ptr_diff <= w_ptr_next - r_ptr;
        end
    end
    
    always @(*) begin
        w_ptr_next = w_ptr + {1'b0, int_valid};
    end
    
    always @(posedge clk) begin
        if (int_valid) begin
            fifo[w_ptr] <= int_in;
        end
    end
    
    assign int_out = fifo[r_ptr];
    assign empty = (ptr_diff == 2'b0);
endmodule