//SystemVerilog
module ICMU_JTAGDebug #(
    parameter DW = 32
)(
    input tck,
    input tms,
    input tdi,
    output tdo,
    input [DW-1:0] ctx_data,
    output reg [DW-1:0] debug_out
);
    // Pipeline stage 1: Input capture
    reg tms_reg;
    reg tdi_reg;
    
    // Pipeline stage 2: Shift register and TAP state
    reg [DW-1:0] shift_reg_stage1;
    reg [2:0] tap_state_stage1;
    
    // Pipeline stage 3: Data processing
    reg [DW-1:0] shift_reg_stage2;
    reg [2:0] tap_state_stage2;
    reg [DW-1:0] debug_out_stage2;
    
    // Pipeline stage 4: Output
    reg [DW-1:0] debug_out_stage3;
    
    // Stage 1: Input capture
    always @(posedge tck) begin
        tms_reg <= tms;
        tdi_reg <= tdi;
    end
    
    // Stage 2: Shift register and TAP state
    always @(posedge tck) begin
        shift_reg_stage1 <= {tdi_reg, shift_reg_stage1[DW-1:1]};
        
        case(tap_state_stage1)
            3'h0: tap_state_stage1 <= (!tms_reg) ? 3'h1 : 3'h0;
            3'h1: tap_state_stage1 <= (tms_reg) ? 3'h4 : 3'h1;
            3'h4: tap_state_stage1 <= 3'h0;
            default: tap_state_stage1 <= 3'h0;
        endcase
    end
    
    // Stage 3: Process data and prepare output
    always @(posedge tck) begin
        shift_reg_stage2 <= shift_reg_stage1;
        tap_state_stage2 <= tap_state_stage1;
        
        if (tap_state_stage1 == 3'h4) begin
            debug_out_stage2 <= shift_reg_stage1;
        end
    end
    
    // Stage 4: Final output
    always @(posedge tck) begin
        debug_out_stage3 <= debug_out_stage2;
        debug_out <= debug_out_stage3;
    end
    
    assign tdo = shift_reg_stage1[0];
endmodule