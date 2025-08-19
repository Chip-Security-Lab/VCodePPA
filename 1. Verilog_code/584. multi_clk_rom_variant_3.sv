//SystemVerilog
module multi_clk_rom (
    input clk_a, clk_b,
    input [3:0] addr_a,
    input [3:0] addr_b,
    output reg [7:0] data_a,
    output reg [7:0] data_b
);

    reg [7:0] rom [0:15];
    reg [3:0] addr_a_reg;
    reg [3:0] addr_b_reg;
    reg [7:0] data_a_reg;
    reg [7:0] data_b_reg;

    initial begin
        rom[0] = 8'h11; rom[1] = 8'h22; rom[2] = 8'h33; rom[3] = 8'h44;
    end

    // First pipeline stage - address register
    always @(posedge clk_a) begin
        addr_a_reg <= addr_a;
    end

    always @(posedge clk_b) begin
        addr_b_reg <= addr_b;
    end

    // Second pipeline stage - ROM read
    always @(posedge clk_a) begin
        data_a_reg <= rom[addr_a_reg];
    end

    always @(posedge clk_b) begin
        data_b_reg <= rom[addr_b_reg];
    end

    // Final pipeline stage - output register
    always @(posedge clk_a) begin
        data_a <= data_a_reg;
    end

    always @(posedge clk_b) begin
        data_b <= data_b_reg;
    end

endmodule