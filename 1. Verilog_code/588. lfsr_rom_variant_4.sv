//SystemVerilog
module lfsr_rom (
    input clk,
    input rst,
    output reg [3:0] addr,
    output reg [7:0] data
);
    reg [7:0] rom [0:15];
    reg [3:0] next_addr_stage1;
    reg [3:0] next_addr_stage2;
    reg [3:0] addr_stage1;
    reg [3:0] addr_stage2;
    wire [3:0] addr_pre;
    wire [3:0] next_addr;

    initial begin
        rom[0] = 8'hA0; rom[1] = 8'hB1;
    end

    // Stage 1: Address pre-calculation
    assign addr_pre = {addr[2:0], addr[3] ^ addr[2]};
    assign next_addr = rst ? 4'b1010 : addr_pre;

    // Stage 1 pipeline register
    always @(posedge clk) begin
        next_addr_stage1 <= next_addr;
    end

    // Stage 2 pipeline register
    always @(posedge clk) begin
        next_addr_stage2 <= next_addr_stage1;
        addr_stage1 <= next_addr_stage2;
    end

    // Stage 3 pipeline register
    always @(posedge clk) begin
        addr_stage2 <= addr_stage1;
        addr <= addr_stage2;
        data <= rom[addr_stage2];
    end
endmodule