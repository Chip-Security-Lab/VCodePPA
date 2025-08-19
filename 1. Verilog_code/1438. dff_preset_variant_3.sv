//SystemVerilog
module dff_preset (
    input wire clk,
    input wire reset_n,
    input wire preset,
    input wire d,
    input wire valid_in,
    output wire valid_out,
    output reg q
);

    // Pipeline Stage 1: Input registration
    reg preset_stage1, d_stage1;
    reg valid_stage1;

    // Pipeline Stage 2: Process and prepare output
    reg preset_stage2, d_stage2;
    reg valid_stage2;

    // Pipeline Control
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // Reset all pipeline registers
            preset_stage1 <= 1'b0;
            d_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            
            preset_stage2 <= 1'b0;
            d_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            
            q <= 1'b0;
        end else begin
            // Stage 1: Register inputs
            preset_stage1 <= preset;
            d_stage1 <= d;
            valid_stage1 <= valid_in;
            
            // Stage 2: Process and prepare output
            preset_stage2 <= preset_stage1;
            d_stage2 <= d_stage1;
            valid_stage2 <= valid_stage1;
            
            // Output stage: Final computation
            if (valid_stage2)
                q <= preset_stage2 ? 1'b1 : d_stage2;
        end
    end

    // Output valid signal
    assign valid_out = valid_stage2;

endmodule