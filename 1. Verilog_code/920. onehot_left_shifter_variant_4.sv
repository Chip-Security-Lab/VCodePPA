//SystemVerilog
module onehot_left_shifter #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] in_data,
    input [WIDTH-1:0] one_hot_control, // One-hot encoded shift amount
    output [WIDTH-1:0] out_data
);
    wire [WIDTH-1:0] shift_result;
    wire [WIDTH-1:0] shift_amount;
    
    // Convert one-hot to binary (log2 representation of shift amount)
    onehot_to_binary #(.WIDTH(WIDTH)) oh2bin (
        .one_hot(one_hot_control),
        .binary(shift_amount)
    );
    
    // Perform shifting using Han-Carlson based shifter
    hc_shifter #(.WIDTH(WIDTH)) shifter (
        .in_data(in_data),
        .shift_amount(shift_amount),
        .out_data(shift_result)
    );
    
    assign out_data = shift_result;
endmodule

module onehot_to_binary #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] one_hot,
    output [$clog2(WIDTH)-1:0] binary
);
    reg [$clog2(WIDTH)-1:0] bin_value;
    integer i;
    
    always @(*) begin
        bin_value = {$clog2(WIDTH){1'b0}};
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (one_hot[i])
                bin_value = bin_value | i[$clog2(WIDTH)-1:0];
        end
    end
    
    assign binary = bin_value;
endmodule

module hc_shifter #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] in_data,
    input [$clog2(WIDTH)-1:0] shift_amount,
    output [WIDTH-1:0] out_data
);
    reg [WIDTH-1:0] result;
    integer i;
    
    // Barrel shifter implementation (more efficient than iterative shifting)
    always @(*) begin
        result = in_data;
        for (i = 0; i < $clog2(WIDTH); i = i + 1) begin
            if (shift_amount[i])
                result = result << (1 << i);
        end
    end
    
    assign out_data = result;
endmodule

module han_carlson_adder #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output [WIDTH-1:0] sum,
    output cout
);
    // Generate and Propagate signals
    wire [WIDTH-1:0] g, p;
    wire [WIDTH-1:0] g_prev, p_prev;
    
    // Stage 1: Generate P and G signals
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_pg
            assign p[i] = a[i] ^ b[i];
            assign g[i] = a[i] & b[i];
        end
    endgenerate
    
    // Carry chain using Han-Carlson parallel prefix structure
    // Group size of 2 (even-odd pattern)
    wire [WIDTH:0] c;  // Carry signals
    assign c[0] = cin;
    
    // Even indexed preprocessing
    generate
        for (i = 0; i < WIDTH; i = i + 2) begin : even_preprocess
            assign g_prev[i] = g[i];
            assign p_prev[i] = p[i];
        end
    endgenerate
    
    // Log2(WIDTH) stages of the Han-Carlson prefix tree
    generate
        // First stage (odd indices)
        for (i = 1; i < WIDTH; i = i + 2) begin : odd_indices_stage1
            assign g_prev[i] = g[i] | (p[i] & g[i-1]);
            assign p_prev[i] = p[i] & p[i-1];
        end
        
        // Remaining stages
        genvar j, k;
        for (j = 1; j <= $clog2(WIDTH); j = j + 1) begin : hc_stages
            wire [WIDTH-1:0] g_stage, p_stage;
            
            // Preprocessing for this stage
            for (k = 0; k < WIDTH; k = k + 1) begin : prep_stage
                if (k < (1 << (j-1))) begin
                    assign g_stage[k] = g_prev[k];
                    assign p_stage[k] = p_prev[k];
                end
                else begin
                    assign g_stage[k] = g_prev[k] | (p_prev[k] & g_prev[k-(1<<(j-1))]);
                    assign p_stage[k] = p_prev[k] & p_prev[k-(1<<(j-1))];
                end
            end
            
            // Update for next stage
            for (k = 0; k < WIDTH; k = k + 1) begin : update_stage
                assign g_prev[k] = g_stage[k];
                assign p_prev[k] = p_stage[k];
            end
        end
    endgenerate
    
    // Post-processing to generate carries
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_carry
            if (i == 0)
                assign c[i+1] = g[i] | (p[i] & cin);
            else
                assign c[i+1] = g_prev[i];
        end
    endgenerate
    
    // Final sum calculation
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_sum
            assign sum[i] = p[i] ^ c[i];
        end
    endgenerate
    
    assign cout = c[WIDTH];
endmodule