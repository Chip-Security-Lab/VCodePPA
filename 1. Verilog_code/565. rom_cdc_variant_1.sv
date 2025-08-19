//SystemVerilog
module rom_cdc #(parameter DW=64)(
    input wr_clk,
    input rd_clk,
    input [3:0] addr,
    output reg [DW-1:0] q
);
    reg [DW-1:0] mem [0:15];
    
    // Clock domain crossing registers for address (2-stage synchronizer)
    reg [3:0] addr_sync1, addr_sync2;
    
    // Pipeline registers for memory read operation
    reg [3:0] addr_stage1;
    reg [DW-1:0] data_stage1;
    reg valid_stage1, valid_stage2;
    
    // Initialize memory
    integer i;
    initial begin
        for (i = 0; i < 16; i = i + 1)
            mem[i] = {DW{1'b0}} | i;
    end
    
    // Address synchronization across clock domains (wr_clk to rd_clk)
    always @(posedge rd_clk) begin
        addr_sync1 <= addr;
        addr_sync2 <= addr_sync1;
    end
    
    // Pipeline Stage 1: Address decoding and memory read
    always @(posedge rd_clk) begin
        addr_stage1 <= addr_sync2;
        data_stage1 <= mem[addr_sync2];
        valid_stage1 <= 1'b1;  // Always valid in this simplified example
    end
    
    // Pipeline Stage 2: Output register
    always @(posedge rd_clk) begin
        q <= data_stage1;
        valid_stage2 <= valid_stage1;
    end
endmodule