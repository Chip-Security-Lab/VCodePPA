//SystemVerilog
module async_dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire we_a, we_b
);

    // Memory array
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // Address registers
    reg [ADDR_WIDTH-1:0] addr_a_reg, addr_b_reg;
    reg [ADDR_WIDTH-1:0] addr_a_reg2, addr_b_reg2;
    
    // Write data registers
    reg [DATA_WIDTH-1:0] din_a_reg, din_b_reg;
    reg [DATA_WIDTH-1:0] din_a_reg2, din_b_reg2;
    
    // Write enable registers
    reg we_a_reg, we_b_reg;
    reg we_a_reg2, we_b_reg2;
    
    // Read data registers
    reg [DATA_WIDTH-1:0] ram_data_a, ram_data_b;
    
    // Write operation pipeline - Stage 1
    always @(posedge clk) begin
        addr_a_reg <= addr_a;
        addr_b_reg <= addr_b;
        din_a_reg <= din_a;
        din_b_reg <= din_b;
        we_a_reg <= we_a;
        we_b_reg <= we_b;
    end
    
    // Write operation pipeline - Stage 2
    always @(posedge clk) begin
        addr_a_reg2 <= addr_a_reg;
        addr_b_reg2 <= addr_b_reg;
        din_a_reg2 <= din_a_reg;
        din_b_reg2 <= din_b_reg;
        we_a_reg2 <= we_a_reg;
        we_b_reg2 <= we_b_reg;
        
        if (we_a_reg2) begin
            ram[addr_a_reg2] <= din_a_reg2;
        end
        if (we_b_reg2) begin
            ram[addr_b_reg2] <= din_b_reg2;
        end
    end
    
    // Read operation pipeline - Stage 1
    always @(posedge clk) begin
        ram_data_a <= ram[addr_a_reg2];
        ram_data_b <= ram[addr_b_reg2];
    end
    
    // Read operation pipeline - Stage 2
    always @(posedge clk) begin
        dout_a <= ram_data_a;
        dout_b <= ram_data_b;
    end

endmodule