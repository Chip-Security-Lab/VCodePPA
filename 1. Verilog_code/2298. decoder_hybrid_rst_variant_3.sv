//SystemVerilog
//IEEE 1364-2005
module decoder_hybrid_rst #(
    parameter SYNC_RST = 1
)(
    input wire clk,          // System clock
    input wire async_rst,    // Asynchronous reset
    input wire sync_rst,     // Synchronous reset
    input wire [3:0] addr,   // Address input
    output reg [15:0] decoded // Decoded output
);

    // Clock buffer tree for reducing fanout
    reg clk_buf1, clk_buf2, clk_buf3;
    
    // Reset buffer tree
    reg async_rst_buf1, async_rst_buf2, async_rst_buf3;
    
    // Internal pipeline registers
    reg [3:0] addr_reg;
    reg [15:0] pre_decoded;
    reg sync_rst_reg;
    
    // Clock buffer distribution - first level
    always @(posedge clk) begin
        clk_buf1 <= ~clk_buf1;
    end
    
    // Clock buffer distribution - second level
    always @(posedge clk_buf1) begin
        clk_buf2 <= ~clk_buf2;
        clk_buf3 <= ~clk_buf3;
    end
    
    // Reset buffer distribution
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            async_rst_buf1 <= 1'b1;
        end else begin
            async_rst_buf1 <= 1'b0;
        end
    end
    
    always @(posedge clk or posedge async_rst_buf1) begin
        if (async_rst_buf1) begin
            async_rst_buf2 <= 1'b1;
            async_rst_buf3 <= 1'b1;
        end else begin
            async_rst_buf2 <= 1'b0;
            async_rst_buf3 <= 1'b0;
        end
    end
    
    // Stage 1: Input registration and reset synchronization
    always @(posedge clk_buf2 or posedge async_rst_buf2) begin
        if (async_rst_buf2) begin
            addr_reg <= 4'b0;
            sync_rst_reg <= 1'b0;
        end else begin
            addr_reg <= addr;
            sync_rst_reg <= sync_rst;
        end
    end
    
    // Stage 2: Address decoding logic
    always @(posedge clk_buf2 or posedge async_rst_buf2) begin
        if (async_rst_buf2) begin
            pre_decoded <= 16'b0;
        end else begin
            pre_decoded <= 1'b1 << addr_reg;
        end
    end
    
    // Stage 3: Final output with reset handling
    always @(posedge clk_buf3 or posedge async_rst_buf3) begin
        if (async_rst_buf3) begin
            decoded <= 16'b0;
        end else if (SYNC_RST && sync_rst_reg) begin
            decoded <= 16'b0;
        end else begin
            decoded <= pre_decoded;
        end
    end

endmodule