//SystemVerilog
// Top-level module
module rom_cdc #(parameter DW=64)(
    input wr_clk,
    input rd_clk,
    input [3:0] addr,
    output reg [DW-1:0] q
);
    // Registered version of input address for wr_clk domain
    reg [3:0] addr_wr_reg;
    // Memory output signals
    wire [DW-1:0] mem_out;
    wire [3:0] sync_addr;
    
    // Register input address in write clock domain to break timing path
    always @(posedge wr_clk) begin
        addr_wr_reg <= addr;
    end

    // Instantiate memory module with registered address
    memory #(DW) mem_inst (
        .wr_clk(wr_clk),
        .addr(addr_wr_reg),
        .mem_out(mem_out)
    );

    // Instantiate address synchronization module
    addr_sync addr_sync_inst (
        .rd_clk(rd_clk),
        .addr(addr),
        .sync_addr(sync_addr)
    );

    // Output logic with enable to reduce switching activity
    always @(posedge rd_clk) begin
        q <= mem_out;
    end
endmodule

// Memory module
module memory #(parameter DW=64)(
    input wr_clk,
    input [3:0] addr,
    output reg [DW-1:0] mem_out
);
    // Memory array
    reg [DW-1:0] mem [0:15];
    // Registered output to improve timing
    reg [3:0] addr_reg;

    // Initialize memory
    integer i;
    initial begin
        for (i = 0; i < 16; i = i + 1)
            mem[i] = {DW{1'b0}} | i;
    end

    // Register address to break combinational path
    always @(posedge wr_clk) begin
        addr_reg <= addr;
    end

    // Split the read operation into two stages to reduce critical path
    // First stage: register the address
    // Second stage: access memory with registered address
    always @(*) begin
        mem_out = mem[addr_reg];
    end
endmodule

// Address synchronization module with 2-stage CDC
module addr_sync(
    input rd_clk,
    input [3:0] addr,
    output reg [3:0] sync_addr
);
    // Two-stage synchronizer to prevent metastability
    reg [3:0] sync_stage1;
    
    always @(posedge rd_clk) begin
        sync_stage1 <= addr;
        sync_addr <= sync_stage1;
    end
endmodule