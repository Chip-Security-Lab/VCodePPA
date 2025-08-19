//SystemVerilog
module async_binary_priority_comp #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_vector,
    output [$clog2(WIDTH)-1:0] encoded_output,
    output valid_output
);
    // Combinational logic for binary encoding
    reg [$clog2(WIDTH)-1:0] encoder_out;
    wire [$clog2(WIDTH)-1:0] ks_adder_result;
    integer idx;
    
    always @(*) begin
        encoder_out = 0;
        for (idx = 0; idx < WIDTH; idx = idx + 1)
            if (data_vector[idx]) encoder_out = idx[$clog2(WIDTH)-1:0];
    end
    
    // Instantiate Kogge-Stone adder to process the output
    kogge_stone_adder #(
        .WIDTH($clog2(WIDTH))
    ) ks_adder (
        .a(encoder_out),
        .b({{($clog2(WIDTH)-1){1'b0}}, valid_output}),
        .sum(ks_adder_result)
    );
    
    assign encoded_output = ks_adder_result;
    assign valid_output = |data_vector;
endmodule

// Kogge-Stone 8-bit Adder Implementation
module kogge_stone_adder #(parameter WIDTH = 3)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] sum
);
    // Generate and Propagate signals
    wire [WIDTH-1:0] p;  // Propagate
    wire [WIDTH-1:0] g;  // Generate
    
    // Stage signals for Kogge-Stone algorithm
    wire [WIDTH-1:0] p_stage[0:$clog2(WIDTH)-1];
    wire [WIDTH-1:0] g_stage[0:$clog2(WIDTH)-1];
    
    // Initial Propagate and Generate calculation
    assign p = a ^ b;  // Propagate = a XOR b
    assign g = a & b;  // Generate = a AND b
    
    // Initialize the first stage
    assign p_stage[0] = p;
    assign g_stage[0] = g;
    
    // Generate the carry chain using Kogge-Stone algorithm
    genvar i, j;
    generate
        for (i = 1; i <= $clog2(WIDTH)-1; i = i + 1) begin : KS_STAGES
            for (j = 0; j < WIDTH; j = j + 1) begin : KS_BITS
                if (j >= (1 << (i-1))) begin
                    assign g_stage[i][j] = g_stage[i-1][j] | (p_stage[i-1][j] & g_stage[i-1][j-(1<<(i-1))]);
                    assign p_stage[i][j] = p_stage[i-1][j] & p_stage[i-1][j-(1<<(i-1))];
                end else begin
                    assign g_stage[i][j] = g_stage[i-1][j];
                    assign p_stage[i][j] = p_stage[i-1][j];
                end
            end
        end
    endgenerate
    
    // Calculate final sum
    wire [WIDTH-1:0] carry;
    assign carry[0] = 1'b0;  // No carry input for the LSB
    
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : CARRY_CALC
            assign carry[i] = g_stage[$clog2(WIDTH)-1][i-1];
        end
    endgenerate
    
    // Sum = a XOR b XOR carry
    assign sum = p ^ {carry[WIDTH-1:1], 1'b0};
endmodule