//SystemVerilog
// Top-level module for asynchronous FIFO write pointer synchronization
module async_fifo_sync #(parameter ADDR_W = 4) (
    input wire wr_clk,
    input wire rd_clk,
    input wire rst,
    output wire [ADDR_W:0] synced_wptr
);

    wire [ADDR_W:0] wr_ptr;
    wire [ADDR_W:0] gray_wptr;
    wire [ADDR_W:0] synced_gray_wptr;

    // Write pointer logic submodule
    wr_ptr_gen #(
        .ADDR_W(ADDR_W)
    ) u_wr_ptr_gen (
        .clk(wr_clk),
        .rst(rst),
        .wr_ptr(wr_ptr)
    );

    // Binary to Gray code converter submodule
    bin2gray #(
        .WIDTH(ADDR_W+1)
    ) u_bin2gray (
        .bin_in(wr_ptr),
        .gray_out(gray_wptr)
    );

    // Synchronizer submodule for Gray-coded write pointer
    gray_sync #(
        .WIDTH(ADDR_W+1)
    ) u_gray_sync (
        .clk(rd_clk),
        .rst(rst),
        .gray_in(gray_wptr),
        .gray_out(synced_gray_wptr)
    );

    // Output assignment
    assign synced_wptr = synced_gray_wptr;

endmodule

//------------------------------------------------------------------------------
// Write Pointer Generator
// Generates the binary write pointer for FIFO
//------------------------------------------------------------------------------
module wr_ptr_gen #(parameter ADDR_W = 4) (
    input wire clk,
    input wire rst,
    output reg [ADDR_W:0] wr_ptr
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            wr_ptr <= { (ADDR_W+1){1'b0} };
        else
            wr_ptr <= wr_ptr + 1'b1;
    end
endmodule

//------------------------------------------------------------------------------
// Binary to Gray Code Converter
// Converts binary input to Gray code
//------------------------------------------------------------------------------
module bin2gray #(parameter WIDTH = 5) (
    input wire [WIDTH-1:0] bin_in,
    output wire [WIDTH-1:0] gray_out
);
    assign gray_out = (bin_in >> 1) ^ bin_in;
endmodule

//------------------------------------------------------------------------------
// Gray Code Synchronizer
// Double-flop synchronizer for metastability protection
//------------------------------------------------------------------------------
module gray_sync #(parameter WIDTH = 5) (
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] gray_in,
    output reg [WIDTH-1:0] gray_out
);
    reg [WIDTH-1:0] sync_ff1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_ff1  <= {WIDTH{1'b0}};
            gray_out  <= {WIDTH{1'b0}};
        end else begin
            sync_ff1  <= gray_in;
            gray_out  <= sync_ff1;
        end
    end
endmodule