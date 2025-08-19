//SystemVerilog
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

    reg addr_ready_reg;

    always @(posedge clk) begin
        if (addr_valid) begin
            if (addr_ready_reg) begin
                remapped_addr <= orig_addr - BASE_ADDR + OFFSET;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_ready_reg <= 1'b0;
        end else begin
            addr_ready_reg <= 1'b1;
        end
    end

    assign addr_ready = addr_ready_reg;

endmodule