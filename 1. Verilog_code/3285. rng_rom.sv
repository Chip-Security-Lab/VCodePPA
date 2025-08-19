module rng_rom_5(
    input            clk,
    input            rst,
    input            en,
    output reg [7:0] rand_out
);
    reg [4:0] addr;
    reg [7:0] mem[0:31];
    initial begin
        mem[0] = 8'hAF; mem[1] = 8'h3C; /* ... 可自行添加初始化 ... */ 
        mem[2] = 8'h77; mem[3] = 8'h12; // 示例，省略部分初始化
    end
    always @(posedge clk) begin
        if(rst)     addr <= 0;
        else if(en) addr <= addr + 1;
        rand_out <= mem[addr];
    end
endmodule
