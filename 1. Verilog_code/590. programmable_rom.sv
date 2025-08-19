module programmable_rom (
    input clk,
    input prog_en,  // 编程模式
    input [3:0] addr,
    input [7:0] din,
    output reg [7:0] data
);
    reg [7:0] rom [0:15];
    reg programmed [0:15]; // 记录是否已写入

    always @(posedge clk) begin
        if (prog_en && !programmed[addr]) begin
            rom[addr] <= din;
            programmed[addr] <= 1;
        end
        data <= rom[addr];
    end
endmodule
