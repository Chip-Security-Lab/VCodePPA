module multi_clk_rom (
    input clk_a, clk_b,  // 两个时钟域
    input [3:0] addr_a,
    input [3:0] addr_b,
    output reg [7:0] data_a,
    output reg [7:0] data_b
);
    reg [7:0] rom [0:15];

    initial begin
        rom[0] = 8'h11; rom[1] = 8'h22; rom[2] = 8'h33; rom[3] = 8'h44;
    end

    always @(posedge clk_a) begin
        data_a <= rom[addr_a];
    end

    always @(posedge clk_b) begin
        data_b <= rom[addr_b];
    end
endmodule
