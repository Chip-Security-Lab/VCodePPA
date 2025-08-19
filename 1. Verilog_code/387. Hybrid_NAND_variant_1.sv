//SystemVerilog
//IEEE 1364-2005 Verilog standard
module Hybrid_NAND(
    input wire [1:0] ctrl,
    input wire [7:0] base,
    output wire [7:0] res
);
    // Pipeline stage 1: Mask Generation
    reg [7:0] mask_stage1;
    reg [7:0] base_stage1;
    
    always @(*) begin
        case (ctrl)
            2'b00: mask_stage1 = 8'h0F; // Lower nibble mask
            2'b01: mask_stage1 = 8'hF0; // Upper nibble mask
            2'b10: mask_stage1 = 8'hFF; // Full byte mask
            2'b11: mask_stage1 = 8'h00; // No mask
            default: mask_stage1 = 8'h00;
        endcase
        base_stage1 = base;
    end
    
    // Pipeline stage 2: AND Operation
    wire [7:0] and_result_stage2;
    assign and_result_stage2 = base_stage1 & mask_stage1;
    
    // Pipeline stage 3: NAND Output
    assign res = ~and_result_stage2;
endmodule