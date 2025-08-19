//SystemVerilog
module shadow_reg_delayed_rst #(parameter DW=16, DELAY=3, PIPELINE_STAGES=3) (
    input clk, rst_in,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out
);
    // Reset shift register
    reg [DELAY-1:0] rst_sr;
    
    // Pipeline stage registers for data
    reg [DW-1:0] data_stage1, data_stage2;
    
    // Pipeline valid signals
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Combined reset signal
    wire reset_active = |rst_sr;
    
    always @(posedge clk) begin
        // Reset shift register logic
        rst_sr <= {rst_sr[DELAY-2:0], rst_in};
        
        // Pipeline stage 1
        data_stage1 <= reset_active ? {DW{1'b0}} : data_in;
        valid_stage1 <= !reset_active;
        
        // Pipeline stage 2
        data_stage2 <= reset_active ? {DW{1'b0}} : data_stage1;
        valid_stage2 <= reset_active ? 1'b0 : valid_stage1;
        
        // Pipeline stage 3 (output stage)
        data_out <= reset_active ? {DW{1'b0}} : data_stage2;
        valid_stage3 <= reset_active ? 1'b0 : valid_stage2;
    end
endmodule