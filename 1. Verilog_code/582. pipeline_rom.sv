module pipeline_rom (
    input clk,
    input [3:0] addr,
    output reg [7:0] data
);
    reg [7:0] rom [0:15];
    reg [7:0] stage1, stage2; // 两级流水线

    initial begin
        rom[0] = 8'h12; rom[1] = 8'h34;
    end

    always @(posedge clk) begin
        stage1 <= rom[addr];  // 第一级
        stage2 <= stage1;     // 第二级
        data <= stage2;
    end
endmodule
