//SystemVerilog
module multi_output_rst_sync (
    input  wire clock,
    input  wire reset_in_n,
    output wire reset_out_n_stage1,
    output wire reset_out_n_stage2,
    output wire reset_out_n_stage3,
    output wire reset_out_n_stage4,
    output wire reset_out_n_stage5,
    output wire reset_out_n_stage6
);
    // 增加流水线深度，从3级扩展到6级
    reg [5:0] sync_pipeline;
    reg sync_pipeline_buf1;
    reg sync_pipeline_buf2;
    reg sync_pipeline_buf3;
    reg sync_pipeline_buf4;
    reg sync_pipeline_buf5;
    reg sync_pipeline_buf6;
    
    // 低延迟同步模块的主要流水线逻辑
    always @(posedge clock or negedge reset_in_n) begin
        if (!reset_in_n) begin
            sync_pipeline <= 6'b000000;
            sync_pipeline_buf1 <= 1'b0;
            sync_pipeline_buf2 <= 1'b0;
            sync_pipeline_buf3 <= 1'b0;
            sync_pipeline_buf4 <= 1'b0;
            sync_pipeline_buf5 <= 1'b0;
            sync_pipeline_buf6 <= 1'b0;
        end
        else begin
            // 扩展流水线深度，通过移位操作传播复位释放信号
            sync_pipeline <= {sync_pipeline[4:0], 1'b1};
            
            // 拆分每级流水线的缓冲逻辑，降低每级的计算复杂度
            sync_pipeline_buf1 <= sync_pipeline[0];
            sync_pipeline_buf2 <= sync_pipeline[1];
            sync_pipeline_buf3 <= sync_pipeline[2];
            sync_pipeline_buf4 <= sync_pipeline[3];
            sync_pipeline_buf5 <= sync_pipeline[4];
            sync_pipeline_buf6 <= sync_pipeline[5];
        end
    end
    
    // 输出分配
    assign reset_out_n_stage1 = sync_pipeline_buf1;
    assign reset_out_n_stage2 = sync_pipeline_buf2;
    assign reset_out_n_stage3 = sync_pipeline_buf3;
    assign reset_out_n_stage4 = sync_pipeline_buf4;
    assign reset_out_n_stage5 = sync_pipeline_buf5;
    assign reset_out_n_stage6 = sync_pipeline_buf6;
endmodule