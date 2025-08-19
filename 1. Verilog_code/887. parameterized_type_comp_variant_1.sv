//SystemVerilog
module parameterized_type_comp #(
    parameter WIDTH = 8,
    parameter DATA_WIDTH = 8
)(
    input clk, rst_n,
    input [DATA_WIDTH-1:0] inputs [0:WIDTH-1],
    output reg [$clog2(WIDTH)-1:0] max_idx,
    output reg valid
);

    // Generate and propagate signals for parallel prefix
    wire [WIDTH-1:0] g [0:$clog2(WIDTH)];
    wire [WIDTH-1:0] p [0:$clog2(WIDTH)];
    
    // Initialize first level
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_init
            assign g[0][i] = (i > 0) ? (inputs[i] > inputs[0]) : 1'b0;
            assign p[0][i] = (i > 0) ? (inputs[i] == inputs[0]) : 1'b1;
        end
    endgenerate

    // Parallel prefix computation
    genvar k;
    generate
        for (k = 1; k <= $clog2(WIDTH); k = k + 1) begin : gen_prefix
            for (i = 0; i < WIDTH; i = i + 1) begin : gen_level
                wire [WIDTH-1:0] mask = (1 << k) - 1;
                wire [WIDTH-1:0] shift = 1 << (k-1);
                
                assign g[k][i] = g[k-1][i] | (p[k-1][i] & g[k-1][i & ~mask | shift]);
                assign p[k][i] = p[k-1][i] & p[k-1][i & ~mask | shift];
            end
        end
    endgenerate

    // Final comparison and index selection
    wire [WIDTH-1:0] max_flags;
    assign max_flags = g[$clog2(WIDTH)];

    // Priority encoder for max index
    reg [$clog2(WIDTH)-1:0] max_idx_next;
    integer j;
    always @(*) begin
        max_idx_next = 0;
        for (j = 0; j < WIDTH; j = j + 1) begin
            if (max_flags[j])
                max_idx_next = j[$clog2(WIDTH)-1:0];
        end
    end

    // Output registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            max_idx <= 0;
            valid <= 0;
        end else begin
            max_idx <= max_idx_next;
            valid <= 1;
        end
    end

endmodule