//SystemVerilog
module thermometer_to_binary #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] thermo_in,
    output reg [$clog2(WIDTH):0] binary_out
);

    wire [WIDTH-1:0] generate_term;
    wire [WIDTH-1:0] propagate_term;
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] sum;
    integer j;

    assign generate_term   = thermo_in;
    assign propagate_term  = thermo_in;

    assign carry[0] = 1'b0;

    // 8-bit carry lookahead adder logic for sum = sum of bits in thermo_in
    wire [WIDTH-1:0] group_generate;
    wire [WIDTH-1:0] group_propagate;

    // Group Generate and Propagate
    assign group_generate[0] = generate_term[0];
    assign group_propagate[0] = propagate_term[0];

    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : group_gen_prop
            assign group_generate[i] = generate_term[i] | (propagate_term[i] & group_generate[i-1]);
            assign group_propagate[i] = propagate_term[i] & group_propagate[i-1];
        end
    endgenerate

    // Carry calculation using lookahead logic
    assign carry[1] = generate_term[0] | (propagate_term[0] & carry[0]);
    assign carry[2] = generate_term[1] | (propagate_term[1] & carry[1]);
    assign carry[3] = generate_term[2] | (propagate_term[2] & carry[2]);
    assign carry[4] = generate_term[3] | (propagate_term[3] & carry[3]);
    assign carry[5] = generate_term[4] | (propagate_term[4] & carry[4]);
    assign carry[6] = generate_term[5] | (propagate_term[5] & carry[5]);
    assign carry[7] = generate_term[6] | (propagate_term[6] & carry[6]);
    assign carry[8] = generate_term[7] | (propagate_term[7] & carry[7]);

    // Sum calculation
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : sum_calc
            assign sum[i] = propagate_term[i] ^ carry[i];
        end
    endgenerate

    // Binary output calculation
    always @(*) begin
        binary_out = {($clog2(WIDTH)+1){1'b0}};
        for (j = 0; j < WIDTH; j = j + 1) begin
            binary_out = binary_out + sum[j];
        end
    end

endmodule