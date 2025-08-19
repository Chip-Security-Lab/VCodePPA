//SystemVerilog
module variable_step_counter #(parameter STEP=1) (
    input wire clk, rst,
    output reg [7:0] ring_reg
);

    // 预计算的几个循环移位结果
    reg [7:0] shift_1, shift_2, shift_3, shift_4;
    reg [7:0] shift_5, shift_6, shift_7;
    
    // 流水线寄存器 - 多级流水线以分解复杂组合逻辑
    reg [7:0] ring_stage1;
    reg [7:0] ring_stage2;
    
    // 第一阶段流水线 - 预先计算所有可能的移位结果
    always @(posedge clk) begin
        if (rst) begin
            shift_1 <= 8'h00;
            shift_2 <= 8'h00;
            shift_3 <= 8'h00;
            shift_4 <= 8'h00;
            shift_5 <= 8'h00;
            shift_6 <= 8'h00;
            shift_7 <= 8'h00;
        end else begin
            shift_1 <= {ring_reg[0], ring_reg[7:1]};
            shift_2 <= {ring_reg[1:0], ring_reg[7:2]};
            shift_3 <= {ring_reg[2:0], ring_reg[7:3]};
            shift_4 <= {ring_reg[3:0], ring_reg[7:4]};
            shift_5 <= {ring_reg[4:0], ring_reg[7:5]};
            shift_6 <= {ring_reg[5:0], ring_reg[7:6]};
            shift_7 <= {ring_reg[6:0], ring_reg[7]};
        end
    end
    
    // 第二阶段流水线 - 选择合适的移位结果
    always @(posedge clk) begin
        if (rst) 
            ring_stage1 <= 8'h01;
        else begin
            case (STEP)
                1: ring_stage1 <= shift_1;
                2: ring_stage1 <= shift_2;
                3: ring_stage1 <= shift_3;
                4: ring_stage1 <= shift_4;
                5: ring_stage1 <= shift_5;
                6: ring_stage1 <= shift_6;
                7: ring_stage1 <= shift_7;
                default: ring_stage1 <= shift_1; // 默认步长为1
            endcase
        end
    end
    
    // 第三级流水线：进一步处理并准备输出
    always @(posedge clk) begin
        if (rst)
            ring_stage2 <= 8'h01;
        else
            ring_stage2 <= ring_stage1;
    end
    
    // 最终输出寄存器
    always @(posedge clk) begin
        if (rst)
            ring_reg <= 8'h01;
        else
            ring_reg <= ring_stage2;
    end

endmodule