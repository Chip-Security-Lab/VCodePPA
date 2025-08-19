//SystemVerilog
module lcg_rng (
    input clock,
    input reset,
    output [31:0] random_number
);
    reg [31:0] lcg_state;

    parameter A = 32'd1664525;
    parameter C = 32'd1013904223;

    always @(posedge clock) begin
        if (reset) begin
            lcg_state <= 32'd123456789;
        end else begin
            lcg_state <= (A * lcg_state) + C;
        end
    end

    assign random_number = lcg_state;
endmodule