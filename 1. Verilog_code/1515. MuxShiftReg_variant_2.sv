//SystemVerilog
// IEEE 1364-2005
module MuxShiftReg #(parameter DEPTH=4, WIDTH=8) (
    input clk,
    input rst_n,  // 添加复位信号
    input [1:0] sel,
    input [WIDTH-1:0] din,
    input valid_in,  // 输入有效信号
    output valid_out, // 输出有效信号
    output reg [WIDTH-1:0] dout
);
    // 流水线寄存器组
    reg [WIDTH-1:0] regs_stage1 [0:DEPTH-1];
    reg [WIDTH-1:0] regs_stage2 [0:DEPTH-1];
    reg [WIDTH-1:0] regs_stage3 [0:DEPTH-1];
    
    // 流水线控制信号
    reg [1:0] sel_stage1, sel_stage2;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 第一级流水线：寄存选择信号和输入数据
    always @(posedge clk) begin
        if (!rst_n) begin
            sel_stage1 <= 2'b00;
            valid_stage1 <= 1'b0;
        end else begin
            sel_stage1 <= sel;
            valid_stage1 <= valid_in;
            
            // 将当前寄存器状态保存到第一级流水线
            for (integer i=0; i<DEPTH; i=i+1) begin
                regs_stage1[i] <= regs_stage3[i];
            end
        end
    end
    
    // 第二级流水线：计算新的寄存器状态
    always @(posedge clk) begin
        if (!rst_n) begin
            sel_stage2 <= 2'b00;
            valid_stage2 <= 1'b0;
        end else begin
            sel_stage2 <= sel_stage1;
            valid_stage2 <= valid_stage1;
            
            // 根据选择信号确定的操作计算中间状态
            case(sel_stage1)
                2'b00: begin // Shift left
                    for (integer i=DEPTH-1; i>0; i=i-1)
                        regs_stage2[i] <= regs_stage1[i-1];
                    regs_stage2[0] <= din;
                end
                2'b01: begin // Shift right
                    for (integer i=0; i<DEPTH-1; i=i+1)
                        regs_stage2[i] <= regs_stage1[i+1];
                    regs_stage2[DEPTH-1] <= din;
                end
                2'b10: begin // Rotate right
                    for (integer i=0; i<DEPTH-1; i=i+1)
                        regs_stage2[i] <= regs_stage1[i+1];
                    regs_stage2[DEPTH-1] <= regs_stage1[0];
                end
                default: begin // Hold values
                    for (integer i=0; i<DEPTH; i=i+1)
                        regs_stage2[i] <= regs_stage1[i];
                end
            endcase
        end
    end
    
    // 第三级流水线：最终寄存器状态和输出
    always @(posedge clk) begin
        if (!rst_n) begin
            valid_stage3 <= 1'b0;
            for (integer i=0; i<DEPTH; i=i+1) begin
                regs_stage3[i] <= {WIDTH{1'b0}};
            end
            dout <= {WIDTH{1'b0}};
        end else begin
            valid_stage3 <= valid_stage2;
            
            // 更新最终寄存器状态
            for (integer i=0; i<DEPTH; i=i+1) begin
                regs_stage3[i] <= regs_stage2[i];
            end
            
            // 输出最后一个寄存器的值
            dout <= regs_stage2[DEPTH-1];
        end
    end
    
    // 连接输出有效信号
    assign valid_out = valid_stage3;
    
endmodule