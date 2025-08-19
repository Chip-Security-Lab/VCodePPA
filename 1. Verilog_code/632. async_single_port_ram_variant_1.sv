//SystemVerilog
module async_single_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    input wire we
);

    reg [ADDR_WIDTH-1:0] addr_reg;
    reg [DATA_WIDTH-1:0] din_reg;
    reg we_reg;
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    always @(posedge clk) begin
        // Pipeline stage 1: Register inputs
        addr_reg <= addr;
        din_reg <= din;
        we_reg <= we;
        
        // Pipeline stage 2: Memory access
        if (we_reg) begin
            ram[addr_reg] <= din_reg;
        end
        dout <= ram[addr_reg];
    end

endmodule