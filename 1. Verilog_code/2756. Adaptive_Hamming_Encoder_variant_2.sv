//SystemVerilog
module Adaptive_Hamming_Encoder(
    input clk,
    input reset, // 添加重置信号
    input [7:0] data_in,
    input valid_in,
    output ready_out,
    output reg [11:0] adaptive_code,
    output reg [2:0] parity_bits_used,
    output reg valid_out,
    input ready_in
);
    // 流水线阶段信号定义
    // 阶段1: 输入和计算数据1位的数量
    reg [7:0] data_stage1;
    reg valid_stage1;
    reg [2:0] ones_count_stage1;
    
    // 阶段2: 计算校验位并准备编码
    reg [7:0] data_stage2;
    reg [2:0] ones_count_stage2;
    reg valid_stage2;
    reg [11:0] code_stage2;
    reg [2:0] parity_used_stage2;
    
    // 流水线控制信号
    wire stage1_ready;
    wire stage2_ready;
    
    // 数据流控制
    assign ready_out = stage1_ready;
    assign stage1_ready = !valid_stage1 || stage2_ready;
    assign stage2_ready = !valid_stage2 || ready_in;
    
    // 替换$countones函数
    function [2:0] count_ones;
        input [7:0] data;
        reg [2:0] count;
        integer i;
        begin
            count = 0;
            for(i=0; i<8; i=i+1)
                if(data[i]) count = count + 1;
            count_ones = count;
        end
    endfunction
    
    // 阶段1: 输入注册和1位计数
    always @(posedge clk) begin
        if (reset) begin
            data_stage1 <= 8'b0;
            valid_stage1 <= 1'b0;
            ones_count_stage1 <= 3'b0;
        end
        else if (stage1_ready) begin
            if (valid_in) begin
                data_stage1 <= data_in;
                ones_count_stage1 <= count_ones(data_in);
                valid_stage1 <= 1'b1;
            end
            else if (stage2_ready) begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // 阶段2: 编码生成
    always @(posedge clk) begin
        if (reset) begin
            data_stage2 <= 8'b0;
            ones_count_stage2 <= 3'b0;
            valid_stage2 <= 1'b0;
            code_stage2 <= 12'b0;
            parity_used_stage2 <= 3'b0;
        end
        else if (stage2_ready) begin
            if (valid_stage1) begin
                data_stage2 <= data_stage1;
                ones_count_stage2 <= ones_count_stage1;
                valid_stage2 <= 1'b1;
                
                // 根据1位数量选择编码方式
                case(ones_count_stage1)
                    3'd0, 3'd1, 3'd2: begin // 低密度使用(8,4)码
                        code_stage2[10:8] <= data_stage1[7:4];
                        code_stage2[7] <= ^{data_stage1[7:4], data_stage1[3:0]};
                        code_stage2[6:0] <= {data_stage1[3:0], 3'b0};
                        parity_used_stage2 <= 3'd4;
                    end
                    default: begin // 高密度使用(12,8)码
                        code_stage2[11] <= ^data_stage1;
                        code_stage2[10:3] <= data_stage1;
                        code_stage2[2] <= ^{data_stage1[7:5], data_stage1[3:1]};
                        code_stage2[1] <= ^{data_stage1[4:2], data_stage1[0]};
                        code_stage2[0] <= ^{data_stage1[7:4], data_stage1[3:0]};
                        parity_used_stage2 <= 3'd3;
                    end
                endcase
            end
            else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // 输出寄存器阶段
    always @(posedge clk) begin
        if (reset) begin
            adaptive_code <= 12'b0;
            parity_bits_used <= 3'b0;
            valid_out <= 1'b0;
        end
        else if (ready_in) begin
            if (valid_stage2) begin
                adaptive_code <= code_stage2;
                parity_bits_used <= parity_used_stage2;
                valid_out <= 1'b1;
            end
            else begin
                valid_out <= 1'b0;
            end
        end
    end
    
endmodule