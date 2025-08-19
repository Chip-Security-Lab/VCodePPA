//SystemVerilog
module Comparator_Weighted #(
    parameter WIDTH = 8,
    parameter [WIDTH-1:0] WEIGHT = 8'b1000_0001
)(
    input  [WIDTH-1:0] vector_a,
    input  [WIDTH-1:0] vector_b,
    output             a_gt_b
);

    // Kogge-Stone adder implementation
    function [31:0] kogge_stone_add;
        input [31:0] a, b;
        reg [31:0] g, p, sum;
        reg [31:0] g_next, p_next;
        integer i;
        begin
            // Generate and propagate
            for(i = 0; i < 32; i = i + 1) begin
                g[i] = a[i] & b[i];
                p[i] = a[i] ^ b[i];
            end

            // Kogge-Stone prefix computation
            for(i = 0; i < 5; i = i + 1) begin
                for(int j = 0; j < 32; j = j + 1) begin
                    if(j >= (1 << i)) begin
                        g_next[j] = g[j] | (p[j] & g[j-(1<<i)]);
                        p_next[j] = p[j] & p[j-(1<<i)];
                    end else begin
                        g_next[j] = g[j];
                        p_next[j] = p[j];
                    end
                end
                g = g_next;
                p = p_next;
            end

            // Final sum computation
            sum[0] = p[0];
            for(i = 1; i < 32; i = i + 1) begin
                sum[i] = p[i] ^ g[i-1];
            end
            kogge_stone_add = sum;
        end
    endfunction

    // Weighted sum calculation using Kogge-Stone adder
    function [31:0] weighted_sum;
        input [WIDTH-1:0] vec;
        reg [31:0] sum;
        integer i;
        begin
            sum = 0;
            for(i = 0; i < WIDTH; i = i + 1) begin
                if(vec[i]) begin
                    sum = kogge_stone_add(sum, (32'b1 << i) & WEIGHT);
                end
            end
            weighted_sum = sum;
        end
    endfunction

    wire [31:0] sum_a, sum_b;
    assign sum_a = weighted_sum(vector_a);
    assign sum_b = weighted_sum(vector_b);
    assign a_gt_b = (sum_a > sum_b);

endmodule