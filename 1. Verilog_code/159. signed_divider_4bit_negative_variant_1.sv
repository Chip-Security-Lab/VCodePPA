//SystemVerilog
module signed_divider_4bit_negative (
    input signed [3:0] a,
    input signed [3:0] b,
    output signed [3:0] quotient,
    output signed [3:0] remainder
);

    // Optimized division logic
    wire signed [3:0] abs_a = (a[3]) ? -a : a;
    wire signed [3:0] abs_b = (b[3]) ? -b : b;
    wire sign_quotient = a[3] ^ b[3];
    
    // Division core
    reg signed [3:0] div_result;
    reg signed [3:0] rem_result;
    
    always @(*) begin
        if (b == 0) begin
            div_result = 4'b0;
            rem_result = 4'b0;
        end else begin
            // Optimized division algorithm
            div_result = 4'b0;
            rem_result = abs_a;
            
            for (int i = 3; i >= 0; i--) begin
                if (rem_result >= (abs_b << i)) begin
                    div_result[i] = 1'b1;
                    rem_result = rem_result - (abs_b << i);
                end
            end
            
            // Apply sign to quotient
            div_result = sign_quotient ? -div_result : div_result;
            
            // Apply sign to remainder
            rem_result = a[3] ? -rem_result : rem_result;
        end
    end

    assign quotient = div_result;
    assign remainder = rem_result;

endmodule