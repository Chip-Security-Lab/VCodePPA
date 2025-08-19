module rom_cdc #(parameter DW=64)(
    input wr_clk,
    input rd_clk,
    input [3:0] addr,
    output reg [DW-1:0] q
);
    reg [DW-1:0] mem [0:15];
    reg [3:0] sync_addr;
    
    // Initialize memory
    integer i;
    initial begin
        for (i = 0; i < 16; i = i + 1)
            mem[i] = {DW{1'b0}} | i;
    end
    
    // Complete implementation for write logic
    always @(posedge wr_clk) begin
        // No write operations in this simplified example
    end
    
    always @(posedge rd_clk) begin
        sync_addr <= addr;
        q <= mem[sync_addr];
    end
endmodule