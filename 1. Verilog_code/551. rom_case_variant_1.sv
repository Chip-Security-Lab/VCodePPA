//SystemVerilog
module rom_case #(parameter DW=8, AW=4)(
    input clk,
    input [AW-1:0] addr,
    output reg [DW-1:0] data
);
    // ROM查找表
    reg [DW-1:0] rom_lut [0:(1<<AW)-1];
    reg [DW-1:0] rom_lut_buffer; // 缓冲寄存器

    // 初始化查找表
    initial begin
        rom_lut[4'h0] = 8'h00;
        rom_lut[4'h1] = 8'h11;
        rom_lut[4'h2] = 8'h22;
        rom_lut[4'h3] = 8'h33;
        rom_lut[4'h4] = 8'h44;
        rom_lut[4'h5] = 8'h55;
        rom_lut[4'h6] = 8'h66;
        rom_lut[4'h7] = 8'h77;
        rom_lut[4'h8] = 8'h88;
        rom_lut[4'h9] = 8'h99;
        rom_lut[4'hA] = 8'hAA;
        rom_lut[4'hB] = 8'hBB;
        rom_lut[4'hC] = 8'hCC;
        rom_lut[4'hD] = 8'hDD;
        rom_lut[4'hE] = 8'hEE;
        rom_lut[4'hF] = 8'hFF;
    end
    
    // 同步读取数据
    always @(posedge clk) begin
        rom_lut_buffer <= rom_lut[addr]; // 先将数据存入缓冲寄存器
        data <= rom_lut_buffer; // 再将缓冲寄存器的值赋给输出
    end
endmodule