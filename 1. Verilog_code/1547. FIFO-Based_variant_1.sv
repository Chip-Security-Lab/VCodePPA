//SystemVerilog
// IEEE 1364-2005 SystemVerilog
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
    // FIFO memory
    reg [WIDTH-1:0] fifo [0:DEPTH-1];
    
    // Pointers and next pointers
    reg [1:0] wr_ptr, rd_ptr;
    wire [1:0] next_wr, next_rd;
    
    // Buffered next_wr signals to reduce fanout
    reg [1:0] next_wr_buf1, next_wr_buf2;
    
    // Calculate next pointer values
    assign next_wr = wr_ptr + 1;
    assign next_rd = rd_ptr + 1;
    
    // Status flags
    assign empty = (wr_ptr == rd_ptr);
    assign full = (next_wr_buf1 == rd_ptr);
    
    // Shadow output - read from current read pointer position
    assign shadow_out = fifo[rd_ptr];
    
    // Buffer the next_wr signal to distribute load
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_wr_buf1 <= 2'b00;
        end else begin
            next_wr_buf1 <= next_wr;
        end
    end
    
    // Second buffer for next_wr signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_wr_buf2 <= 2'b00;
        end else begin
            next_wr_buf2 <= next_wr;
        end
    end
    
    // Write pointer management
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 2'b00;
        end else if (push && !full) begin
            wr_ptr <= next_wr_buf2;
        end
    end
    
    // FIFO memory write operation
    always @(posedge clk) begin
        if (push && !full) begin
            fifo[wr_ptr] <= data_in;
        end
    end
    
    // Read pointer management
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 2'b00;
        end else if (pop && !empty) begin
            rd_ptr <= next_rd;
        end
    end
endmodule