//SystemVerilog
module RangeDetector_AsyncMultiZone #(
    parameter ZONES = 4,
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] bounds [ZONES*2-1:0],
    output [ZONES-1:0] zone_flags
);

wire [WIDTH-1:0] lower_diff [ZONES-1:0];
wire [WIDTH-1:0] upper_diff [ZONES-1:0];
wire [ZONES-1:0] lower_flags, upper_flags;

// Generate comparison flags using Han-Carlson adder for subtraction
generate
genvar i;
for(i=0; i<ZONES; i=i+1) begin : gen_comparisons
    // Lower bound check: data_in >= bounds[2*i]
    // Compute data_in - bounds[2*i] and check if result is non-negative
    HanCarlsonAdder #(.WIDTH(WIDTH)) lower_adder (
        .a(data_in),
        .b(~bounds[2*i]),
        .cin(1'b1),  // Add 1 for two's complement
        .sum(lower_diff[i])
    );
    assign lower_flags[i] = ~lower_diff[i][WIDTH-1]; // Not negative = greater or equal
    
    // Upper bound check: data_in <= bounds[2*i+1]
    // Compute bounds[2*i+1] - data_in and check if result is non-negative
    HanCarlsonAdder #(.WIDTH(WIDTH)) upper_adder (
        .a(bounds[2*i+1]),
        .b(~data_in),
        .cin(1'b1),  // Add 1 for two's complement
        .sum(upper_diff[i])
    );
    assign upper_flags[i] = ~upper_diff[i][WIDTH-1]; // Not negative = greater or equal
    
    // Final zone flag
    assign zone_flags[i] = lower_flags[i] & upper_flags[i];
end
endgenerate

endmodule

// Optimized Han-Carlson Parallel Prefix Adder with barrel shifter
module HanCarlsonAdder #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output [WIDTH-1:0] sum
);

    // Generate and Propagate signals
    wire [WIDTH-1:0] g, p;
    wire [WIDTH:0] c;
    
    // Initial Generate and Propagate
    assign g = a & b;
    assign p = a ^ b;
    assign c[0] = cin;
    
    // Han-Carlson specific wires
    wire [WIDTH/2-1:0] g_even, p_even;
    wire [WIDTH/2-1:0] g_odd, p_odd;
    
    // Step 1: Split into even and odd bits
    genvar i, j, k;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_split
            if (i % 2 == 0) begin
                assign g_even[i/2] = g[i];
                assign p_even[i/2] = p[i];
            end else begin
                assign g_odd[(i-1)/2] = g[i];
                assign p_odd[(i-1)/2] = p[i];
            end
        end
        
        // Step 2: Process even bits using barrel shifter structure
        wire [WIDTH/2-1:0] g_stages [log2(WIDTH/2)+1:0];
        wire [WIDTH/2-1:0] p_stages [log2(WIDTH/2)+1:0];
        
        // Initialize first stage
        assign g_stages[0] = g_even;
        assign p_stages[0] = p_even;
        
        // Barrel shifter architecture for prefix computation
        for (j = 0; j < log2(WIDTH/2); j = j + 1) begin : barrel_stages
            localparam shift_amount = 2**j;
            
            for (k = 0; k < WIDTH/2; k = k + 1) begin : barrel_cells
                // For each bit position, determine result based on shift amount
                if (k >= shift_amount) begin
                    // Combine with shifted value
                    assign g_stages[j+1][k] = g_stages[j][k] | (p_stages[j][k] & g_stages[j][k-shift_amount]);
                    assign p_stages[j+1][k] = p_stages[j][k] & p_stages[j][k-shift_amount];
                end else begin
                    // Pass through for positions that don't have predecessors at this stage
                    assign g_stages[j+1][k] = g_stages[j][k];
                    assign p_stages[j+1][k] = p_stages[j][k];
                end
            end
        end
        
        // Step 3: Generate carries for even bits using final stage outputs
        for (i = 0; i < WIDTH/2; i = i + 1) begin : carry_even
            assign c[i*2+1] = g_stages[log2(WIDTH/2)][i] | (p_stages[log2(WIDTH/2)][i] & c[0]);
        end
        
        // Step 4: Generate carries for odd bits
        for (i = 0; i < WIDTH/2; i = i + 1) begin : carry_odd
            assign c[i*2+2] = g_odd[i] | (p_odd[i] & c[i*2+1]);
        end
        
        // Final sum computation
        for (i = 0; i < WIDTH; i = i + 1) begin : sum_compute
            assign sum[i] = p[i] ^ c[i];
        end
    endgenerate

    // Function to compute log2 (ceiling)
    function integer log2;
        input integer value;
        integer temp;
        begin
            temp = value - 1;
            for (log2 = 0; temp > 0; log2 = log2 + 1) begin
                temp = temp >> 1;
            end
        end
    endfunction

endmodule