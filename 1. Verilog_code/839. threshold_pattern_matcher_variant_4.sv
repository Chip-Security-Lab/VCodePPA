//SystemVerilog
module threshold_pattern_matcher #(parameter W = 16, THRESHOLD = 3) (
    input [W-1:0] data, pattern,
    output match_flag
);
    wire [W-1:0] xnor_result = ~(data ^ pattern);
    wire [$clog2(W+1)-1:0] match_count;
    
    han_carlson_popcount #(.WIDTH(W)) bit_counter (
        .bits_in(xnor_result),
        .count_out(match_count)
    );
    
    assign match_flag = (match_count >= THRESHOLD);
endmodule

module han_carlson_popcount #(parameter WIDTH = 16) (
    input [WIDTH-1:0] bits_in,
    output [$clog2(WIDTH+1)-1:0] count_out
);
    localparam STAGES = $clog2(WIDTH);
    wire [$clog2(WIDTH+1)-1:0] stage0 [WIDTH-1:0];
    wire [$clog2(WIDTH+1)-1:0] prefix_sum [STAGES:0][WIDTH-1:0];
    
    genvar i, j, k;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: init_stage
            assign stage0[i] = bits_in[i] ? 1'b1 : 1'b0;
            assign prefix_sum[0][i] = stage0[i];
        end
        
        for (i = 0; i < STAGES; i = i + 1) begin: prefix_stage
            for (j = 0; j < WIDTH; j = j + 1) begin: prefix_step
                if (i == 0) begin
                    if (j >= 1) begin
                        assign prefix_sum[i+1][j] = prefix_sum[i][j] + prefix_sum[i][j-1];
                    end else begin
                        assign prefix_sum[i+1][j] = prefix_sum[i][j];
                    end
                end else if (i == 1) begin
                    if (j >= 2) begin
                        assign prefix_sum[i+1][j] = prefix_sum[i][j] + prefix_sum[i][j-2];
                    end else begin
                        assign prefix_sum[i+1][j] = prefix_sum[i][j];
                    end
                end else begin
                    if (j >= (1 << (i+1))) begin
                        assign prefix_sum[i+1][j] = prefix_sum[i][j] + prefix_sum[i][j-(1<<(i+1))];
                    end else begin
                        assign prefix_sum[i+1][j] = prefix_sum[i][j];
                    end
                end
            end
        end
    endgenerate
    
    assign count_out = prefix_sum[STAGES][WIDTH-1];
endmodule