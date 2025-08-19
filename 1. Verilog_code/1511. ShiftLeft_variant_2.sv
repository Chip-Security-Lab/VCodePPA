//SystemVerilog
// IEEE 1364-2005 Verilog
module ShiftLeft #(parameter WIDTH=8) (
    input clk, rst_n, en, serial_in,
    output reg [WIDTH-1:0] q
);

// 流水线阶段寄存器
reg [WIDTH-1:0] shift_reg_stage1;
reg [WIDTH-1:0] shift_reg_stage2;
reg [WIDTH-1:0] shift_reg_stage3;
reg [WIDTH-1:0] shift_reg_stage4;

// 流水线控制信号
reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;

// 阶段1计算：将输入位添加到移位寄存器
wire [WIDTH-1:0] next_shift_stage1;
assign next_shift_stage1 = en ? {shift_reg_stage1[WIDTH-2:0], serial_in} : shift_reg_stage1;

// 流水线执行逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 重置所有流水线阶段
        shift_reg_stage1 <= {WIDTH{1'b0}};
        shift_reg_stage2 <= {WIDTH{1'b0}};
        shift_reg_stage3 <= {WIDTH{1'b0}};
        shift_reg_stage4 <= {WIDTH{1'b0}};
        
        // 重置控制信号
        valid_stage1 <= 1'b0;
        valid_stage2 <= 1'b0;
        valid_stage3 <= 1'b0;
        valid_stage4 <= 1'b0;
        
        // 重置输出
        q <= {WIDTH{1'b0}};
    end
    else begin
        // 阶段1：输入处理
        shift_reg_stage1 <= next_shift_stage1;
        valid_stage1 <= en;
        
        // 阶段2：数据前传
        shift_reg_stage2 <= shift_reg_stage1;
        valid_stage2 <= valid_stage1;
        
        // 阶段3：数据前传
        shift_reg_stage3 <= shift_reg_stage2;
        valid_stage3 <= valid_stage2;
        
        // 阶段4：输出阶段
        shift_reg_stage4 <= shift_reg_stage3;
        valid_stage4 <= valid_stage3;
        
        // 输出更新
        if (valid_stage4) begin
            q <= shift_reg_stage4;
        end
    end
end

endmodule