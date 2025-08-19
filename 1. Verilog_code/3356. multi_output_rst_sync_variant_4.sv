//SystemVerilog
module multi_output_rst_sync (
    input  wire clock,
    input  wire reset_in_n,
    output wire reset_out_n_stage1,
    output wire reset_out_n_stage2,
    output wire reset_out_n_stage3
);
    // 内部时序逻辑信号
    reg [2:0] sync_pipeline_reg;
    // 组合逻辑信号
    wire next_bit;
    
    // 组合逻辑部分
    assign next_bit = 1'b1;  // 同步器的输入位始终为1
    
    // 组合逻辑输出映射
    assign reset_out_n_stage1 = sync_pipeline_reg[0];
    assign reset_out_n_stage2 = sync_pipeline_reg[1];
    assign reset_out_n_stage3 = sync_pipeline_reg[2];
    
    // 时序逻辑部分
    always @(posedge clock or negedge reset_in_n) begin
        if (!reset_in_n) begin
            sync_pipeline_reg <= 3'b000;
        end else begin
            sync_pipeline_reg <= {sync_pipeline_reg[1:0], next_bit};
        end
    end
endmodule