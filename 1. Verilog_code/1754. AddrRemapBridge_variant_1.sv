//SystemVerilog
module AddrRemapBridge #(
    parameter BASE_ADDR = 32'h4000_0000,
    parameter OFFSET = 32'h1000
)(
    input clk, 
    input rst_n,
    input [31:0] orig_addr,
    input addr_valid,
    output addr_ready,
    output [31:0] remapped_addr
);

    wire addr_ready_internal;
    wire [31:0] adjusted_addr;

    // Address Adjustment Submodule
    AddressAdjuster addr_adjuster (
        .clk(clk),
        .orig_addr(orig_addr),
        .base_addr(BASE_ADDR),
        .offset(OFFSET),
        .addr_valid(addr_valid),
        .addr_ready(addr_ready_internal),
        .remapped_addr(adjusted_addr)
    );

    // Address Ready Logic
    assign addr_ready = ~rst_n ? 0 : addr_ready_internal;

    // Output the remapped address
    assign remapped_addr = adjusted_addr;

endmodule

// Address Adjustment Submodule
module AddressAdjuster (
    input clk,
    input [31:0] orig_addr,
    input [31:0] base_addr,
    input [31:0] offset,
    input addr_valid,
    output reg addr_ready,
    output reg [31:0] remapped_addr
);

    always @(posedge clk) begin
        if (addr_valid && addr_ready) 
            remapped_addr <= orig_addr - base_addr + offset;
    end

    always @(posedge clk or negedge addr_valid) begin
        if (!addr_valid)
            addr_ready <= 0;
        else
            addr_ready <= 1;
    end

endmodule