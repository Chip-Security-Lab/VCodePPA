//SystemVerilog
module rng_cross_10(
    input             clk,
    input             rst,
    input             en,
    output reg [7:0]  out_rnd
);
    reg [7:0] state1, state2;
    wire [7:0] booth_mult_result;

    // Pipeline register for state1/state2 to booth_multiplier
    reg [7:0] state1_pipe, state2_pipe;
    reg       en_pipe;

    booth_multiplier_8bit u_booth_multiplier_8bit (
        .clk(clk),
        .rst(rst),
        .start(en_pipe),
        .multiplicand(state1_pipe),
        .multiplier(state2_pipe),
        .product(booth_mult_result)
    );

    // State update
    always @(posedge clk) begin
        if (rst) begin
            state1 <= 8'hF0;
            state2 <= 8'h0F;
        end else if (en) begin
            state1 <= {state1[6:0], state2[7] ^ state1[0]};
            state2 <= {state2[6:0], state1[7] ^ state2[0]};
        end
    end

    // Pipeline the input to multiplier to cut the path
    always @(posedge clk) begin
        if (rst) begin
            state1_pipe <= 8'd0;
            state2_pipe <= 8'd0;
            en_pipe     <= 1'b0;
        end else begin
            state1_pipe <= state1;
            state2_pipe <= state2;
            en_pipe     <= en;
        end
    end

    // Pipeline output for correct timing and to align with pipeline stage
    reg [7:0] booth_mult_result_pipe;
    always @(posedge clk) begin
        if (rst)
            booth_mult_result_pipe <= 8'd0;
        else
            booth_mult_result_pipe <= booth_mult_result;
    end

    // Output logic now aligned with pipeline
    always @(posedge clk) begin
        if (rst)
            out_rnd <= 8'd0;
        else if (en_pipe)
            out_rnd <= booth_mult_result_pipe;
    end

endmodule

module booth_multiplier_8bit(
    input         clk,
    input         rst,
    input         start,
    input  [7:0]  multiplicand,
    input  [7:0]  multiplier,
    output reg [7:0] product
);
    reg [15:0] booth_prod, booth_prod_pipe;
    reg [7:0]  booth_multiplicand, booth_multiplicand_pipe;
    reg [7:0]  booth_multiplier, booth_multiplier_pipe;
    reg [3:0]  booth_count, booth_count_pipe;
    reg        booth_last_bit, booth_last_bit_pipe;
    reg        booth_busy, booth_busy_pipe;
    reg        start_pipe;

    // Pipeline registers for input to booth logic
    always @(posedge clk) begin
        if (rst) begin
            booth_multiplicand_pipe <= 8'd0;
            booth_multiplier_pipe   <= 8'd0;
            start_pipe              <= 1'b0;
        end else begin
            booth_multiplicand_pipe <= multiplicand;
            booth_multiplier_pipe   <= multiplier;
            start_pipe              <= start;
        end
    end

    // Booth pipeline stage 1: Register input and prepare for operation
    always @(posedge clk) begin
        if (rst) begin
            booth_prod         <= 16'd0;
            booth_multiplicand <= 8'd0;
            booth_multiplier   <= 8'd0;
            booth_count        <= 4'd0;
            booth_last_bit     <= 1'b0;
            booth_busy         <= 1'b0;
        end else begin
            if (start_pipe && !booth_busy) begin
                booth_prod         <= 16'd0;
                booth_multiplicand <= booth_multiplicand_pipe;
                booth_multiplier   <= booth_multiplier_pipe;
                booth_count        <= 4'd0;
                booth_last_bit     <= 1'b0;
                booth_busy         <= 1'b1;
            end else if (booth_busy) begin
                // Pipeline registers for the next booth stage
                booth_prod_pipe         <= booth_prod;
                booth_multiplicand_pipe <= booth_multiplicand;
                booth_multiplier_pipe   <= booth_multiplier;
                booth_count_pipe        <= booth_count;
                booth_last_bit_pipe     <= booth_last_bit;
                booth_busy_pipe         <= booth_busy;
            end
        end
    end

    // Booth pipeline stage 2: Main booth logic and shifting (cuts critical path)
    always @(posedge clk) begin
        if (rst) begin
            booth_prod         <= 16'd0;
            booth_multiplicand <= 8'd0;
            booth_multiplier   <= 8'd0;
            booth_count        <= 4'd0;
            booth_last_bit     <= 1'b0;
            booth_busy         <= 1'b0;
            product            <= 8'd0;
        end else begin
            if (booth_busy_pipe) begin
                case ({booth_multiplier_pipe[0], booth_last_bit_pipe})
                    2'b01: booth_prod_pipe[15:8] = booth_prod_pipe[15:8] + booth_multiplicand_pipe;
                    2'b10: booth_prod_pipe[15:8] = booth_prod_pipe[15:8] - booth_multiplicand_pipe;
                    default: ;
                endcase

                {booth_prod, booth_last_bit} <= {booth_prod_pipe[15], booth_prod_pipe, booth_last_bit_pipe} >>> 1;
                booth_multiplier <= booth_multiplier_pipe >> 1;
                booth_count      <= booth_count_pipe + 1'b1;
                booth_multiplicand <= booth_multiplicand_pipe;
                booth_busy       <= booth_busy_pipe;

                if (booth_count_pipe == 4'd7) begin
                    booth_busy  <= 1'b0;
                    product     <= booth_prod[7:0];
                end
            end
        end
    end
endmodule