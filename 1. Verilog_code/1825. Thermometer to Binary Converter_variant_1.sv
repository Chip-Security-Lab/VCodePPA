//SystemVerilog
module therm2bin_converter #(parameter THERM_WIDTH = 7) (
    input  wire [THERM_WIDTH-1:0] therm_code,
    output wire [$clog2(THERM_WIDTH+1)-1:0] bin_code
);

    // Kogge-Stone adder implementation
    wire [THERM_WIDTH-1:0] g [0:3];
    wire [THERM_WIDTH-1:0] p [0:3];
    wire [THERM_WIDTH-1:0] sum;

    // Generate and Propagate computation
    genvar i;
    generate
        for (i = 0; i < THERM_WIDTH; i = i + 1) begin : gen_gp
            assign g[0][i] = therm_code[i];
            assign p[0][i] = therm_code[i];
        end
    endgenerate

    // Kogge-Stone prefix computation
    // Stage 1
    assign g[1][0] = g[0][0];
    assign p[1][0] = p[0][0];
    generate
        for (i = 1; i < THERM_WIDTH; i = i + 1) begin : stage1
            assign g[1][i] = g[0][i] | (p[0][i] & g[0][i-1]);
            assign p[1][i] = p[0][i] & p[0][i-1];
        end
    endgenerate

    // Stage 2
    assign g[2][0] = g[1][0];
    assign p[2][0] = p[1][0];
    assign g[2][1] = g[1][1];
    assign p[2][1] = p[1][1];
    generate
        for (i = 2; i < THERM_WIDTH; i = i + 1) begin : stage2
            assign g[2][i] = g[1][i] | (p[1][i] & g[1][i-2]);
            assign p[2][i] = p[1][i] & p[1][i-2];
        end
    endgenerate

    // Stage 3
    assign g[3][0] = g[2][0];
    assign p[3][0] = p[2][0];
    assign g[3][1] = g[2][1];
    assign p[3][1] = p[2][1];
    assign g[3][2] = g[2][2];
    assign p[3][2] = p[2][2];
    assign g[3][3] = g[2][3];
    assign p[3][3] = p[2][3];
    generate
        for (i = 4; i < THERM_WIDTH; i = i + 1) begin : stage3
            assign g[3][i] = g[2][i] | (p[2][i] & g[2][i-4]);
            assign p[3][i] = p[2][i] & p[2][i-4];
        end
    endgenerate

    // Sum computation
    assign sum[0] = g[0][0];
    generate
        for (i = 1; i < THERM_WIDTH; i = i + 1) begin : sum_gen
            assign sum[i] = g[0][i] ^ g[3][i-1];
        end
    endgenerate

    // Output assignment
    assign bin_code = sum[THERM_WIDTH-1:0];

endmodule