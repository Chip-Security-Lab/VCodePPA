//SystemVerilog
module direction_ring_counter(
    input wire clk,
    input wire rst,
    input wire dir_sel, // Direction select
    output reg [3:0] q_out
);
    // Pipeline stage 1 - Direction selection buffering
    reg dir_sel_stage1;
    
    // Pipeline stage 2 - Direction processing
    reg dir_sel_stage2;
    
    // Pipeline stage 3 - Direction application
    reg dir_sel_stage3;
    reg [3:0] q_intermediate_stage3;
    
    // Pipeline stage 4 - Result preparation
    reg [3:0] q_out_stage4;
    
    always @(posedge clk) begin
        if (rst) begin
            // Reset all pipeline registers
            dir_sel_stage1 <= 1'b0;
            dir_sel_stage2 <= 1'b0;
            dir_sel_stage3 <= 1'b0;
            q_intermediate_stage3 <= 4'b0001;
            q_out_stage4 <= 4'b0001;
            q_out <= 4'b0001;
        end else begin
            // Pipeline stage 1 - Input capture
            dir_sel_stage1 <= dir_sel;
            
            // Pipeline stage 2 - Direction processing
            dir_sel_stage2 <= dir_sel_stage1;
            
            // Pipeline stage 3 - Calculate shift pattern
            dir_sel_stage3 <= dir_sel_stage2;
            if (dir_sel_stage2)
                q_intermediate_stage3 <= {q_out[0], q_out[3:1]}; // Shift right
            else
                q_intermediate_stage3 <= {q_out[2:0], q_out[3]}; // Shift left
            
            // Pipeline stage 4 - Prepare final output
            q_out_stage4 <= q_intermediate_stage3;
            
            // Final output register
            q_out <= q_out_stage4;
        end
    end
endmodule