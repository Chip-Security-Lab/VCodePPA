//SystemVerilog
module rom_lookup #(parameter N=4)(
    input [N-1:0] x,
    output reg [2**N-1:0] y
);
    wire [2**N-1:0] barrel_out;
    wire [N-1:0] shift_amount;
    wire valid;
    
    // Check if x is valid for shifting (x < N)
    assign valid = (x < N) ? 1'b1 : 1'b0;
    assign shift_amount = x;
    
    // Implement barrel shifter structure with one-hot base value
    // Starting with 1 at position 0
    wire [2**N-1:0] base_value = {{(2**N-1){1'b0}}, 1'b1};
    
    // Barrel shifter implementation
    // Level 0: Shift by 1 bit if shift_amount[0] is 1
    wire [2**N-1:0] level0 = shift_amount[0] ? {base_value[2**N-2:0], base_value[2**N-1]} : base_value;
    
    // Level 1: Shift by 2 bits if shift_amount[1] is 1
    wire [2**N-1:0] level1 = shift_amount[1] ? {level0[2**N-3:0], level0[2**N-1:2**N-2]} : level0;
    
    // Level 2: Shift by 4 bits if shift_amount[2] is 1
    wire [2**N-1:0] level2 = (N > 2 && shift_amount[2]) ? {level1[2**N-5:0], level1[2**N-1:2**N-4]} : level1;
    
    // Level 3: Shift by 8 bits if shift_amount[3] is 1
    wire [2**N-1:0] level3 = (N > 3 && shift_amount[3]) ? {level2[2**N-9:0], level2[2**N-1:2**N-8]} : level2;
    
    // Additional levels would be added for N > 4
    
    // Final output (use level3 for N=4, or adapt for other N values)
    assign barrel_out = (N <= 3) ? level2 : level3;
    
    always @(*) begin
        y = valid ? barrel_out : {(2**N){1'b0}};
    end
endmodule