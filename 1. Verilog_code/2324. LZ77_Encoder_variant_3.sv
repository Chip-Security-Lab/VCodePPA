//SystemVerilog
module LZ77_Encoder #(WIN_SIZE=4) (
    input clk, en,
    input [7:0] data,
    output reg [15:0] code
);
    // 流水线缓冲区
    reg [7:0] buffer_stage1 [0:WIN_SIZE-1];
    reg [7:0] buffer_stage2 [0:WIN_SIZE-1];
    reg [7:0] data_stage1, data_stage2;
    reg en_stage1, en_stage2;
    
    // 中间结果寄存器
    reg [15:0] match_result_stage1;
    reg [3:0] match_index_stage1;
    reg match_found_stage1;
    
    // 流水线控制
    reg [3:0] ptr_stage1, ptr_stage2;
    
    // 查找表辅助减法器
    reg [15:0] subtraction_lut [0:31];
    
    integer i;
    
    initial begin
        ptr_stage1 = 0;
        ptr_stage2 = 0;
        match_found_stage1 = 0;
        match_index_stage1 = 0;
        en_stage1 = 0;
        en_stage2 = 0;
        data_stage1 = 0;
        data_stage2 = 0;
        
        for(i=0; i<WIN_SIZE; i=i+1) begin
            buffer_stage1[i] = 0;
            buffer_stage2[i] = 0;
        end
            
        // 初始化减法查找表
        for(i=0; i<32; i=i+1) begin
            subtraction_lut[i] = i - 1;
        end
    end
    
    // 第一级流水线：模式匹配
    always @(posedge clk) begin
        // 传递控制信号
        en_stage1 <= en;
        data_stage1 <= data;
        
        // 初始化匹配结果
        match_found_stage1 <= 1'b0;
        match_index_stage1 <= 4'h0;
        
        if (en) begin
            // 模式匹配逻辑
            for(i=0; i<WIN_SIZE; i=i+1) begin
                if(buffer_stage1[i] == data) begin
                    match_found_stage1 <= 1'b1;
                    match_index_stage1 <= i[3:0];
                end
            end
        end
    end
    
    // 第二级流水线：缓冲区更新和输出生成
    always @(posedge clk) begin
        // 传递控制信号到下一级
        en_stage2 <= en_stage1;
        data_stage2 <= data_stage1;
        
        // 默认无匹配码
        code <= 16'h0;
        
        if (en_stage1) begin
            // 生成输出编码
            if (match_found_stage1) begin
                code <= {match_index_stage1[3:0], 8'h0};
            end
            
            // 向前移动缓冲区
            for(i=WIN_SIZE-1; i>0; i=i-1) begin
                buffer_stage2[i] <= buffer_stage1[i-1];
            end
            buffer_stage2[0] <= data_stage1;
        end
    end
    
    // 缓冲区状态更新 - 从第二级回到第一级以进行下一个周期的匹配
    always @(posedge clk) begin
        if (en_stage2) begin
            for(i=0; i<WIN_SIZE; i=i+1) begin
                buffer_stage1[i] <= buffer_stage2[i];
            end
        end
    end
endmodule