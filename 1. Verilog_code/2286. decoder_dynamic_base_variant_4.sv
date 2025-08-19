//SystemVerilog
module decoder_dynamic_base (
    input [7:0] base_addr,
    input [7:0] current_addr,
    output reg sel
);
    wire [7:0] comparison_result;
    wire [3:0] addr_upper_nibble_a;
    wire [3:0] addr_upper_nibble_b;
    
    assign addr_upper_nibble_a = current_addr[7:4];
    assign addr_upper_nibble_b = base_addr[7:4];
    
    booth_multiplier booth_compare (
        .a(addr_upper_nibble_a),
        .b(addr_upper_nibble_b),
        .product(comparison_result)
    );
    
    always @(*) begin
        // If upper nibbles match, their XOR will be 0
        // Using booth multiplier output for comparison
        sel = (comparison_result[7:4] == addr_upper_nibble_a) ? 1'b1 : 1'b0;
    end
endmodule

module booth_multiplier (
    input [3:0] a,
    input [3:0] b,
    output [7:0] product
);
    reg [7:0] product_reg;
    reg [8:0] A, S, P;
    integer i;
    
    always @(*) begin
        // Initialize registers
        A = {a, 5'b00000};
        S = {(~a + 1'b1), 5'b00000}; // 2's complement of a
        P = {4'b0000, b, 1'b0};
        
        // Booth algorithm implementation
        for (i = 0; i < 4; i = i + 1) begin
            case (P[1:0])
                2'b01: P = P + A;  // Add A
                2'b10: P = P + S;  // Add S (which is -A)
                default: P = P;    // Do nothing for 00 or 11
            endcase
            
            // Arithmetic right shift
            P = {P[8], P[8:1]};
        end
        
        // Final product
        product_reg = P[8:1];
    end
    
    assign product = product_reg;
endmodule