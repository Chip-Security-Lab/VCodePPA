//SystemVerilog
module LZ77_Encoder #(WIN_SIZE=4) (
    input clk, en, rst,
    input [7:0] data_in,
    input data_valid,
    output reg data_ready,
    output reg [15:0] code_out,
    output reg code_valid
);
    // 缓冲区寄存器
    reg [7:0] buffer [0:WIN_SIZE-1];
    
    // 扩展流水线阶段寄存器
    reg [7:0] data_stage1;
    reg data_valid_stage1;
    
    reg [7:0] data_stage2;
    reg data_valid_stage2;
    reg [WIN_SIZE-1:0] match_candidates_stage2;
    
    reg [7:0] data_stage3;
    reg data_valid_stage3;
    reg [3:0] match_index_stage3;
    reg match_found_stage3;
    
    reg [7:0] data_stage4;
    reg [15:0] match_result_stage4;
    reg data_valid_stage4;
    
    integer i;
    
    // 复位逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < WIN_SIZE; i = i + 1) begin
                buffer[i] <= 8'h0;
            end
            data_stage1 <= 8'h0;
            data_valid_stage1 <= 1'b0;
            
            data_stage2 <= 8'h0;
            data_valid_stage2 <= 1'b0;
            match_candidates_stage2 <= {WIN_SIZE{1'b0}};
            
            data_stage3 <= 8'h0;
            data_valid_stage3 <= 1'b0;
            match_index_stage3 <= 4'h0;
            match_found_stage3 <= 1'b0;
            
            data_stage4 <= 8'h0;
            match_result_stage4 <= 16'h0;
            data_valid_stage4 <= 1'b0;
            
            code_out <= 16'h0;
            code_valid <= 1'b0;
            data_ready <= 1'b1;
        end
    end
    
    // 阶段1: 输入接收
    always @(posedge clk) begin
        if (!rst) begin
            if (en && data_valid && data_ready) begin
                // 将输入数据传递到第一级流水线
                data_stage1 <= data_in;
                data_valid_stage1 <= 1'b1;
                data_ready <= 1'b0;  // 暂时不接收新数据
            end else if (!data_valid_stage1) begin
                data_ready <= 1'b1;  // 准备接收新数据
            end
        end
    end
    
    // 阶段2: 匹配候选项识别
    always @(posedge clk) begin
        if (!rst) begin
            if (data_valid_stage1) begin
                // 为每个缓冲区位置生成匹配候选标志
                for (i = 0; i < WIN_SIZE; i = i + 1) begin
                    match_candidates_stage2[i] <= (buffer[i] == data_stage1) ? 1'b1 : 1'b0;
                end
                
                data_stage2 <= data_stage1;
                data_valid_stage2 <= 1'b1;
                data_valid_stage1 <= 1'b0;
            end else begin
                data_valid_stage2 <= 1'b0;
            end
        end
    end
    
    // 阶段3: 匹配选择和编码
    always @(posedge clk) begin
        if (!rst) begin
            if (data_valid_stage2) begin
                match_found_stage3 <= 1'b0;
                match_index_stage3 <= 4'h0;
                
                // 寻找第一个匹配的索引
                for (i = 0; i < WIN_SIZE; i = i + 1) begin
                    if (match_candidates_stage2[i] && !match_found_stage3) begin
                        match_found_stage3 <= 1'b1;
                        match_index_stage3 <= i[3:0];
                    end
                end
                
                data_stage3 <= data_stage2;
                data_valid_stage3 <= 1'b1;
                data_valid_stage2 <= 1'b0;
            end else begin
                data_valid_stage3 <= 1'b0;
            end
        end
    end
    
    // 阶段4: 结果格式化
    always @(posedge clk) begin
        if (!rst) begin
            if (data_valid_stage3) begin
                if (match_found_stage3) begin
                    match_result_stage4 <= {match_index_stage3, 8'h0};
                end else begin
                    match_result_stage4 <= 16'h0;
                end
                
                data_stage4 <= data_stage3;
                data_valid_stage4 <= 1'b1;
                data_valid_stage3 <= 1'b0;
            end else begin
                data_valid_stage4 <= 1'b0;
            end
        end
    end
    
    // 阶段5: 输出生成和缓冲区更新
    always @(posedge clk) begin
        if (!rst) begin
            if (data_valid_stage4) begin
                // 输出编码结果
                code_out <= match_result_stage4;
                code_valid <= 1'b1;
                
                // 更新缓冲区
                for (i = WIN_SIZE-1; i > 0; i = i - 1) begin
                    buffer[i] <= buffer[i-1];
                end
                buffer[0] <= data_stage4;
                
                data_valid_stage4 <= 1'b0;
                data_ready <= 1'b1;  // 准备接收下一个数据
            end else begin
                code_valid <= 1'b0;
            end
        end
    end
endmodule