module AddrRemapBridge #(
    parameter BASE_ADDR = 32'h4000_0000,
    parameter OFFSET = 32'h1000
)(
    input clk, rst_n,
    input [31:0] orig_addr,
    output reg [31:0] remapped_addr,
    input addr_valid,
    output addr_ready
);
    always @(posedge clk) begin
        if (addr_valid && addr_ready) 
            remapped_addr <= orig_addr - BASE_ADDR + OFFSET;
    end
    assign addr_ready = ~rst_n ? 0 : 1;
endmodule