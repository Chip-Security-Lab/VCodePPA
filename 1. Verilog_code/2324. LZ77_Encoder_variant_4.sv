//SystemVerilog
// Top-level module
module LZ77_Encoder #(
    parameter WIN_SIZE = 4
) (
    input wire clk,
    input wire rst_n,  // 添加复位信号
    input wire valid_in,
    input wire [7:0] data_in,
    output wire valid_out,
    output wire [15:0] code_out,
    output wire ready_in  // 反压信号
);

    // 流水线阶段控制信号
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 数据流水线寄存器
    reg [7:0] data_stage1, data_stage2;
    
    // 流水线寄存器 - 缓冲区数据
    reg [7:0] buffer_data_stage1 [0:WIN_SIZE-1];
    reg [7:0] buffer_data_stage2 [0:WIN_SIZE-1];
    
    // 匹配结果流水线寄存器
    reg [3:0] match_index_stage2, match_index_stage3;
    reg match_found_stage2, match_found_stage3;
    
    // 模块间连接信号
    wire [7:0] buffer_data [0:WIN_SIZE-1];
    wire [3:0] match_index;
    wire match_found;
    
    // 所有流水线级都准备好接收数据
    assign ready_in = 1'b1;  // 简化版本，后续可扩展为背压机制
    
    // Stage 1: 缓冲区更新
    SlidingWindowBuffer #(
        .WIN_SIZE(WIN_SIZE)
    ) buffer_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_in && ready_in),
        .data_in(data_in),
        .buffer_out(buffer_data)
    );
    
    // 第一级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
            data_stage1 <= 8'h0;
            for (integer i = 0; i < WIN_SIZE; i = i + 1) begin
                buffer_data_stage1[i] <= 8'h0;
            end
        end else if (ready_in) begin
            valid_stage1 <= valid_in;
            data_stage1 <= data_in;
            for (integer i = 0; i < WIN_SIZE; i = i + 1) begin
                buffer_data_stage1[i] <= buffer_data[i];
            end
        end
    end
    
    // Stage 2: 模式匹配
    PatternMatcher #(
        .WIN_SIZE(WIN_SIZE)
    ) matcher_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_stage1),
        .data(data_stage1),
        .buffer(buffer_data_stage1),
        .match_index(match_index),
        .match_found(match_found)
    );
    
    // 第二级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
            data_stage2 <= 8'h0;
            match_index_stage2 <= 4'h0;
            match_found_stage2 <= 1'b0;
            for (integer i = 0; i < WIN_SIZE; i = i + 1) begin
                buffer_data_stage2[i] <= 8'h0;
            end
        end else begin
            valid_stage2 <= valid_stage1;
            data_stage2 <= data_stage1;
            match_index_stage2 <= match_index;
            match_found_stage2 <= match_found;
            for (integer i = 0; i < WIN_SIZE; i = i + 1) begin
                buffer_data_stage2[i] <= buffer_data_stage1[i];
            end
        end
    end
    
    // Stage 3: 代码生成
    CodeGenerator code_gen_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_stage2),
        .match_index(match_index_stage2),
        .match_found(match_found_stage2),
        .data(data_stage2),
        .code(code_out)
    );
    
    // 第三级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage3 <= 1'b0;
            match_index_stage3 <= 4'h0;
            match_found_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
            match_index_stage3 <= match_index_stage2;
            match_found_stage3 <= match_found_stage2;
        end
    end
    
    // 输出有效信号
    assign valid_out = valid_stage3;

endmodule

// Module for managing the sliding window buffer - 流水线优化版本
module SlidingWindowBuffer #(
    parameter WIN_SIZE = 4
) (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [7:0] data_in,
    output reg [7:0] buffer_out [0:WIN_SIZE-1]
);

    // 更新缓冲区
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for(integer i = 0; i < WIN_SIZE; i = i + 1)
                buffer_out[i] <= 8'h0;
        end else if (en) begin
            // 移位缓冲区内容
            for(integer i = WIN_SIZE-1; i > 0; i = i - 1)
                buffer_out[i] <= buffer_out[i-1];
            
            // 在位置0插入新数据
            buffer_out[0] <= data_in;
        end
    end

endmodule

// Module for matching the current data with buffer content - 流水线优化版本
module PatternMatcher #(
    parameter WIN_SIZE = 4
) (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [7:0] data,
    input wire [7:0] buffer [0:WIN_SIZE-1],
    output reg [3:0] match_index,
    output reg match_found
);
    
    // 内部比较结果寄存器
    reg [WIN_SIZE-1:0] match_result;
    
    // 第一阶段：比较和优先级编码
    always @(*) begin
        match_result = {WIN_SIZE{1'b0}};
        
        // 并行比较所有缓冲区元素
        for(integer i = 0; i < WIN_SIZE; i = i + 1) begin
            match_result[i] = (buffer[i] == data);
        end
    end
    
    // 第二阶段：优先级编码并输出结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_found <= 1'b0;
            match_index <= 4'h0;
        end else if (en) begin
            match_found <= |match_result;  // 如果任何一个位置匹配，则置为1
            
            // 优先级编码器 - 找到最低位的匹配
            match_index <= 4'h0;
            for(integer i = 0; i < WIN_SIZE; i = i + 1) begin
                if(match_result[i]) begin
                    match_index <= i[3:0];
                end
            end
        end else begin
            match_found <= 1'b0;
            match_index <= 4'h0;
        end
    end

endmodule

// Module for generating the output code - 流水线优化版本
module CodeGenerator (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [3:0] match_index,
    input wire match_found,
    input wire [7:0] data,
    output reg [15:0] code
);

    // 内部流水线寄存器
    reg [7:0] data_pipe;
    reg [3:0] match_index_pipe;
    reg match_found_pipe;
    
    // 第一级：捕获输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_pipe <= 8'h0;
            match_index_pipe <= 4'h0;
            match_found_pipe <= 1'b0;
        end else if (en) begin
            data_pipe <= data;
            match_index_pipe <= match_index;
            match_found_pipe <= match_found;
        end
    end

    // 第二级：生成代码
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code <= 16'h0;
        end else begin
            if (match_found_pipe) 
                code <= {match_index_pipe[3:0], data_pipe};
            else
                code <= {8'h00, data_pipe};  // 不匹配时，包含原始数据
        end
    end

endmodule