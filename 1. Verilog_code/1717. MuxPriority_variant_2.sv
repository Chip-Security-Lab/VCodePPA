//SystemVerilog
module MuxPriority #(parameter W=8, N=4) (
    input [N-1:0] valid,
    input [W-1:0] data [0:N-1],
    output reg [W-1:0] result
);
    wire [W-1:0] carry;
    wire [W-1:0] sum;
    wire [W-1:0] g [0:N-1];
    wire [W-1:0] p [0:N-1];
    
    // Generate and Propagate signals
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : gen_gp
            assign g[i] = valid[i] ? data[i] : {W{1'b0}};
            assign p[i] = valid[i] ? {W{1'b1}} : {W{1'b0}};
        end
    endgenerate
    
    // Carry Lookahead Logic
    assign carry[0] = 1'b0;
    genvar j;
    generate
        for (j = 1; j < W; j = j + 1) begin : gen_carry
            assign carry[j] = g[j-1] | (p[j-1] & carry[j-1]);
        end
    endgenerate
    
    // Sum Generation
    genvar k;
    generate
        for (k = 0; k < W; k = k + 1) begin : gen_sum
            assign sum[k] = g[k] ^ carry[k];
        end
    endgenerate
    
    always @(*) begin
        result = sum;
    end
endmodule