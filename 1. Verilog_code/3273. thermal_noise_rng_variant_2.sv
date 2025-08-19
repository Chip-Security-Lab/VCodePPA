//SystemVerilog
module thermal_noise_rng_valid_ready (
    input  wire         clock,
    input  wire         reset,
    input  wire         out_ready,
    output reg  [15:0]  out_data,
    output reg          out_valid
);

    reg [31:0] noise_gen_x, noise_gen_x_next;
    reg [31:0] noise_gen_y, noise_gen_y_next;
    reg [15:0] random_next;
    reg        out_valid_next;

    typedef enum logic [1:0] {
        STATE_RESET       = 2'b00,
        STATE_GEN_RANDOM  = 2'b01,
        STATE_HOLD        = 2'b10
    } state_t;

    state_t current_state;

    always @* begin
        case ({reset, (out_ready || !out_valid)})
            2'b10: current_state = STATE_RESET;
            2'b01: current_state = STATE_GEN_RANDOM;
            2'b00: current_state = STATE_HOLD;
            default: current_state = STATE_HOLD;
        endcase
    end

    always @* begin
        case (current_state)
            STATE_RESET: begin
                noise_gen_x_next = 32'h12345678;
                noise_gen_y_next = 32'h87654321;
                random_next      = 16'h0;
                out_valid_next   = 1'b0;
            end
            STATE_GEN_RANDOM: begin
                noise_gen_x_next = noise_gen_x * 32'd1103515245 + 32'd12345;
                noise_gen_y_next = noise_gen_y * 32'd214013 + 32'd2531011;
                random_next      = noise_gen_x_next[31:24] * noise_gen_y_next[31:24];
                out_valid_next   = 1'b1;
            end
            STATE_HOLD: begin
                noise_gen_x_next = noise_gen_x;
                noise_gen_y_next = noise_gen_y;
                random_next      = out_data;
                out_valid_next   = out_valid;
            end
            default: begin
                noise_gen_x_next = noise_gen_x;
                noise_gen_y_next = noise_gen_y;
                random_next      = out_data;
                out_valid_next   = out_valid;
            end
        endcase
    end

    always @(posedge clock) begin
        if (reset) begin
            noise_gen_x <= 32'h12345678;
            noise_gen_y <= 32'h87654321;
            out_data    <= 16'h0;
            out_valid   <= 1'b0;
        end else begin
            noise_gen_x <= noise_gen_x_next;
            noise_gen_y <= noise_gen_y_next;
            out_data    <= random_next;
            out_valid   <= out_valid_next;
        end
    end

endmodule