//SystemVerilog
module DelayCompBridge #(
    parameter DELAY_CYC = 3
)(
    input clk, rst_n,
    input valid_in,
    input [31:0] data_in,
    output valid_out,
    output [31:0] data_out,
    input ready_out,
    output ready_in
);
    // 流水线寄存器，存储数据和有效信号
    reg [31:0] data_stage [0:DELAY_CYC-1];
    reg valid_stage [0:DELAY_CYC-1];
    
    // 提前存储下一级的就绪状态
    reg [DELAY_CYC:0] next_stage_ready;
    
    // 流水线控制信号
    wire stage_ready [0:DELAY_CYC];
    
    // 反压机制，从下游向上游传播
    assign stage_ready[DELAY_CYC] = ready_out;
    
    genvar g;
    generate
        for (g = DELAY_CYC-1; g >= 0; g = g - 1) begin : gen_backpressure
            assign stage_ready[g] = !valid_stage[g] || next_stage_ready[g+1];
        end
    endgenerate
    
    // 输入接口就绪信号
    assign ready_in = stage_ready[0];
    
    // 输出接口
    assign data_out = data_stage[DELAY_CYC-1];
    assign valid_out = valid_stage[DELAY_CYC-1];
    
    integer i;
    
    // 流水线寄存器更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DELAY_CYC; i = i + 1) begin
                data_stage[i] <= 32'b0;
                valid_stage[i] <= 1'b0;
            end
            next_stage_ready <= {(DELAY_CYC+1){1'b0}};
        end else begin
            // 预先存储下一级的就绪状态，优化关键路径
            next_stage_ready[DELAY_CYC] <= ready_out;
            for (i = DELAY_CYC-1; i >= 0; i = i - 1) begin
                next_stage_ready[i] <= !valid_stage[i] || next_stage_ready[i+1];
            end
            
            // 第一级流水线
            if (stage_ready[0] && valid_in) begin
                data_stage[0] <= data_in;
                valid_stage[0] <= 1'b1;
            end else if (stage_ready[0] && !valid_in) begin
                valid_stage[0] <= 1'b0;
            end
            
            // 后续流水线级 - 优化处理顺序，减少关键路径
            for (i = 1; i < DELAY_CYC; i = i + 1) begin
                if (stage_ready[i]) begin
                    if (valid_stage[i-1]) begin
                        data_stage[i] <= data_stage[i-1];
                        valid_stage[i] <= 1'b1;
                    end else begin
                        valid_stage[i] <= 1'b0;
                    end
                end
            end
        end
    end
endmodule