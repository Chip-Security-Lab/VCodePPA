//SystemVerilog
module onehot_sync_decoder (
    input wire clock,
    input wire valid,
    input wire [2:0] addr_in,
    output reg ready,
    output reg [7:0] decode_out
);
    // Barrel shifter implementation
    wire [7:0] barrel_shift;
    
    // First level: shift by 0 or 1
    wire [7:0] level1;
    assign level1 = addr_in[0] ? {barrel_shift[6:0], 1'b0} : barrel_shift;
    
    // Second level: shift by 0 or 2
    wire [7:0] level2;
    assign level2 = addr_in[1] ? {level1[5:0], 2'b0} : level1;
    
    // Third level: shift by 0 or 4
    wire [7:0] level3;
    assign level3 = addr_in[2] ? {level2[3:0], 4'b0} : level2;
    
    // Initial value is 1
    assign barrel_shift = 8'b00000001;
    
    // Register the output and ready signal
    always @(posedge clock) begin
        if (valid) begin
            decode_out <= level3;
            ready <= 1'b1;
        end else begin
            decode_out <= 8'b0;
            ready <= 1'b0;
        end
    end
endmodule