//SystemVerilog
module pipeline_rom (
    input clk,
    input [3:0] addr,
    output reg [7:0] data
);
    reg [7:0] rom [0:15];
    reg [7:0] stage1, stage2;
    reg [7:0] rom_buf [0:15];
    reg [7:0] carry_chain [0:7];
    reg [7:0] sum_chain [0:7];

    initial begin
        rom[0] = 8'h12; rom[1] = 8'h34;
        for (integer i = 0; i < 16; i = i + 1) begin
            rom_buf[i] = rom[i];
        end
    end

    always @(posedge clk) begin
        // 带状进位加法器实现
        for (integer i = 0; i < 8; i = i + 1) begin
            if (i == 0) begin
                carry_chain[i] <= rom_buf[addr][i] & stage1[i];
                sum_chain[i] <= rom_buf[addr][i] ^ stage1[i];
            end else begin
                carry_chain[i] <= (rom_buf[addr][i] & stage1[i]) | 
                                ((rom_buf[addr][i] ^ stage1[i]) & carry_chain[i-1]);
                sum_chain[i] <= (rom_buf[addr][i] ^ stage1[i]) ^ carry_chain[i-1];
            end
        end

        stage1 <= rom_buf[addr];
        stage2 <= {sum_chain[7], sum_chain[6], sum_chain[5], sum_chain[4],
                  sum_chain[3], sum_chain[2], sum_chain[1], sum_chain[0]};
        data <= stage2;
    end
endmodule