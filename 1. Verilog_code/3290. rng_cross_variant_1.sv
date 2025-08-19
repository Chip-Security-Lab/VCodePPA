//SystemVerilog
module rng_cross_10(
    input             clk,
    input             rst,
    input             en,
    output reg [7:0]  out_rnd
);
    reg [7:0] state_a, state_b;
    wire [7:0] next_state_a, next_state_b;
    wire feedback_a, feedback_b;

    assign feedback_a = state_b[7] ^ state_a[0];
    assign feedback_b = state_a[7] ^ state_b[0];

    assign next_state_a = {state_a[6:0], feedback_a};
    assign next_state_b = {state_b[6:0], feedback_b};

    reg [7:0] multiplicand;
    reg [7:0] multiplier;
    reg [15:0] booth_product_result;
    reg [4:0] booth_cnt;
    reg booth_active;
    reg booth_start;
    reg [7:0] rnd_value;

    localparam MUL_IDLE = 1'b0, MUL_BUSY = 1'b1;
    reg mul_state;

    // Booth Multiplier Registers
    reg [16:0] booth_accumulator; // [16:0] to store [product[15:0], Q-1]
    reg [7:0] booth_mcand;
    reg [7:0] booth_mplier;

    always @(posedge clk) begin
        if (rst) begin
            state_a <= 8'hF0;
            state_b <= 8'h0F;
        end else if (en) begin
            state_a <= next_state_a;
            state_b <= next_state_b;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            multiplicand        <= 8'd0;
            multiplier          <= 8'd0;
            booth_product_result<= 16'd0;
            booth_cnt           <= 5'd0;
            booth_active        <= 1'b0;
            booth_start         <= 1'b0;
            booth_accumulator   <= 17'd0;
            booth_mcand         <= 8'd0;
            booth_mplier        <= 8'd0;
            mul_state           <= MUL_IDLE;
            rnd_value           <= 8'd0;
        end else begin
            case (mul_state)
                MUL_IDLE: begin
                    if (en) begin
                        multiplicand        <= state_a ^ state_b;
                        multiplier          <= state_a + state_b;
                        booth_mcand         <= state_a ^ state_b;
                        booth_mplier        <= state_a + state_b;
                        booth_accumulator   <= {8'd0, state_a + state_b, 1'b0}; // [A(8):Q(8):Q-1]
                        booth_cnt           <= 5'd0;
                        booth_active        <= 1'b1;
                        booth_start         <= 1'b1;
                        mul_state           <= MUL_BUSY;
                    end else begin
                        booth_active        <= 1'b0;
                        booth_start         <= 1'b0;
                    end
                end
                MUL_BUSY: begin
                    if (booth_cnt < 8) begin
                        case ({booth_accumulator[1:0]})
                            2'b01: booth_accumulator[16:9] <= booth_accumulator[16:9] + booth_mcand;
                            2'b10: booth_accumulator[16:9] <= booth_accumulator[16:9] - booth_mcand;
                            default: /* do nothing */;
                        endcase
                        // Arithmetic right shift {A,Q,Q-1}
                        booth_accumulator <= {booth_accumulator[16], booth_accumulator[16:1]};
                        booth_cnt         <= booth_cnt + 1'b1;
                    end else begin
                        booth_product_result <= booth_accumulator[16:1];
                        rnd_value           <= booth_accumulator[8:1];
                        mul_state           <= MUL_IDLE;
                        booth_active        <= 1'b0;
                        booth_start         <= 1'b0;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        out_rnd = rnd_value;
    end
endmodule