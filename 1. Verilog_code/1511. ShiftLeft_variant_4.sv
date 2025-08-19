//SystemVerilog
// IEEE 1364-2005 Verilog标准
module ShiftLeft #(parameter WIDTH=8) (
    input wire clk, rst_n, en, serial_in,
    input wire flush,  // 新增流水线刷新信号
    output reg [WIDTH-1:0] q,
    output reg valid_out  // 新增有效输出信号
);
    // 流水线寄存器
    reg [WIDTH-1:0] q_stage1, q_stage2, q_stage3;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 阶段1: 初始移位操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else if (flush) begin
            q_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else if (en) begin
            q_stage1 <= {q[WIDTH-2:0], serial_in};
            valid_stage1 <= 1'b1;
        end else begin
            q_stage1 <= q_stage1;
            valid_stage1 <= valid_stage1;
        end
    end
    
    // 阶段2: 中间处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else if (flush) begin
            q_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            q_stage2 <= q_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 阶段3: 最终输出阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_stage3 <= {WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
        end else if (flush) begin
            q_stage3 <= {WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            q_stage3 <= q_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出赋值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else if (flush) begin
            q <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            q <= q_stage3;
            valid_out <= valid_stage3;
        end
    end
    
endmodule