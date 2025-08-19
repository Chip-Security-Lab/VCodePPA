module SPI_Configurable #(
    parameter REG_FILE_SIZE = 8
)(
    input clk, rst_n,
    // SPI接口
    output sclk, mosi, cs_n,
    input miso,
    // 配置接口
    input [7:0] config_addr,
    input [15:0] config_data,
    input config_wr
);

reg [15:0] config_reg [0:REG_FILE_SIZE-1];
reg [7:0] clk_div;
reg [3:0] data_width;
reg [1:0] cpol_cpha;
integer i; // 用于for循环

// 配置寄存器写逻辑 - 使用标准Verilog循环
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0; i<REG_FILE_SIZE; i=i+1)
            config_reg[i] <= 0;
    end else if(config_wr) begin
        config_reg[config_addr] <= config_data;
    end
end

// 寄存器和参数映射
always @(*) begin
    clk_div = config_reg[0][7:0];
    data_width = config_reg[1][3:0];
    cpol_cpha = config_reg[2][1:0];
end

// 动态时钟分频
reg [7:0] clk_counter;
reg sclk_int;
always @(posedge clk) begin
    if(clk_counter >= clk_div) begin
        sclk_int <= ~sclk_int;
        clk_counter <= 0;
    end else begin
        clk_counter <= clk_counter + 1;
    end
end

// CPOL控制
assign sclk = cpol_cpha[1] ? ~sclk_int : sclk_int;
// 添加默认分配
assign mosi = 1'b0; // 需要实际实现
assign cs_n = 1'b1; // 默认不选中任何设备
endmodule