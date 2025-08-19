//SystemVerilog
module block_fp #(
    parameter N = 4,
    parameter W = 16
)(
    input  [W-1:0] in_array [0:N-1],
    output [W+3:0] out_array [0:N-1],
    output [3:0]   exp
);

    // Optimized log2 calculation function: priority encoder
    function [3:0] log2_encoder;
        input [W-1:0] value;
        integer idx;
        begin
            log2_encoder = 0;
            for (idx = W-1; idx >= 0; idx = idx - 1) begin : log2_loop
                if (value[idx]) begin
                    log2_encoder = idx[3:0];
                    disable log2_loop;
                end
            end
        end
    endfunction

    reg [3:0] log2_val [0:N-1];
    reg [3:0] max_log2;
    integer i;

    // Calculate log2 for each input using the optimized encoder
    always @(*) begin
        for (i = 0; i < N; i = i + 1) begin
            log2_val[i] = log2_encoder(in_array[i]);
        end
    end

    // Efficient maximum search using pairwise comparison tree
    reg [3:0] stage1 [0:((N+1)/2)-1];
    reg [3:0] stage2 [0:((N+3)/4)-1];
    integer j;

    always @(*) begin
        // Stage 1: Pairwise compare
        for (j = 0; j < N/2; j = j + 1) begin
            stage1[j] = (log2_val[2*j] > log2_val[2*j+1]) ? log2_val[2*j] : log2_val[2*j+1];
        end
        if (N % 2) stage1[N/2] = log2_val[N-1];

        // Stage 2: Pairwise compare
        for (j = 0; j < (N+1)/4; j = j + 1) begin
            stage2[j] = (stage1[2*j] > stage1[2*j+1]) ? stage1[2*j] : stage1[2*j+1];
        end
        if (((N+1)/2) % 2) stage2[(N+1)/4] = stage1[((N+1)/2)-1];

        // Final max selection
        if ((N+3)/4 == 1) begin
            max_log2 = stage2[0];
        end else begin
            max_log2 = stage2[0];
            for (j = 1; j < (N+3)/4; j = j + 1) begin
                if (stage2[j] > max_log2)
                    max_log2 = stage2[j];
            end
        end
    end

    assign exp = max_log2;

    genvar g;
    generate
        for (g = 0; g < N; g = g + 1) begin : gen_output
            assign out_array[g] = in_array[g] << (max_log2 - log2_val[g]);
        end
    endgenerate

endmodule