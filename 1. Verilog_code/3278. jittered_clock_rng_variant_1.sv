//SystemVerilog
module jittered_clock_rng_valid_ready (
    input  wire        main_clk,
    input  wire        reset,
    input  wire [7:0]  jitter_value,
    input  wire        random_out_ready,
    output reg  [15:0] random_out,
    output reg         random_out_valid
);

    reg [7:0]  counter;
    reg        capture_bit;
    reg        next_capture;
    reg [15:0] next_random_out;
    reg        update_random;

    always @(posedge main_clk) begin
        if (reset) begin
            counter           <= 8'h01;
            capture_bit       <= 1'b0;
            random_out        <= 16'h1234;
            random_out_valid  <= 1'b0;
            next_capture      <= 1'b0;
            next_random_out   <= 16'h1234;
            update_random     <= 1'b0;
        end else begin
            counter <= counter + 1'b1;

            next_capture <= ((counter == jitter_value) ? ~capture_bit : capture_bit);

            update_random   <= (next_capture && !capture_bit) ? 1'b1 : 1'b0;
            next_random_out <= (next_capture && !capture_bit) ? {random_out[14:0], counter[0] ^ random_out[15]} : random_out;

            // 扁平化的 valid-ready 控制逻辑
            if (random_out_valid && random_out_ready && !update_random) begin
                random_out_valid <= 1'b0;
            end else if (random_out_valid && random_out_ready && update_random) begin
                random_out       <= next_random_out;
                random_out_valid <= update_random;
            end else if (!random_out_valid && update_random) begin
                random_out       <= next_random_out;
                random_out_valid <= 1'b1;
            end

            capture_bit <= next_capture;
        end
    end

endmodule