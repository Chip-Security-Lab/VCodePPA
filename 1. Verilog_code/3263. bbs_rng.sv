module bbs_rng (
    input wire clock,
    input wire reset,
    output wire [7:0] random_byte
);
    parameter P = 11;
    parameter Q = 23;
    parameter M = P * Q;   // 253
    
    reg [15:0] state;
    reg [7:0] output_reg;
    
    always @(posedge clock) begin
        if (reset)
            state <= 16'd3;
        else
            state <= (state * state) % M;
    end
    
    always @(posedge clock) begin
        if (reset)
            output_reg <= 0;
        else
            output_reg <= state[7:0];
    end
    
    assign random_byte = output_reg;
endmodule