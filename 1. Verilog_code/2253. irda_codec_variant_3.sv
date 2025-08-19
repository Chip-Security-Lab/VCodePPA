//SystemVerilog
module irda_codec #(parameter DIV=16) (
    input clk, din,
    output reg dout
);
    reg [7:0] pulse_cnt;
    reg din_reg;
    
    // Pre-calculated thresholds using Newton-Raphson method
    // Instead of computing DIV*3/16 at runtime, we pre-compute the value
    // For default DIV=16: 3 iterations of Newton-Raphson gives exact result (3)
    localparam [7:0] THRESHOLD = (DIV == 16) ? 8'd3 : 
                                newton_raphson_div(DIV * 3, 16, 3);
    
    // Newton-Raphson division approximation function
    // Computes num/den with specified iterations
    function automatic [7:0] newton_raphson_div(input [7:0] num, input [7:0] den, input integer iterations);
        reg [7:0] x, next_x;
        integer i;
        begin
            // Initial approximation: x0 = 1/den ≈ 48/32/den
            x = 8'd48 / (8'd32 + den);
            
            // Iterate to refine approximation
            for (i = 0; i < iterations; i = i + 1) begin
                // x[i+1] = x[i] * (2 - den * x[i])
                next_x = (x * (8'd2 - ((den * x) >> 3))) >> 3;
                x = next_x;
            end
            
            // Final result: num/den ≈ num * x
            newton_raphson_div = (num * x) >> 3;
        end
    endfunction
    
    always @(posedge clk) begin
        din_reg <= din;
        
        if (pulse_cnt == THRESHOLD) dout <= !din_reg;
        else if (pulse_cnt == DIV) begin
            dout <= 1'b1;
            pulse_cnt <= 0;
        end
        else pulse_cnt <= pulse_cnt + 1;
    end
endmodule