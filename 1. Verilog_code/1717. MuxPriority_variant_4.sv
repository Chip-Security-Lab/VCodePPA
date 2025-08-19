//SystemVerilog
module MuxPriority #(parameter W=8, N=4) (
    input [N-1:0] valid,
    input [W-1:0] data [0:N-1],
    output reg [W-1:0] result
);

    // Generate and propagate signals for carry lookahead
    wire [N-1:0] g, p;
    wire [N:0] carry;
    
    // Generate and propagate logic
    genvar i;
    generate
        for(i = 0; i < N; i = i + 1) begin : gen_prop
            assign g[i] = valid[i];
            assign p[i] = valid[i];
        end
    endgenerate
    
    // Carry lookahead logic
    assign carry[0] = 1'b0;
    genvar j;
    generate
        for(j = 0; j < N; j = j + 1) begin : carry_gen
            assign carry[j+1] = g[j] | (p[j] & carry[j]);
        end
    endgenerate
    
    // Output selection using carry lookahead
    always @(*) begin
        result = 0;
        for(int k = 0; k < N; k = k + 1) begin
            if(carry[k] & ~carry[k+1]) begin
                result = data[k];
            end
        end
    end

endmodule