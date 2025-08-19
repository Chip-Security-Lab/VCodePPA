module param_lfsr_rng #(
    parameter WIDTH = 16,
    parameter [WIDTH-1:0] SEED = {WIDTH{1'b1}},
    parameter [WIDTH-1:0] TAPS = 16'h8016
)(
    input wire clock,
    input wire reset_n,
    input wire enable,
    output wire [WIDTH-1:0] random_value
);
    reg [WIDTH-1:0] lfsr_q;
    wire [WIDTH-1:0] lfsr_c;
    wire feedback;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_lfsr
            if (i == WIDTH-1)
                assign lfsr_c[i] = feedback;
            else
                assign lfsr_c[i] = lfsr_q[i+1];
        end
    endgenerate
    
    assign feedback = ^(lfsr_q & TAPS);
    
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            lfsr_q <= SEED;
        else if (enable)
            lfsr_q <= lfsr_c;
    end
    
    assign random_value = lfsr_q;
endmodule