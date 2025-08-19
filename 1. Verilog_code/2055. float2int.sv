module float2int #(parameter INT_BITS = 32) (
    input wire clk, rst_n,
    input wire [31:0] float_in,  // IEEE-754 Single precision
    output reg signed [INT_BITS-1:0] int_out,
    output reg overflow
);
    wire sign;
    wire [7:0] exponent;
    wire [22:0] mantissa;
    wire [INT_BITS-1:0] shifted_value;
    
    assign sign = float_in[31];
    assign exponent = float_in[30:23];
    assign mantissa = float_in[22:0];
    
    assign shifted_value = {1'b1, mantissa} << (exponent - 127);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_out <= 0;
            overflow <= 1'b0;
        end else begin
            overflow <= (exponent > (127 + INT_BITS - 1));
            if (!overflow)
                int_out <= sign ? -shifted_value : shifted_value;
            else
                int_out <= sign ? {1'b1, {(INT_BITS-1){1'b0}}} : {1'b0, {(INT_BITS-1){1'b1}}};
        end
    end
endmodule