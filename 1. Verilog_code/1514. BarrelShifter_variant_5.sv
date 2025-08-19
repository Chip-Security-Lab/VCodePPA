//SystemVerilog
// SystemVerilog
// IEEE 1364-2005
module BarrelShifter #(
    parameter SIZE        = 16,
    parameter SHIFT_WIDTH = 4
)(
    input                      clk,      // 时钟信号
    input                      rst_n,    // 复位信号，低有效
    input      [SIZE-1:0]      din,      // 输入数据
    input      [SHIFT_WIDTH-1:0] shift,    // 移位量
    input                      en,       // 使能信号
    input                      left,     // 移位方向控制：1=左移，0=右移
    output reg [SIZE-1:0]      dout      // 输出数据
);

    // 第一级移位结果 - 直接在组合逻辑后寄存
    reg [SIZE-1:0]       stage1_data;
    reg                   en_stage1;
    reg                   left_stage1;
    reg [SHIFT_WIDTH-3:0] shift_high_stage1;
    
    // 第二级移位结果
    reg [SIZE-1:0]       stage2_result;
    
    // 组合逻辑 - 计算低位移位
    wire [SIZE-1:0] shift_result_low;
    
    // 组合逻辑处理低两位移位，将寄存器移到组合逻辑之后
    assign shift_result_low = (left) ? 
                             ((shift[1:0] == 2'b00) ? din :
                              (shift[1:0] == 2'b01) ? {din[SIZE-2:0], 1'b0} :
                              (shift[1:0] == 2'b10) ? {din[SIZE-3:0], 2'b0} :
                                                      {din[SIZE-4:0], 3'b0}) :
                             ((shift[1:0] == 2'b00) ? din :
                              (shift[1:0] == 2'b01) ? {1'b0, din[SIZE-1:1]} :
                              (shift[1:0] == 2'b10) ? {2'b0, din[SIZE-1:2]} :
                                                      {3'b0, din[SIZE-1:3]});
    
    // 第一级流水线：寄存低位移位结果和控制信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= {SIZE{1'b0}};
            en_stage1 <= 1'b0;
            left_stage1 <= 1'b0;
            shift_high_stage1 <= {(SHIFT_WIDTH-2){1'b0}};
        end else begin
            stage1_data <= en ? shift_result_low : din;
            en_stage1 <= en;
            left_stage1 <= left;
            shift_high_stage1 <= shift[SHIFT_WIDTH-1:2];
        end
    end
    
    // 第二级流水线：执行高位移位运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_result <= {SIZE{1'b0}};
        end else if (en_stage1) begin
            // 处理高位移位，完成移位操作
            if (left_stage1) begin
                case(shift_high_stage1)
                    0: stage2_result <= stage1_data;
                    1: stage2_result <= {stage1_data[SIZE-5:0], 4'b0};
                    2: stage2_result <= {stage1_data[SIZE-9:0], 8'b0};
                    3: stage2_result <= {stage1_data[SIZE-13:0], 12'b0};
                    default: stage2_result <= {SIZE{1'b0}}; // 处理更大移位
                endcase
            end else begin
                case(shift_high_stage1)
                    0: stage2_result <= stage1_data;
                    1: stage2_result <= {4'b0, stage1_data[SIZE-1:4]};
                    2: stage2_result <= {8'b0, stage1_data[SIZE-1:8]};
                    3: stage2_result <= {12'b0, stage1_data[SIZE-1:12]};
                    default: stage2_result <= {SIZE{1'b0}}; // 处理更大移位
                endcase
            end
        end else begin
            stage2_result <= stage1_data; // 非使能状态保持前一级结果
        end
    end
    
    // 输出级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= {SIZE{1'b0}};
        end else begin
            dout <= stage2_result;
        end
    end

endmodule