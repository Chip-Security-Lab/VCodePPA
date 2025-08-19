//SystemVerilog
module crc_fsm (
    input clk, start, rst,
    input [7:0] data,
    output reg [15:0] crc,
    output done
);
    // 状态定义
    parameter IDLE = 0, CALC1 = 1, CALC2 = 2, FINISH = 3;
    reg [1:0] state;
    
    // 流水线阶段寄存器
    reg [7:0] data_stage1;
    reg [15:0] crc_stage1;
    reg [15:0] partial_crc;
    reg [2:0] bit_counter;
    reg valid_stage1, valid_stage2;
    
    // 单比特CRC计算函数 - 简化计算以便流水线化
    function [15:0] crc_bit_calc;
        input bit_data;
        input [15:0] crc_in;
        begin
            if ((bit_data ^ crc_in[15]) == 1'b1)
                crc_bit_calc = {crc_in[14:0], 1'b0} ^ 16'h1021;
            else
                crc_bit_calc = {crc_in[14:0], 1'b0};
        end
    endfunction

    // 控制逻辑和第一级流水线
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            crc <= 16'hFFFF;
            data_stage1 <= 8'h0;
            crc_stage1 <= 16'hFFFF;
            bit_counter <= 3'b0;
            valid_stage1 <= 1'b0;
            partial_crc <= 16'h0;
        end else begin
            case(state)
                IDLE: begin
                    valid_stage1 <= 1'b0;
                    if (start) begin
                        state <= CALC1;
                        data_stage1 <= data;
                        crc_stage1 <= crc;
                        bit_counter <= 3'b0;
                        valid_stage1 <= 1'b1;
                    end
                end
                
                CALC1: begin
                    // 第一级流水线 - 处理当前数据的一个比特
                    if (bit_counter < 7) begin
                        // 计算当前位的CRC并更新
                        partial_crc <= crc_bit_calc(data_stage1[bit_counter], 
                                                 (bit_counter == 0) ? crc_stage1 : partial_crc);
                        bit_counter <= bit_counter + 1'b1;
                    end else begin
                        // 处理最后一位
                        partial_crc <= crc_bit_calc(data_stage1[7], partial_crc);
                        state <= CALC2;
                        valid_stage2 <= 1'b1;
                    end
                end
                
                CALC2: begin
                    // 第二级流水线 - 准备输出结果
                    crc <= partial_crc;
                    valid_stage2 <= 1'b0;
                    state <= FINISH;
                end
                
                FINISH: begin
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
            
            // 支持连续数据输入 - 允许在计算过程中启动新数据
            if (start && state == FINISH) begin
                state <= CALC1;
                data_stage1 <= data;
                crc_stage1 <= partial_crc; // 使用当前计算结果作为下一个数据的初始值
                bit_counter <= 3'b0;
                valid_stage1 <= 1'b1;
            end
        end
    end

    assign done = (state == FINISH);
endmodule