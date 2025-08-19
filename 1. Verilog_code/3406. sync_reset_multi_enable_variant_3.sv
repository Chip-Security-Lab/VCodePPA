//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: sync_reset_multi_enable_pipelined.v
// Description: Top level module for synchronous reset with multiple enable conditions
//              implemented with pipelined architecture for improved throughput
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module sync_reset_multi_enable (
    input  wire       clk,
    input  wire       reset_in,
    input  wire [3:0] enable_conditions,
    output wire [3:0] reset_out
);

    // Individual reset control signals for each channel
    wire [3:0] reset_channel;

    // Generate and instantiate 4 reset controller channels
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : reset_channel_gen
            reset_controller_pipelined channel_ctrl (
                .clk              (clk),
                .reset_in         (reset_in),
                .enable_condition (enable_conditions[i]),
                .reset_out        (reset_channel[i])
            );
        end
    endgenerate

    // Connect individual channel outputs to the final reset_out
    assign reset_out = reset_channel;

endmodule

///////////////////////////////////////////////////////////////////////////////
// Single channel reset controller with pipelined architecture
///////////////////////////////////////////////////////////////////////////////

module reset_controller_pipelined (
    input  wire clk,
    input  wire reset_in,
    input  wire enable_condition,
    output wire reset_out
);
    // Pipeline stage registers
    reg reset_out_stage1;
    reg reset_out_stage2;
    reg reset_out_stage3;
    
    // Pipeline valid registers to track active data
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;
    
    // Input capture registers
    reg enable_condition_reg;
    reg reset_in_reg;
    
    // Pipeline Stage 0: Input capture
    always @(posedge clk) begin
        enable_condition_reg <= enable_condition;
        reset_in_reg <= reset_in;
        valid_stage1 <= 1'b1; // Start valid signal propagation
    end
    
    // Pipeline Stage 1: Initial reset processing
    always @(posedge clk) begin
        if (reset_in_reg) begin
            reset_out_stage1 <= 1'b1;
        end
        else if (valid_stage1) begin
            reset_out_stage1 <= enable_condition_reg ? 1'b0 : reset_out_stage3; // Feedback from final stage
        end
        valid_stage2 <= valid_stage1;
    end
    
    // Pipeline Stage 2: Intermediate processing
    always @(posedge clk) begin
        reset_out_stage2 <= reset_out_stage1;
        valid_stage3 <= valid_stage2;
    end
    
    // Pipeline Stage 3: Final output stage
    always @(posedge clk) begin
        reset_out_stage3 <= reset_out_stage2;
    end
    
    // Output assignment
    assign reset_out = reset_out_stage3;

endmodule