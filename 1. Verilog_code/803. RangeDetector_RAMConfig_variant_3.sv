//SystemVerilog
module RangeDetector_RAMConfig #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input clk,
    input wr_en,
    input [ADDR_WIDTH-1:0] wr_addr,
    input [DATA_WIDTH-1:0] wr_data,
    input [DATA_WIDTH-1:0] data_in,
    output out_flag
);
    // 存储器定义
    reg [DATA_WIDTH-1:0] threshold_ram [2**ADDR_WIDTH-1:0];
    
    // 添加缓冲寄存器，为threshold_ram[0]和threshold_ram[1]增加寄存器缓冲
    reg [DATA_WIDTH-1:0] low_buf1, low_buf2;
    reg [DATA_WIDTH-1:0] high_buf1, high_buf2;
    
    // 写入逻辑
    always @(posedge clk) begin
        if(wr_en) threshold_ram[wr_addr] <= wr_data;
    end
    
    // 读取缓冲，分阶段缓存以减少扇出
    always @(posedge clk) begin
        // 第一级缓冲
        low_buf1 <= threshold_ram[0];
        high_buf1 <= threshold_ram[1];
        
        // 第二级缓冲，进一步分散负载
        low_buf2 <= low_buf1;
        high_buf2 <= high_buf1;
    end
    
    // 使用缓冲后的阈值信号
    wire [DATA_WIDTH-1:0] low = low_buf2;
    wire [DATA_WIDTH-1:0] high = high_buf2;
    
    // 补码加法实现范围检测
    wire low_cond, high_cond;
    
    // 引入数据缓冲寄存器
    reg [DATA_WIDTH-1:0] data_in_buf;
    always @(posedge clk) begin
        data_in_buf <= data_in;
    end
    
    // 计算子模块以减少关键路径长度
    RangeCalc #(
        .DATA_WIDTH(DATA_WIDTH)
    ) range_calc_inst (
        .clk(clk),
        .data_in(data_in_buf),
        .low(low),
        .high(high),
        .low_cond(low_cond),
        .high_cond(high_cond)
    );
    
    // 添加输出寄存器，进一步减少扇出负载
    reg out_flag_reg;
    always @(posedge clk) begin
        out_flag_reg <= low_cond && high_cond;
    end
    
    assign out_flag = out_flag_reg;

endmodule

// 分离计算逻辑到子模块，减少主模块关键路径
module RangeCalc #(
    parameter DATA_WIDTH = 8
)(
    input clk,
    input [DATA_WIDTH-1:0] data_in,
    input [DATA_WIDTH-1:0] low,
    input [DATA_WIDTH-1:0] high,
    output reg low_cond,
    output reg high_cond
);
    wire [DATA_WIDTH:0] data_low_sum, high_data_sum;
    reg [DATA_WIDTH:0] data_low_sum_reg, high_data_sum_reg;
    
    // 计算data_in >= low的条件，使用data_in + (~low + 1) >= 0的判断
    // 当data_in >= low时，结果的最高位(符号位)为0
    assign data_low_sum = {1'b0, data_in} + {1'b0, ~low} + 1'b1;
    
    // 计算data_in <= high的条件，使用high + (~data_in + 1) >= 0的判断
    // 当data_in <= high时，结果的最高位(符号位)为0
    assign high_data_sum = {1'b0, high} + {1'b0, ~data_in} + 1'b1;
    
    // 添加计算结果缓冲
    always @(posedge clk) begin
        data_low_sum_reg <= data_low_sum;
        high_data_sum_reg <= high_data_sum;
        
        // 寄存比较结果
        low_cond <= ~data_low_sum_reg[DATA_WIDTH];
        high_cond <= ~high_data_sum_reg[DATA_WIDTH];
    end
    
endmodule