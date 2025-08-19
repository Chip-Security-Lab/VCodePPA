//SystemVerilog
module multi_clk_rom (
    input clk_a, clk_b,
    input [3:0] addr_a,
    input [3:0] addr_b,
    output reg [7:0] data_a,
    output reg [7:0] data_b
);
    reg [7:0] rom [0:15];
    reg [3:0] addr_a_stage1, addr_b_stage1;
    reg [7:0] data_a_stage1, data_b_stage1;
    reg [7:0] data_a_stage2, data_b_stage2;

    initial begin
        rom[0] = 8'h11; rom[1] = 8'h22; rom[2] = 8'h33; rom[3] = 8'h44;
    end

    // Stage 1: Address registration
    always @(posedge clk_a) begin
        addr_a_stage1 <= addr_a;
    end

    always @(posedge clk_b) begin
        addr_b_stage1 <= addr_b;
    end

    // Stage 2: ROM access
    always @(posedge clk_a) begin
        data_a_stage1 <= rom[addr_a_stage1];
    end

    always @(posedge clk_b) begin
        data_b_stage1 <= rom[addr_b_stage1];
    end

    // Stage 3: Output registration
    always @(posedge clk_a) begin
        data_a_stage2 <= data_a_stage1;
        data_a <= data_a_stage2;
    end

    always @(posedge clk_b) begin
        data_b_stage2 <= data_b_stage1;
        data_b <= data_b_stage2;
    end
endmodule