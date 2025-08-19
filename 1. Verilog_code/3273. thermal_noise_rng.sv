module thermal_noise_rng (
    input wire clock,
    input wire reset,
    output reg [15:0] random_out
);
    reg [31:0] noise_gen_x;
    reg [31:0] noise_gen_y;
    
    always @(posedge clock) begin
        if (reset) begin
            noise_gen_x <= 32'h12345678;
            noise_gen_y <= 32'h87654321;
            random_out <= 16'h0;
        end else begin
            // Box-Muller transform approximation
            noise_gen_x <= noise_gen_x * 32'd1103515245 + 32'd12345;
            noise_gen_y <= noise_gen_y * 32'd214013 + 32'd2531011;
            random_out <= noise_gen_x[31:24] * noise_gen_y[31:24];
        end
    end
endmodule