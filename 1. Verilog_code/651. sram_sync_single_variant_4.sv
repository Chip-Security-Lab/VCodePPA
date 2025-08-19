//SystemVerilog
module sram_sync_single #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter DEPTH = 16
)(
    input clk,
    input rst_n,
    input cs,
    input we,
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);

reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
reg [ADDR_WIDTH-1:0] addr_reg;
reg [DATA_WIDTH-1:0] din_reg;
reg we_reg;
reg cs_reg;
reg [DATA_WIDTH-1:0] mem_data_reg;
integer i;

// Single stage pipeline with optimized control logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_reg <= 0;
        din_reg <= 0;
        we_reg <= 0;
        cs_reg <= 0;
        mem_data_reg <= 0;
        dout <= 0;
        for (i=0; i<DEPTH; i=i+1) mem[i] <= 0;
    end else begin
        // Register inputs
        addr_reg <= addr;
        din_reg <= din;
        we_reg <= we;
        cs_reg <= cs;
        
        // Memory access
        if (cs_reg) begin
            if (we_reg) begin
                mem[addr_reg] <= din_reg;
            end
            mem_data_reg <= mem[addr_reg];
            dout <= mem_data_reg;
        end
    end
end

endmodule