module dram_bank_conflict #(
    parameter NUM_BANKS = 8,
    parameter BANK_BITS = 3
)(
    input clk,
    input [BANK_BITS-1:0] current_bank,
    input [BANK_BITS-1:0] new_bank,
    input precharge,  // Added missing precharge input
    output reg conflict
);
    reg [NUM_BANKS-1:0] active_banks;
    
    always @(posedge clk) begin
        conflict <= active_banks[new_bank];
        active_banks[current_bank] <= 1'b1; // Mark current bank as active
    end
    
    // Precharge logic
    always @(posedge clk) begin
        if(precharge) 
            active_banks <= {NUM_BANKS{1'b0}};
    end
endmodule