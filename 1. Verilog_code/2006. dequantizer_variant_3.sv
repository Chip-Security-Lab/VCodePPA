//SystemVerilog
module dequantizer_valid_ready #(parameter B=8) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  in_valid,
    output wire                  in_ready,
    input  wire signed   [15:0]  qval,
    input  wire signed   [15:0]  scale,
    output reg                   out_valid,
    input  wire                  out_ready,
    output reg  signed   [15:0]  deq
);

    // Internal signals for valid-ready handshake
    reg                          input_accepted;
    reg                          process_busy;
    reg  signed   [15:0]         qval_reg;
    reg  signed   [15:0]         scale_reg;
    wire signed   [31:0]         mult_result;

    // Input ready signal: accept input when not busy and output not valid, or when output is ready to be consumed
    assign in_ready = (!process_busy) && (!out_valid || (out_valid && out_ready));

    // Latch input data on valid and ready
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            qval_reg   <= 16'sd0;
            scale_reg  <= 16'sd0;
            input_accepted <= 1'b0;
        end else if (in_valid && in_ready) begin
            qval_reg   <= qval;
            scale_reg  <= scale;
            input_accepted <= 1'b1;
        end else begin
            input_accepted <= 1'b0;
        end
    end

    // Busy signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            process_busy <= 1'b0;
        end else if (in_valid && in_ready) begin
            process_busy <= 1'b1;
        end else if (out_valid && out_ready) begin
            process_busy <= 1'b0;
        end
    end

    // Karatsuba multiplier instance
    karatsuba_multiplier_16x16 karatsuba_mult_inst (
        .a(qval_reg),
        .b(scale_reg),
        .product(mult_result)
    );

    // Output valid logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
        end else if (input_accepted) begin
            out_valid <= 1'b1;
        end else if (out_valid && out_ready) begin
            out_valid <= 1'b0;
        end
    end

    // Output data logic (saturate mult_result)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            deq <= 16'sd0;
        end else if (input_accepted) begin
            if (mult_result > 32767)
                deq <= 16'sd32767;
            else if (mult_result < -32768)
                deq <= -16'sd32768;
            else
                deq <= mult_result[15:0];
        end
    end

endmodule

module karatsuba_multiplier_16x16 (
    input  wire signed [15:0] a,
    input  wire signed [15:0] b,
    output wire signed [31:0] product
);
    wire signed [7:0] a_high = a[15:8];
    wire signed [7:0] a_low  = a[7:0];
    wire signed [7:0] b_high = b[15:8];
    wire signed [7:0] b_low  = b[7:0];

    wire signed [15:0] z0;
    wire signed [15:0] z2;
    wire signed [15:0] z1;
    wire signed [8:0]  a_sum;
    wire signed [8:0]  b_sum;
    wire signed [17:0] z1_temp;

    assign z0 = a_low * b_low;
    assign z2 = a_high * b_high;

    assign a_sum = a_low + a_high;
    assign b_sum = b_low + b_high;
    assign z1_temp = a_sum * b_sum;
    assign z1 = z1_temp - z2 - z0;

    assign product = ({{16{z2[15]}},z2} << 16) + ({{8{z1[15]}},z1} << 8) + z0;

endmodule