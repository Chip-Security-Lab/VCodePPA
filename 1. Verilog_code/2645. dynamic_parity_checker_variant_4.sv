//SystemVerilog
module dynamic_parity_checker #(
    parameter MAX_WIDTH = 64
)(
    input [$clog2(MAX_WIDTH)-1:0] width,
    input [MAX_WIDTH-1:0] data,
    output parity
);

// Pipeline stage 1: Input processing
wire [MAX_WIDTH-1:0] propagate_data;
wire [MAX_WIDTH-1:0] generate_data;
reg [MAX_WIDTH-1:0] stage1_propagate;
reg [MAX_WIDTH-1:0] stage1_generate;

assign propagate_data = data;
assign generate_data = {data[MAX_WIDTH-1], data[MAX_WIDTH-1:1]};

always @(*) begin
    stage1_propagate = propagate_data;
    stage1_generate = generate_data;
end

// Pipeline stage 2: Carry computation
wire [MAX_WIDTH:0] carry_chain;
reg [MAX_WIDTH:0] stage2_carry;

assign carry_chain[0] = 1'b0;
genvar i;
generate
    for (i = 0; i < MAX_WIDTH; i = i + 1) begin : carry_gen
        assign carry_chain[i + 1] = stage1_generate[i] | (stage1_propagate[i] & carry_chain[i]);
    end
endgenerate

always @(*) begin
    stage2_carry = carry_chain;
end

// Pipeline stage 3: Parity calculation
wire [MAX_WIDTH-1:0] parity_bits;
reg [MAX_WIDTH-1:0] stage3_parity;

generate
    for (i = 0; i < MAX_WIDTH; i = i + 1) begin : parity_calc
        assign parity_bits[i] = stage1_propagate[i] ^ stage2_carry[i];
    end
endgenerate

always @(*) begin
    stage3_parity = parity_bits;
end

// Output stage
reg final_parity;
always @(*) begin
    final_parity = stage3_parity[MAX_WIDTH - 1];
end

assign parity = final_parity;

endmodule