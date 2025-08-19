module lcg_rng (
    input clock,
    input reset,
    output [31:0] random_number
);
    reg [31:0] state;
    
    parameter A = 32'd1664525;
    parameter C = 32'd1013904223;
    
    always @(posedge clock) begin
        if (reset)
            state <= 32'd123456789;
        else
            state <= (A * state) + C;
    end
    
    assign random_number = state;
endmodule