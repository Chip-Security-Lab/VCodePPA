//SystemVerilog
module wave13_half_rect_sine #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst,
    output reg  [DATA_WIDTH-1:0] wave_out
);
    reg [ADDR_WIDTH-1:0] addr;
    reg signed [DATA_WIDTH-1:0] rom [0:(1<<ADDR_WIDTH)-1];
    
    // 流水线寄存器
    reg signed [DATA_WIDTH-1:0] rom_data;
    reg rom_data_negative;
    
    // 使用$signed确保正确处理有符号数
    initial begin
        integer i;
        for(i=0; i<(1<<ADDR_WIDTH); i=i+1) 
            rom[i] = $signed(i - (1<<(DATA_WIDTH-1)));
    end

    always @(posedge clk) begin
        if(rst) begin
            addr <= 0;
            rom_data <= 0;
            rom_data_negative <= 0;
            wave_out <= 0;
        end
        else begin
            // 第一级：地址递增和ROM读取
            addr <= addr + 1;
            rom_data <= rom[addr];
            
            // 第二级：符号检测
            rom_data_negative <= ($signed(rom_data) < 0);
            
            // 第三级：输出逻辑
            wave_out <= rom_data_negative ? 0 : rom_data[DATA_WIDTH-1:0];
        end
    end
endmodule