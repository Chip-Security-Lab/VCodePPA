//SystemVerilog
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
    reg [1:0] wr_ptr_next, rd_ptr_next;
    
    // Pre-calculate next pointers to reduce critical path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_next <= 2'd1;
            rd_ptr_next <= 2'd1;
        end else begin
            wr_ptr_next <= wr_ptr + 2'd1;
            rd_ptr_next <= rd_ptr + 2'd1;
        end
    end
    
    // Status flags - simplified logic path
    assign empty = (wr_ptr == rd_ptr);
    assign full = (wr_ptr_next == rd_ptr);
    
    // Write operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wr_ptr <= 2'd0;
        else if (push && !full)
            wr_ptr <= wr_ptr_next;
    end
    
    // Data write operation - separated for better timing
    always @(posedge clk) begin
        if (push && !full)
            fifo[wr_ptr] <= data_in;
    end
    
    // Read operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rd_ptr <= 2'd0;
        else if (pop && !empty)
            rd_ptr <= rd_ptr_next;
    end
    
    // Shadow output - registered for better timing
    reg [WIDTH-1:0] shadow_out_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_out_reg <= {WIDTH{1'b0}};
        else
            shadow_out_reg <= fifo[rd_ptr];
    end
    
    assign shadow_out = shadow_out_reg;
endmodule