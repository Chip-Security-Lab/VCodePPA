//SystemVerilog
module dram_bank_conflict #(
    parameter NUM_BANKS = 8,
    parameter BANK_BITS = 3
)(
    input clk,
    input [BANK_BITS-1:0] current_bank,
    input [BANK_BITS-1:0] new_bank,
    input precharge,
    output reg conflict
);

    reg [NUM_BANKS-1:0] active_banks;
    wire [NUM_BANKS-1:0] next_active_banks;
    
    // Optimized bank activation logic
    assign next_active_banks = precharge ? {NUM_BANKS{1'b0}} : 
                             (active_banks | (1'b1 << current_bank));
    
    // Optimized conflict detection
    always @(posedge clk) begin
        active_banks <= next_active_banks;
        conflict <= next_active_banks[new_bank];
    end

endmodule