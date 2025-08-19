//SystemVerilog
module param_rom #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] data
);

    // ROM memory array with one-hot encoding
    reg [DATA_WIDTH-1:0] rom_mem [0:(1<<ADDR_WIDTH)-1];
    
    // Address pipeline registers
    reg [ADDR_WIDTH-1:0] addr_reg;
    reg [ADDR_WIDTH-1:0] addr_reg2;
    
    // Data pipeline registers
    reg [DATA_WIDTH-1:0] data_reg;
    reg [DATA_WIDTH-1:0] data_reg2;

    // ROM initialization
    initial begin
        rom_mem[0] = 8'h12;
        rom_mem[1] = 8'h34;
        rom_mem[2] = 8'h56;
        rom_mem[3] = 8'h78;
    end

    // Two-stage address pipeline
    always @(posedge clk) begin
        addr_reg <= addr;
        addr_reg2 <= addr_reg;
    end

    // Two-stage data pipeline
    always @(posedge clk) begin
        data_reg <= rom_mem[addr_reg];
        data_reg2 <= data_reg;
    end

    // Output stage with registered output
    always @(posedge clk) begin
        data <= data_reg2;
    end

endmodule