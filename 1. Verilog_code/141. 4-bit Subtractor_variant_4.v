module subtractor_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [3:0] res
);

// Pipeline registers
reg [3:0] a_reg, b_reg;
reg [3:0] b_inv_reg;
reg [3:0] sum_reg;

// Stage 1: Input registration
always @(*) begin
    a_reg = a;
    b_reg = b;
end

// Stage 2: Inversion and carry-in
always @(*) begin
    b_inv_reg = ~b_reg;
end

// Stage 3: Addition
wire [3:0] carry;
wire [3:0] sum;

// Optimized carry chain
assign carry[0] = (a_reg[0] & b_inv_reg[0]) | (a_reg[0] & 1'b1) | (b_inv_reg[0] & 1'b1);
assign sum[0] = a_reg[0] ^ b_inv_reg[0] ^ 1'b1;

assign carry[1] = (a_reg[1] & b_inv_reg[1]) | (a_reg[1] & carry[0]) | (b_inv_reg[1] & carry[0]);
assign sum[1] = a_reg[1] ^ b_inv_reg[1] ^ carry[0];

assign carry[2] = (a_reg[2] & b_inv_reg[2]) | (a_reg[2] & carry[1]) | (b_inv_reg[2] & carry[1]);
assign sum[2] = a_reg[2] ^ b_inv_reg[2] ^ carry[1];

assign carry[3] = (a_reg[3] & b_inv_reg[3]) | (a_reg[3] & carry[2]) | (b_inv_reg[3] & carry[2]);
assign sum[3] = a_reg[3] ^ b_inv_reg[3] ^ carry[2];

// Stage 4: Output registration
always @(*) begin
    sum_reg = sum;
end

assign res = sum_reg;

endmodule