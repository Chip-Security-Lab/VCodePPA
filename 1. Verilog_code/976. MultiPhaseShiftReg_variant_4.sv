//SystemVerilog
module MultiPhaseShiftReg #(parameter PHASES=4, WIDTH=8) (
    input [PHASES-1:0] phase_clk,
    input serial_in,
    output [PHASES-1:0] phase_out
);

    // Input synchronization registers for better timing
    reg serial_in_meta, serial_in_sync;
    reg [PHASES-1:0] phase_clk_meta, phase_clk_sync;
    
    // Two-stage synchronization to prevent metastability
    always @(posedge phase_clk[0]) begin
        serial_in_meta <= serial_in;
        serial_in_sync <= serial_in_meta;
        
        phase_clk_meta <= phase_clk;
        phase_clk_sync <= phase_clk_meta;
    end
    
    // Pipeline stage for input processing
    reg serial_in_pipe;
    always @(posedge phase_clk[0]) begin
        serial_in_pipe <= serial_in_sync;
    end
    
    genvar i;
    generate
        for(i=0; i<PHASES; i=i+1) begin : phase_shift_regs
            // Split the shift register into two pipeline stages to reduce critical path
            reg [WIDTH/2-1:0] shift_reg_stage1;
            reg [WIDTH/2-1:0] shift_reg_stage2;
            reg pipeline_bit; // Intermediate pipeline register
            reg output_bit;
            
            // First pipeline stage
            always @(posedge phase_clk_sync[i]) begin
                shift_reg_stage1 <= {shift_reg_stage1[WIDTH/2-2:0], serial_in_pipe};
                pipeline_bit <= shift_reg_stage1[WIDTH/2-1];
            end
            
            // Second pipeline stage with reduced critical path
            always @(posedge phase_clk_sync[i]) begin
                shift_reg_stage2 <= {shift_reg_stage2[WIDTH/2-2:0], pipeline_bit};
                output_bit <= shift_reg_stage2[WIDTH/2-1];
            end
            
            // Output assignment
            assign phase_out[i] = output_bit;
        end
    endgenerate
endmodule