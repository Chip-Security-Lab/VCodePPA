//SystemVerilog
// Top-level module that instantiates reset synchronizer stages
module multi_output_rst_sync #(
    parameter SYNC_STAGES = 2  // Number of flip-flops in each synchronizer chain
)(
    input  wire clock,
    input  wire reset_in_n,
    output wire reset_out_n_stage1,
    output wire reset_out_n_stage2,
    output wire reset_out_n_stage3
);
    // Internal connections between synchronizer stages
    wire stage1_sync_out;
    wire stage2_sync_out;
    
    // First stage reset synchronizer
    reset_synchronizer #(
        .SYNC_STAGES(SYNC_STAGES)
    ) stage1_sync (
        .clock(clock),
        .reset_in_n(reset_in_n),
        .reset_out_n(reset_out_n_stage1)
    );
    
    // Second stage reset synchronizer (uses output from first stage)
    reset_synchronizer #(
        .SYNC_STAGES(SYNC_STAGES)
    ) stage2_sync (
        .clock(clock),
        .reset_in_n(reset_in_n),
        .synchronized_input(reset_out_n_stage1),
        .reset_out_n(reset_out_n_stage2)
    );
    
    // Third stage reset synchronizer (uses output from second stage)
    reset_synchronizer #(
        .SYNC_STAGES(SYNC_STAGES)
    ) stage3_sync (
        .clock(clock),
        .reset_in_n(reset_in_n),
        .synchronized_input(reset_out_n_stage2),
        .reset_out_n(reset_out_n_stage3)
    );
    
endmodule

// Generic reset synchronizer module
module reset_synchronizer #(
    parameter SYNC_STAGES = 2  // Number of flip-flops in synchronizer chain
)(
    input  wire clock,            // System clock
    input  wire reset_in_n,       // Asynchronous reset input (active low)
    input  wire synchronized_input = 1'b1, // Optional input from previous stage
    output wire reset_out_n       // Synchronized reset output (active low)
);
    // Synchronization register pipeline
    reg [SYNC_STAGES-1:0] sync_pipeline;
    
    // Synchronization process
    always @(posedge clock or negedge reset_in_n) begin
        if (!reset_in_n)
            sync_pipeline <= {SYNC_STAGES{1'b0}};
        else
            sync_pipeline <= {sync_pipeline[SYNC_STAGES-2:0], synchronized_input};
    end
    
    // Output assignment
    assign reset_out_n = sync_pipeline[SYNC_STAGES-1];
    
endmodule