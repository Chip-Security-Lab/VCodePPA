module multi_output_rst_sync (
    input  wire clock,
    input  wire reset_in_n,
    output wire reset_out_n_stage1,
    output wire reset_out_n_stage2,
    output wire reset_out_n_stage3
);
    reg [2:0] sync_pipeline;
    
    always @(posedge clock or negedge reset_in_n) begin
        if (!reset_in_n)
            sync_pipeline <= 3'b000;
        else
            sync_pipeline <= {sync_pipeline[1:0], 1'b1};
    end
    
    assign reset_out_n_stage1 = sync_pipeline[0];
    assign reset_out_n_stage2 = sync_pipeline[1];
    assign reset_out_n_stage3 = sync_pipeline[2];
endmodule
