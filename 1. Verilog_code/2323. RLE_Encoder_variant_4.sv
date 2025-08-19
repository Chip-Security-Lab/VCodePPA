//SystemVerilog
module RLE_Encoder (
    input clk, rst_n, en,
    input [7:0] data_in,
    output reg [15:0] data_out,
    output reg valid
);
    // 流水线级数定义
    localparam PIPE_STAGES = 3;
    
    // 流水线寄存器
    reg [7:0] prev_data_stage1, prev_data_stage2, prev_data_stage3;
    reg [7:0] counter_stage1, counter_stage2, counter_stage3;
    reg [7:0] data_stage1, data_stage2, data_stage3;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3;
    reg new_symbol_stage1, new_symbol_stage2;
    
    // 状态定义
    localparam RESET = 2'b00,
               COUNT = 2'b01,
               NEW_SYMBOL = 2'b10;
    reg [1:0] state_stage1;
    
    // 第一级流水线 - 状态判断和计数器更新
    always @(posedge clk) begin
        if (!rst_n) begin
            state_stage1 <= RESET;
            prev_data_stage1 <= 8'h0;
            counter_stage1 <= 8'h0;
            data_stage1 <= 8'h0;
            valid_stage1 <= 1'b0;
            new_symbol_stage1 <= 1'b0;
        end
        else if (en) begin
            data_stage1 <= data_in;
            
            if (state_stage1 == RESET) begin
                prev_data_stage1 <= data_in;
                counter_stage1 <= 8'h1;
                valid_stage1 <= 1'b1;
                new_symbol_stage1 <= 1'b0;
                state_stage1 <= COUNT;
            end
            else if (data_in == prev_data_stage1 && counter_stage1 < 8'hFF) begin
                counter_stage1 <= counter_stage1 + 8'h1;
                new_symbol_stage1 <= 1'b0;
                state_stage1 <= COUNT;
            end
            else begin
                new_symbol_stage1 <= 1'b1;
                valid_stage1 <= 1'b1;
                state_stage1 <= NEW_SYMBOL;
            end
        end
    end
    
    // 第二级流水线 - 处理新符号转换
    always @(posedge clk) begin
        if (!rst_n) begin
            prev_data_stage2 <= 8'h0;
            counter_stage2 <= 8'h0;
            data_stage2 <= 8'h0;
            valid_stage2 <= 1'b0;
            new_symbol_stage2 <= 1'b0;
        end
        else if (en) begin
            valid_stage2 <= valid_stage1;
            new_symbol_stage2 <= new_symbol_stage1;
            data_stage2 <= data_stage1;
            
            if (new_symbol_stage1) begin
                prev_data_stage2 <= data_stage1;
                counter_stage2 <= 8'h1;
            end
            else begin
                prev_data_stage2 <= prev_data_stage1;
                counter_stage2 <= counter_stage1;
            end
        end
    end
    
    // 第三级流水线 - 输出生成
    always @(posedge clk) begin
        if (!rst_n) begin
            prev_data_stage3 <= 8'h0;
            counter_stage3 <= 8'h0;
            data_stage3 <= 8'h0;
            valid_stage3 <= 1'b0;
            data_out <= 16'h0;
            valid <= 1'b0;
        end
        else if (en) begin
            prev_data_stage3 <= prev_data_stage2;
            counter_stage3 <= counter_stage2;
            data_stage3 <= data_stage2;
            valid_stage3 <= valid_stage2;
            
            if (new_symbol_stage2 && valid_stage2) begin
                data_out <= {counter_stage2, prev_data_stage2};
                valid <= 1'b1;
            end
            else begin
                valid <= valid_stage3 && (counter_stage3 != 8'h0);
            end
        end
    end
    
endmodule