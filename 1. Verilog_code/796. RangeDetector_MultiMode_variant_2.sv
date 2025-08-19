//SystemVerilog
module RangeDetector_MultiMode #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input [1:0] mode,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    input valid_in,           // 输入数据有效信号
    output ready_in,          // 输入准备好接收新数据信号
    output reg valid_out,     // 输出数据有效信号
    output reg [WIDTH-1:0] data_out_stage2, // 流水线输出数据（可选）
    output reg flag
);

// 第一级流水线寄存器
reg [WIDTH-1:0] data_in_stage1;
reg [WIDTH-1:0] threshold_stage1;
reg [1:0] mode_stage1;
reg valid_stage1;

// 第二级流水线寄存器
reg [1:0] mode_stage2;
reg valid_stage2;
reg [WIDTH-1:0] data_stage2, threshold_stage2;

// 比较结果（第一级流水线的组合逻辑）
reg comp_ge_stage1, comp_le_stage1, comp_ne_stage1, comp_eq_stage1;

// 流水线控制逻辑
assign ready_in = 1'b1; // 简单实现始终准备好接收数据，可根据需要实现背压机制

// 第一级流水线：寄存输入数据并进行比较
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_in_stage1 <= {WIDTH{1'b0}};
        threshold_stage1 <= {WIDTH{1'b0}};
        mode_stage1 <= 2'b00;
        valid_stage1 <= 1'b0;
        
        comp_ge_stage1 <= 1'b0;
        comp_le_stage1 <= 1'b0;
        comp_ne_stage1 <= 1'b0;
        comp_eq_stage1 <= 1'b0;
    end else begin
        // 寄存输入数据
        data_in_stage1 <= data_in;
        threshold_stage1 <= threshold;
        mode_stage1 <= mode;
        valid_stage1 <= valid_in;
        
        // 预计算所有比较结果
        comp_ge_stage1 <= (data_in >= threshold);
        comp_le_stage1 <= (data_in <= threshold);
        comp_ne_stage1 <= (data_in != threshold);
        comp_eq_stage1 <= (data_in == threshold);
    end
end

// 第二级流水线：根据模式选择比较结果
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        flag <= 1'b0;
        valid_stage2 <= 1'b0;
        mode_stage2 <= 2'b00;
        data_stage2 <= {WIDTH{1'b0}};
        threshold_stage2 <= {WIDTH{1'b0}};
        valid_out <= 1'b0;
        data_out_stage2 <= {WIDTH{1'b0}};
    end else begin
        // 传递控制信号和数据到第二级
        valid_stage2 <= valid_stage1;
        mode_stage2 <= mode_stage1;
        data_stage2 <= data_in_stage1;
        threshold_stage2 <= threshold_stage1;
        
        // 根据模式选择比较结果
        if (valid_stage1) begin
            case(mode_stage1)
                2'b00: flag <= comp_ge_stage1;
                2'b01: flag <= comp_le_stage1;
                2'b10: flag <= comp_ne_stage1;
                2'b11: flag <= comp_eq_stage1;
            endcase
        end
        
        // 输出控制和数据
        valid_out <= valid_stage2;
        data_out_stage2 <= data_stage2;
    end
end

endmodule