//SystemVerilog
module pl_reg_preset #(parameter W=8, PRESET=8'hFF) (
    input wire clk,
    input wire rst_n,
    input wire load,
    input wire shift_in,
    input wire valid_in,
    output wire valid_out,
    output wire ready_out,
    output wire [W-1:0] q
);
    // 流水线阶段定义
    localparam STAGES = 2; // 两级流水线
    
    // 流水线寄存器 - 数据路径
    reg [W-1:0] q_stage1;
    reg [W-1:0] q_stage2;
    
    // 流水线寄存器 - 控制信号
    reg valid_stage1;
    reg valid_stage2;
    
    // 流水线阶段1 - 加载预设值或进行移位操作的第一部分
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_stage1 <= {W{1'b0}};
            valid_stage1 <= 1'b0;
        end else if (ready_out) begin
            case ({valid_in, load})
                2'b11: begin // valid_in=1, load=1
                    q_stage1 <= PRESET;
                    valid_stage1 <= 1'b1;
                end
                2'b10: begin // valid_in=1, load=0
                    q_stage1 <= {q[W-2:0], shift_in};
                    valid_stage1 <= 1'b1;
                end
                default: begin // valid_in=0, 任意load值
                    valid_stage1 <= 1'b0;
                end
            endcase
        end
    end
    
    // 流水线阶段2 - 最终输出寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_stage2 <= {W{1'b0}};
            valid_stage2 <= 1'b0;
        end else if (ready_out) begin
            q_stage2 <= q_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出赋值
    assign q = q_stage2;
    assign valid_out = valid_stage2;
    
    // 简单的流水线背压控制 - 此实现总是准备好接收新数据
    assign ready_out = 1'b1;

endmodule