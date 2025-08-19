//SystemVerilog
// Top-level module
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
    // Internal signals
    wire [1:0] wr_ptr, rd_ptr;
    wire [1:0] next_wr, next_rd;
    wire [WIDTH-1:0] fifo_data_out;
    wire write_en;
    
    // Status flags generation
    assign next_wr = wr_ptr + 1;
    assign next_rd = rd_ptr + 1;
    assign empty = (wr_ptr == rd_ptr);
    assign full = (next_wr == rd_ptr);
    assign write_en = push && !full;
    
    // FIFO memory submodule
    fifo_memory #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) memory_inst (
        .clk(clk),
        .write_en(write_en),
        .wr_ptr(wr_ptr),
        .rd_ptr(rd_ptr),
        .data_in(data_in),
        .data_out(shadow_out)
    );
    
    // Write pointer controller
    write_pointer_ctrl #(
        .DEPTH(DEPTH)
    ) wr_ctrl_inst (
        .clk(clk),
        .rst_n(rst_n),
        .push(push),
        .full(full),
        .next_wr(next_wr),
        .wr_ptr(wr_ptr)
    );
    
    // Read pointer controller
    read_pointer_ctrl #(
        .DEPTH(DEPTH)
    ) rd_ctrl_inst (
        .clk(clk),
        .rst_n(rst_n),
        .pop(pop),
        .empty(empty),
        .next_rd(next_rd),
        .rd_ptr(rd_ptr)
    );
    
endmodule

// FIFO memory submodule
module fifo_memory #(
    parameter WIDTH = 8,
    parameter DEPTH = 4
)(
    input wire clk,
    input wire write_en,
    input wire [1:0] wr_ptr,
    input wire [1:0] rd_ptr,
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    // FIFO storage
    reg [WIDTH-1:0] fifo [0:DEPTH-1];
    
    // Write operation
    always @(posedge clk) begin
        if (write_en)
            fifo[wr_ptr] <= data_in;
    end
    
    // Read operation (output)
    assign data_out = fifo[rd_ptr];
    
endmodule

// Write pointer controller
module write_pointer_ctrl #(
    parameter DEPTH = 4
)(
    input wire clk,
    input wire rst_n,
    input wire push,
    input wire full,
    input wire [1:0] next_wr,
    output reg [1:0] wr_ptr
);
    // Write pointer management
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wr_ptr <= 0;
        else if (push && !full)
            wr_ptr <= next_wr;
    end
    
endmodule

// Read pointer controller
module read_pointer_ctrl #(
    parameter DEPTH = 4
)(
    input wire clk,
    input wire rst_n,
    input wire pop,
    input wire empty,
    input wire [1:0] next_rd,
    output reg [1:0] rd_ptr
);
    // Read pointer management
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rd_ptr <= 0;
        else if (pop && !empty)
            rd_ptr <= next_rd;
    end
    
endmodule