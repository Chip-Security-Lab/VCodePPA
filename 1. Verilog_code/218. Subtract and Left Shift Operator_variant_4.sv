//SystemVerilog
module subtract_shift_left (
    input wire clk,              
    input wire rst_n,            
    input wire [7:0] a,
    input wire [7:0] b,
    input wire [2:0] shift_amount,
    output reg [7:0] difference, 
    output reg [7:0] shifted_result 
);
    // 内部流水线寄存器 - 第一级
    reg [7:0] a_stage1, b_stage1;
    reg [2:0] shift_amount_stage1;
    
    // 内部流水线寄存器 - 第二级
    reg [7:0] a_stage2, b_stage2;
    reg [2:0] shift_amount_stage2;
    
    // 内部流水线寄存器 - 第三级
    reg [7:0] difference_stage3;
    reg [7:0] a_for_shift_stage3;
    reg [2:0] shift_amount_stage3;
    
    // 内部流水线寄存器 - 第四级
    reg [7:0] difference_stage4;
    reg [7:0] shifted_intermediate_stage4;
    
    // 第一级流水线: 寄存输入值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 8'b0;
            b_stage1 <= 8'b0;
            shift_amount_stage1 <= 3'b0;
        end else begin
            a_stage1 <= a;
            b_stage1 <= b;
            shift_amount_stage1 <= shift_amount;
        end
    end
    
    // 第二级流水线: 寄存第一级的值，准备计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage2 <= 8'b0;
            b_stage2 <= 8'b0;
            shift_amount_stage2 <= 3'b0;
        end else begin
            a_stage2 <= a_stage1;
            b_stage2 <= b_stage1;
            shift_amount_stage2 <= shift_amount_stage1;
        end
    end
    
    // 第三级流水线: 执行减法，准备移位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            difference_stage3 <= 8'b0;
            a_for_shift_stage3 <= 8'b0;
            shift_amount_stage3 <= 3'b0;
        end else begin
            difference_stage3 <= a_stage2 - b_stage2;
            a_for_shift_stage3 <= a_stage2;
            shift_amount_stage3 <= shift_amount_stage2;
        end
    end
    
    // 第四级流水线: 下一步处理移位运算和减法结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            difference_stage4 <= 8'b0;
            shifted_intermediate_stage4 <= 8'b0;
        end else begin
            difference_stage4 <= difference_stage3;
            // 将移位操作分解
            case(shift_amount_stage3[2])
                1'b0: shifted_intermediate_stage4 <= a_for_shift_stage3;
                1'b1: shifted_intermediate_stage4 <= {a_for_shift_stage3[3:0], 4'b0000};
            endcase
        end
    end
    
    // 第五级流水线: 最终输出结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            difference <= 8'b0;
            shifted_result <= 8'b0;
        end else begin
            difference <= difference_stage4;
            // 完成剩余移位操作
            case(shift_amount_stage3[1:0])
                2'b00: shifted_result <= shifted_intermediate_stage4;
                2'b01: shifted_result <= {shifted_intermediate_stage4[6:0], 1'b0};
                2'b10: shifted_result <= {shifted_intermediate_stage4[5:0], 2'b00};
                2'b11: shifted_result <= {shifted_intermediate_stage4[4:0], 3'b000};
            endcase
        end
    end
    
endmodule