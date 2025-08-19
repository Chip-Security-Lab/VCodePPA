//SystemVerilog
//IEEE 1364-2005
module windowed_signal_recovery #(
    parameter DATA_WIDTH = 10,
    parameter WINDOW_SIZE = 5
)(
    input wire clk,
    input wire window_enable,
    input wire [DATA_WIDTH-1:0] signal_in,
    output reg [DATA_WIDTH-1:0] signal_out,
    output reg valid
);
    reg [DATA_WIDTH-1:0] window [0:WINDOW_SIZE-1];
    wire [DATA_WIDTH+3:0] sum;
    integer i;
    
    // Intermediate signals for CLA adder tree
    wire [DATA_WIDTH+3:0] partial_sum [0:WINDOW_SIZE-2];
    
    // CLA adder implementation for window summing
    cla_adder_tree #(
        .DATA_WIDTH(DATA_WIDTH),
        .WINDOW_SIZE(WINDOW_SIZE)
    ) cla_adder_inst (
        .window_data(window),
        .sum(sum)
    );
    
    always @(posedge clk) begin
        // Using conditional operators instead of if-else
        valid <= window_enable ? 1'b1 : 1'b0;
        
        if (window_enable) begin
            // Shift window values
            for (i = WINDOW_SIZE-1; i > 0; i = i-1)
                window[i] <= window[i-1];
            window[0] <= signal_in;
            
            // Calculate windowed average using the CLA-computed sum
            signal_out <= sum / WINDOW_SIZE;
        end
    end
endmodule

// Carry-Lookahead Adder Tree implementation for window summing
module cla_adder_tree #(
    parameter DATA_WIDTH = 10,
    parameter WINDOW_SIZE = 5
)(
    input [DATA_WIDTH-1:0] window_data [0:WINDOW_SIZE-1],
    output [DATA_WIDTH+3:0] sum
);
    wire [DATA_WIDTH+3:0] operands [0:WINDOW_SIZE-1];
    wire [DATA_WIDTH+3:0] intermediate_sums [0:WINDOW_SIZE-2];
    
    // Convert window data to wider bit width for summing
    genvar j;
    generate
        for (j = 0; j < WINDOW_SIZE; j = j + 1) begin: gen_operands
            assign operands[j] = {{(4){1'b0}}, window_data[j]};
        end
    endgenerate
    
    // First level addition
    cla_adder #(.WIDTH(DATA_WIDTH+4)) cla_first (
        .a(operands[0]),
        .b(operands[1]),
        .cin(1'b0),
        .sum(intermediate_sums[0])
    );
    
    // Build adder tree
    genvar i;
    generate
        for (i = 0; i < WINDOW_SIZE-2; i = i + 1) begin: gen_adders
            cla_adder #(.WIDTH(DATA_WIDTH+4)) cla_inst (
                .a(intermediate_sums[i]),
                .b(operands[i+2]),
                .cin(1'b0),
                .sum(intermediate_sums[i+1])
            );
        end
    endgenerate
    
    // Final sum
    assign sum = intermediate_sums[WINDOW_SIZE-2];
endmodule

// 10-bit Carry-Lookahead Adder
module cla_adder #(
    parameter WIDTH = 14
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output [WIDTH-1:0] sum
);
    wire [WIDTH-1:0] p, g; // Generate and propagate signals
    wire [WIDTH:0] c;       // Carry signals including initial carry
    
    // Initial carry in
    assign c[0] = cin;
    
    // Generate the propagate and generate signals
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_pg
            assign p[i] = a[i] ^ b[i];  // Propagate
            assign g[i] = a[i] & b[i];  // Generate
        end
    endgenerate
    
    // Carry-lookahead logic
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_carries
            assign c[i+1] = g[i] | (p[i] & c[i]);
        end
    endgenerate
    
    // Final sum calculation
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_sum
            assign sum[i] = p[i] ^ c[i];
        end
    endgenerate
endmodule