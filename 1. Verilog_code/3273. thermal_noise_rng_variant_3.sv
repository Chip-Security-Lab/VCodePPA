//SystemVerilog
module thermal_noise_rng (
    input wire clock,
    input wire reset,
    output reg [15:0] random_out
);

    // Stage 1: Seed update registers
    reg [31:0] noise_x_seed_stage1;
    reg [31:0] noise_y_seed_stage1;

    // Stage 2: PRNG calculation registers
    reg [31:0] noise_x_seed_stage2;
    reg [31:0] noise_y_seed_stage2;

    // Stage 3: Output calculation registers
    reg [7:0] noise_x_byte_stage3;
    reg [7:0] noise_y_byte_stage3;
    reg [15:0] random_product_stage3;

    // Pipeline Stage 1: Seed update
    always @(posedge clock) begin
        if (reset) begin
            noise_x_seed_stage1 <= 32'h12345678;
            noise_y_seed_stage1 <= 32'h87654321;
        end else begin
            noise_x_seed_stage1 <= noise_x_seed_stage2;
            noise_y_seed_stage1 <= noise_y_seed_stage2;
        end
    end

    // Pipeline Stage 2: PRNG calculation
    always @(posedge clock) begin
        if (reset) begin
            noise_x_seed_stage2 <= 32'h12345678;
            noise_y_seed_stage2 <= 32'h87654321;
        end else begin
            noise_x_seed_stage2 <= noise_x_seed_stage1 * 32'd1103515245 + 32'd12345;
            noise_y_seed_stage2 <= noise_y_seed_stage1 * 32'd214013 + 32'd2531011;
        end
    end

    // Pipeline Stage 3: Output calculation
    always @(posedge clock) begin
        if (reset) begin
            noise_x_byte_stage3 <= 8'd0;
            noise_y_byte_stage3 <= 8'd0;
            random_product_stage3 <= 16'd0;
        end else begin
            noise_x_byte_stage3 <= noise_x_seed_stage2[31:24];
            noise_y_byte_stage3 <= noise_y_seed_stage2[31:24];
            random_product_stage3 <= noise_x_seed_stage2[31:24] * noise_y_seed_stage2[31:24];
        end
    end

    // Pipeline Stage 4: Register the output
    always @(posedge clock) begin
        if (reset) begin
            random_out <= 16'd0;
        end else begin
            random_out <= random_product_stage3;
        end
    end

endmodule