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
    output reg out_flag
);
    // 使用双端口RAM以支持并行读取low和high值
    reg [DATA_WIDTH-1:0] threshold_ram [2**ADDR_WIDTH-1:0];
    reg [DATA_WIDTH-1:0] low_reg, high_reg;
    
    // 对输入数据进行流水线处理
    reg [DATA_WIDTH-1:0] data_in_pipe;
    
    // 比较结果的中间流水线寄存器
    reg low_compare_result, high_compare_result;
    
    // 数据输入流水线
    always @(posedge clk) begin
        data_in_pipe <= data_in;
    end
    
    // 寄存low和high值以提高时序性能
    always @(posedge clk) begin
        if(wr_en) begin
            threshold_ram[wr_addr] <= wr_data;
            // 优化RAM更新逻辑，直接更新寄存器以减少读延迟
            if(wr_addr == 0) low_reg <= wr_data;
            if(wr_addr == 1) high_reg <= wr_data;
        end else begin
            // 当不写入时，更新low和high寄存器
            low_reg <= threshold_ram[0];
            high_reg <= threshold_ram[1];
        end
    end
    
    // 拆分比较操作为两步，减少关键路径长度
    always @(posedge clk) begin
        // 第一阶段：单独计算大于等于low和小于等于high的比较结果
        low_compare_result <= (data_in_pipe >= low_reg);
        high_compare_result <= (data_in_pipe <= high_reg);
    end
    
    // 第二阶段：合并比较结果
    always @(posedge clk) begin
        out_flag <= low_compare_result && high_compare_result;
    end
endmodule