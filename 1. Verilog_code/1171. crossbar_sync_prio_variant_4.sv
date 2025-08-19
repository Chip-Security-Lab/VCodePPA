//SystemVerilog
module crossbar_sync_prio #(parameter DW=8, N=4) (
    input clk, rst_n, en,
    input [(DW*N)-1:0] din,
    input [(N*2)-1:0] dest,
    output reg [(DW*N)-1:0] dout
);
    // Break out the destination indices
    wire [1:0] dest_indices[0:N-1];
    wire [1:0] mult_results[0:N-1];
    reg [1:0] adjusted_dest_indices[0:N-1];
    
    genvar i;
    generate
        for(i=0; i<N; i=i+1) begin : gen_dest
            assign dest_indices[i] = dest[(i*2+1):(i*2)];
            
            // Instantiate Dadda multiplier for each destination index
            dadda_multiplier dadda_mult_inst (
                .a(dest_indices[i]),
                .b(2'b11),  // Multiply by constant 3 for demonstration
                .p(mult_results[i])
            );
        end
    endgenerate
    
    // Compute adjusted indices once
    always @(*) begin
        for(integer j=0; j<N; j=j+1) begin
            adjusted_dest_indices[j] = (dest_indices[j] + mult_results[j]) % N;
        end
    end
    
    // Synchronous reset implementation with case-based structure
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            dout <= {(DW*N){1'b0}};
        end else begin
            case(en)
                1'b1: begin
                    // Use case statement for output port 0
                    case(adjusted_dest_indices[0])
                        2'b00: dout[DW-1:0] <= din[0 +: DW];
                        2'b01: dout[DW-1:0] <= din[DW +: DW];
                        2'b10: dout[DW-1:0] <= din[2*DW +: DW];
                        2'b11: dout[DW-1:0] <= din[3*DW +: DW];
                    endcase
                    
                    // Use case statement for output port 1
                    case(adjusted_dest_indices[1])
                        2'b00: dout[(2*DW)-1:DW] <= din[0 +: DW];
                        2'b01: dout[(2*DW)-1:DW] <= din[DW +: DW];
                        2'b10: dout[(2*DW)-1:DW] <= din[2*DW +: DW];
                        2'b11: dout[(2*DW)-1:DW] <= din[3*DW +: DW];
                    endcase
                    
                    // Use case statement for output port 2
                    case(adjusted_dest_indices[2])
                        2'b00: dout[(3*DW)-1:(2*DW)] <= din[0 +: DW];
                        2'b01: dout[(3*DW)-1:(2*DW)] <= din[DW +: DW];
                        2'b10: dout[(3*DW)-1:(2*DW)] <= din[2*DW +: DW];
                        2'b11: dout[(3*DW)-1:(2*DW)] <= din[3*DW +: DW];
                    endcase
                    
                    // Use case statement for output port 3
                    case(adjusted_dest_indices[3])
                        2'b00: dout[(4*DW)-1:(3*DW)] <= din[0 +: DW];
                        2'b01: dout[(4*DW)-1:(3*DW)] <= din[DW +: DW];
                        2'b10: dout[(4*DW)-1:(3*DW)] <= din[2*DW +: DW];
                        2'b11: dout[(4*DW)-1:(3*DW)] <= din[3*DW +: DW];
                    endcase
                end
                
                default: begin
                    // When enable is not active, maintain current values
                    dout <= dout;
                end
            endcase
        end
    end
endmodule

// 4-bit Dadda Multiplier
module dadda_multiplier (
    input [1:0] a,
    input [1:0] b,
    output [3:0] p
);
    // Partial product generation
    wire [1:0] pp0, pp1;
    
    // Generate partial products
    assign pp0 = a & {2{b[0]}};
    assign pp1 = a & {2{b[1]}};
    
    // For 2x2 multiplication, the Dadda tree has a simple structure
    // First stage of Dadda reduction
    
    // First bit of result is just the first bit of first partial product
    assign p[0] = pp0[0];
    
    // Second bit uses half adder for pp0[1] and pp1[0]
    wire s1, c1;
    half_adder ha1(
        .a(pp0[1]),
        .b(pp1[0]),
        .sum(s1),
        .carry(c1)
    );
    assign p[1] = s1;
    
    // Third bit uses half adder for pp1[1] and carry from previous addition
    wire s2, c2;
    half_adder ha2(
        .a(pp1[1]),
        .b(c1),
        .sum(s2),
        .carry(c2)
    );
    assign p[2] = s2;
    
    // Fourth bit is just the carry from the last addition
    assign p[3] = c2;
endmodule

// Half Adder module
module half_adder (
    input a, b,
    output sum, carry
);
    assign sum = a ^ b;
    assign carry = a & b;
endmodule

// Full Adder module - for Dadda tree typically requires full adders
module full_adder (
    input a, b, cin,
    output sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule