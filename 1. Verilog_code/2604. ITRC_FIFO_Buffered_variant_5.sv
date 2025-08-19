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
    reg [1:0] w_ptr_buf1, w_ptr_buf2;
    
    // Buffer stage 1 for w_ptr
    always @(posedge clk) begin
        if (!rst_n) begin
            w_ptr_buf1 <= 0;
        end else begin
            w_ptr_buf1 <= w_ptr;
        end
    end
    
    // Buffer stage 2 for w_ptr
    always @(posedge clk) begin
        if (!rst_n) begin
            w_ptr_buf2 <= 0;
        end else begin
            w_ptr_buf2 <= w_ptr_buf1;
        end
    end
    
    // Main control logic
    always @(posedge clk) begin
        case ({rst_n, int_valid})
            2'b00, 2'b01: begin  // reset active
                {w_ptr, r_ptr} <= 0;
            end
            2'b11: begin  // normal write operation
                fifo[w_ptr] <= int_in;
                w_ptr <= w_ptr + 1;
            end
            default: begin  // 2'b10: reset inactive, no valid data
                // No operation
            end
        endcase
    end
    
    assign int_out = fifo[r_ptr];
    assign empty = (w_ptr_buf2 == r_ptr);
endmodule