//SystemVerilog
module pl_reg_parity #(parameter W=8) (
    input clk, 
    input rst_n,
    input load,
    input [W-1:0] data_in,
    input valid_in,
    output valid_out,
    output ready_in,
    output reg [W:0] data_out
);

// 简化流水线控制信号，提前计算
assign ready_in = 1'b1;  // 本设计始终可以接收新数据

// 奇偶校验预计算寄存器
reg [W/2-1:0] partial_parity1;
reg [W-W/2-1:0] partial_parity2;
reg valid_stage1;
reg [W-1:0] data_stage1;

// 最终奇偶校验和输出控制
reg parity_final;
reg valid_stage2;

// 输出赋值
assign valid_out = valid_stage2;

// 阶段1: 并行计算奇偶校验的两部分
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        partial_parity1 <= {(W/2){1'b0}};
        partial_parity2 <= {(W-W/2){1'b0}};
        data_stage1 <= {W{1'b0}};
        valid_stage1 <= 1'b0;
    end else begin
        if (load && valid_in) begin
            // 将奇偶校验计算拆分为两部分，减少关键路径
            partial_parity1 <= ^data_in[W/2-1:0];
            partial_parity2 <= ^data_in[W-1:W/2];
            data_stage1 <= data_in;
            valid_stage1 <= 1'b1;
        end else if (!load) begin
            valid_stage1 <= 1'b0;
        end
    end
end

// 阶段2: 合并奇偶校验结果并组装输出
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        parity_final <= 1'b0;
        valid_stage2 <= 1'b0;
        data_out <= {(W+1){1'b0}};
    end else begin
        if (valid_stage1) begin
            // 合并两部分奇偶校验结果
            parity_final <= partial_parity1 ^ partial_parity2;
            valid_stage2 <= 1'b1;
            data_out <= {parity_final, data_stage1};
        end else begin
            valid_stage2 <= 1'b0;
        end
    end
end

endmodule