//SystemVerilog
module ParallelPrefixSubtractor #(parameter W=8) (
    input [W-1:0] a,
    input [W-1:0] b,
    output [W-1:0] diff,
    output borrow
);
    // Generate and propagate signals
    wire [W-1:0] g, p;
    wire [W-1:0] carry;
    
    // Generate and propagate computation
    genvar i;
    generate
        for (i = 0; i < W; i = i + 1) begin : gen_prop
            assign g[i] = a[i] & ~b[i];
            assign p[i] = a[i] ^ ~b[i];
        end
    endgenerate
    
    // Parallel prefix computation
    wire [W-1:0][W-1:0] prefix_g, prefix_p;
    
    // First level
    genvar j;
    generate
        for (j = 0; j < W; j = j + 1) begin : first_level
            assign prefix_g[0][j] = g[j];
            assign prefix_p[0][j] = p[j];
        end
    endgenerate
    
    // Remaining levels
    genvar k, l;
    generate
        for (k = 1; k < W; k = k + 1) begin : prefix_levels
            for (l = 0; l < W; l = l + 1) begin : prefix_elements
                if (l < (1 << k)) begin
                    assign prefix_g[k][l] = prefix_g[k-1][l];
                    assign prefix_p[k][l] = prefix_p[k-1][l];
                end else begin
                    assign prefix_g[k][l] = prefix_g[k-1][l] | (prefix_p[k-1][l] & prefix_g[k-1][l-(1<<(k-1))]);
                    assign prefix_p[k][l] = prefix_p[k-1][l] & prefix_p[k-1][l-(1<<(k-1))];
                end
            end
        end
    endgenerate
    
    // Carry computation
    assign carry[0] = 1'b0; // Initial carry-in is 0 for subtraction
    genvar m;
    generate
        for (m = 1; m < W; m = m + 1) begin : carry_compute
            assign carry[m] = prefix_g[$clog2(W)-1][m-1];
        end
    endgenerate
    
    // Difference computation
    genvar n;
    generate
        for (n = 0; n < W; n = n + 1) begin : diff_compute
            assign diff[n] = p[n] ^ carry[n];
        end
    endgenerate
    
    // Final borrow
    assign borrow = carry[W-1];
endmodule

module MuxOneHot #(parameter W=4, N=8) (
    input [N-1:0] hot_sel,
    input [N-1:0][W-1:0] channels,
    output [W-1:0] selected
);
    reg [W-1:0] selected_reg;
    integer i;
    
    always @(*) begin
        selected_reg = {W{1'b0}};
        for (i = 0; i < N; i = i + 1) begin
            if (hot_sel[i]) begin
                selected_reg = channels[i];
            end
        end
    end
    
    assign selected = selected_reg;
endmodule

module MuxOneHotWithSubtractor #(parameter W=4, N=8) (
    input [N-1:0] hot_sel,
    input [N-1:0][W-1:0] channels,
    input [W-1:0] subtract_value,
    output [W-1:0] selected,
    output [W-1:0] diff_result,
    output borrow
);
    wire [W-1:0] selected_value;
    
    // Instantiate the original MuxOneHot
    MuxOneHot #(.W(W), .N(N)) mux_inst (
        .hot_sel(hot_sel),
        .channels(channels),
        .selected(selected_value)
    );
    
    // Instantiate the parallel prefix subtractor
    ParallelPrefixSubtractor #(.W(W)) subtractor_inst (
        .a(selected_value),
        .b(subtract_value),
        .diff(diff_result),
        .borrow(borrow)
    );
    
    assign selected = selected_value;
endmodule