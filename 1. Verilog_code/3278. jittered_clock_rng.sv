module jittered_clock_rng (
    input wire main_clk,
    input wire reset,
    input wire [7:0] jitter_value,
    output reg [15:0] random_out
);
    reg [7:0] counter;
    reg capture_bit;
    
    always @(posedge main_clk) begin
        if (reset) begin
            counter <= 8'h01;
            capture_bit <= 1'b0;
            random_out <= 16'h1234;
        end else begin
            counter <= counter + 1'b1;
            
            // Simulate jittered clock by capturing at variable times
            if (counter == jitter_value)
                capture_bit <= ~capture_bit;
                
            if (capture_bit)
                random_out <= {random_out[14:0], counter[0] ^ random_out[15]};
        end
    end
endmodule