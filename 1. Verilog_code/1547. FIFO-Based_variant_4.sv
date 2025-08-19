//SystemVerilog
//IEEE 1364-2005 Verilog
module fifo_shadow_reg #(
    parameter WIDTH = 8,
    parameter DEPTH = 4
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire push,
    input wire pop,
    output wire [WIDTH-1:0] shadow_out,
    output wire full,
    output wire empty
);
    // FIFO memory and pointers
    reg [WIDTH-1:0] fifo [0:DEPTH-1];
    reg [1:0] wr_ptr, rd_ptr;
    reg [1:0] next_wr_buf;
    wire [1:0] next_wr, next_rd;
    
    // Status flags
    assign next_wr = wr_ptr + 1;
    assign next_rd = rd_ptr + 1;
    assign empty = (wr_ptr == rd_ptr);
    assign full = (next_wr_buf == rd_ptr);
    
    // Flattened always block with combined conditions
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            next_wr_buf <= 0;
        end
        else if (push && !full && pop && !empty) begin
            // Both push and pop operations simultaneously
            fifo[wr_ptr] <= data_in;
            wr_ptr <= next_wr;
            rd_ptr <= next_rd;
            next_wr_buf <= next_wr;
        end
        else if (push && !full) begin
            // Only push operation
            fifo[wr_ptr] <= data_in;
            wr_ptr <= next_wr;
            next_wr_buf <= next_wr;
        end
        else if (pop && !empty) begin
            // Only pop operation
            rd_ptr <= next_rd;
            next_wr_buf <= next_wr;
        end
        else begin
            // No operation, just update buffer
            next_wr_buf <= next_wr;
        end
    end
    
    // Shadow output
    assign shadow_out = fifo[rd_ptr];
endmodule