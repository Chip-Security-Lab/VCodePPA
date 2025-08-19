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
    wire [1:0] next_wr, next_rd;
    
    // Status flags
    assign next_wr = wr_ptr + 1;
    assign next_rd = rd_ptr + 1;
    assign empty = (wr_ptr == rd_ptr);
    assign full = (next_wr == rd_ptr);
    
    // Write operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wr_ptr <= 0;
        else if (push && !full) begin
            fifo[wr_ptr] <= data_in;
            wr_ptr <= next_wr;
        end
    end
    
    // Read operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rd_ptr <= 0;
        else if (pop && !empty)
            rd_ptr <= next_rd;
    end
    
    // Shadow output
    assign shadow_out = fifo[rd_ptr];
endmodule