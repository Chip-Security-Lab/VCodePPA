//SystemVerilog
module updown_timer #(parameter WIDTH = 16)(
    input clk, rst_n, en, up_down,  // 1 = up, 0 = down
    input [WIDTH-1:0] load_val,
    input load_en,
    output reg [WIDTH-1:0] count,
    output reg overflow, underflow
);
    // 将计数操作拆分为多个流水线级
    reg [WIDTH-1:0] count_stage1, count_stage2;
    reg up_down_stage1, up_down_stage2;
    reg en_stage1, en_stage2;
    reg load_en_stage1, load_en_stage2;
    reg [WIDTH-1:0] load_val_stage1, load_val_stage2;
    
    // 计算结果寄存器
    reg [WIDTH-1:0] add_result, sub_result;
    
    // 阶段1 - 输入寄存
    always @(posedge clk) begin
        if (!rst_n) begin
            count_stage1 <= {WIDTH{1'b0}};
            up_down_stage1 <= 1'b0;
            en_stage1 <= 1'b0;
            load_en_stage1 <= 1'b0;
            load_val_stage1 <= {WIDTH{1'b0}};
        end else begin
            count_stage1 <= count;
            up_down_stage1 <= up_down;
            en_stage1 <= en;
            load_en_stage1 <= load_en;
            load_val_stage1 <= load_val;
        end
    end
    
    // 阶段2 - 提前计算加法和减法结果
    always @(posedge clk) begin
        if (!rst_n) begin
            add_result <= {WIDTH{1'b0}};
            sub_result <= {WIDTH{1'b0}};
            count_stage2 <= {WIDTH{1'b0}};
            up_down_stage2 <= 1'b0;
            en_stage2 <= 1'b0;
            load_en_stage2 <= 1'b0;
            load_val_stage2 <= {WIDTH{1'b0}};
        end else begin
            add_result <= count_stage1 + 1'b1;
            sub_result <= count_stage1 - 1'b1;
            count_stage2 <= count_stage1;
            up_down_stage2 <= up_down_stage1;
            en_stage2 <= en_stage1;
            load_en_stage2 <= load_en_stage1;
            load_val_stage2 <= load_val_stage1;
        end
    end
    
    // 阶段3 - 最终计数值选择 (使用case替代if-else)
    always @(posedge clk) begin
        if (!rst_n) begin
            count <= {WIDTH{1'b0}};
        end else begin
            case ({load_en_stage2, en_stage2, up_down_stage2})
                3'b100, 3'b101:  // load_en为高，忽略其他信号
                    count <= load_val_stage2;
                3'b010:          // en为高，up_down为低
                    count <= sub_result;
                3'b011:          // en为高，up_down为高
                    count <= add_result;
                default:         // 其他情况保持不变
                    count <= count;
            endcase
        end
    end
    
    // 溢出/下溢检测管线化 (使用case替代if-else)
    reg overflow_temp, underflow_temp;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            overflow_temp <= 1'b0;
            underflow_temp <= 1'b0;
        end else begin
            case ({en_stage2, up_down_stage2})
                2'b11:  // en为高且up_down为高
                    begin
                        overflow_temp <= &count_stage2;
                        underflow_temp <= 1'b0;
                    end
                2'b10:  // en为高且up_down为低
                    begin
                        overflow_temp <= 1'b0;
                        underflow_temp <= ~|count_stage2;
                    end
                default:  // en为低或其他情况
                    begin
                        overflow_temp <= 1'b0;
                        underflow_temp <= 1'b0;
                    end
            endcase
        end
    end
    
    // 最终溢出/下溢输出
    always @(posedge clk) begin
        if (!rst_n) begin
            overflow <= 1'b0;
            underflow <= 1'b0;
        end else begin
            overflow <= overflow_temp;
            underflow <= underflow_temp;
        end
    end
    
endmodule