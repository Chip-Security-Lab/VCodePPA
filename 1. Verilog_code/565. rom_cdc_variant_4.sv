//SystemVerilog
module rom_cdc #(parameter DW=64)(
    input wr_clk,
    input rd_clk,
    input [3:0] addr,
    output reg [DW-1:0] q
);
    reg [DW-1:0] mem [0:15];
    
    // Two-stage synchronizer for CDC
    reg [3:0] sync_addr_stage1;
    reg [3:0] sync_addr_stage2;
    
    // Initialize memory
    integer i;
    initial begin
        for (i = 0; i < 16; i = i + 1)
            mem[i] = {DW{1'b0}} | i;
    end
    
    // No write operations in this simplified example
    
    // CDC synchronization with two-stage synchronizer
    always @(posedge rd_clk) begin
        sync_addr_stage1 <= addr;
        sync_addr_stage2 <= sync_addr_stage1;
    end
    
    // Read logic separated from synchronization logic
    always @(posedge rd_clk) begin
        q <= mem[sync_addr_stage2];
    end
endmodule