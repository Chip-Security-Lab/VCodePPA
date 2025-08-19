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
    reg [NUM_BANKS-1:0] active_banks_next;
    
    // Optimized conflict detection using bitwise operations
    always @(*) begin
        // Direct conflict check using bitwise AND
        conflict = |(active_banks & ~(1'b1 << new_bank));
    end
    
    // Update active banks on clock edge
    always @(posedge clk) begin
        if (precharge) begin
            active_banks <= {NUM_BANKS{1'b0}};
        end else begin
            active_banks[current_bank] <= 1'b1;
        end
    end
endmodule