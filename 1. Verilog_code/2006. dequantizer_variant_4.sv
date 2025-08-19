//SystemVerilog
module dequantizer_valid_ready #(
    parameter B = 8
)(
    input               clk,
    input               rst_n,
    input       [15:0]  qval,
    input       [15:0]  scale,
    input               in_valid,
    output              in_ready,
    output reg  [15:0]  deq,
    output reg          out_valid,
    input               out_ready
);

    reg         [15:0]  qval_reg;
    reg         [15:0]  scale_reg;
    reg                 busy;
    wire        [31:0]  karatsuba_result;
    reg                 result_valid;
    reg         [15:0]  deq_next;
    reg                 out_valid_next;

    // Input handshake logic
    assign in_ready = ~busy;

    // Input latching and busy flag
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            qval_reg   <= 16'd0;
            scale_reg  <= 16'd0;
            busy       <= 1'b0;
            result_valid <= 1'b0;
        end else begin
            if (in_valid && in_ready) begin
                qval_reg  <= qval;
                scale_reg <= scale;
                busy      <= 1'b1;
            end
            // Latch result_valid when output ready and valid
            if (result_valid && out_ready) begin
                busy        <= 1'b0;
                result_valid <= 1'b0;
            end else if (busy) begin
                result_valid <= 1'b1;
            end
        end
    end

    // Karatsuba multiplication
    karatsuba16x16 u_karatsuba16x16 (
        .a(qval_reg),
        .b(scale_reg),
        .product(karatsuba_result)
    );

    // Dequantization and saturation logic
    always @(*) begin
        deq_next = karatsuba_result[15:0];
        // Saturate to signed 16-bit range
        if ($signed(deq_next) > 16'sd32767)
            deq_next = 16'sd32767;
        else if ($signed(deq_next) < -16'sd32768)
            deq_next = -16'sd32768;
    end

    // Output valid and data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            deq        <= 16'd0;
            out_valid  <= 1'b0;
        end else begin
            if (result_valid && (!out_valid || out_ready)) begin
                deq       <= deq_next;
                out_valid <= 1'b1;
            end else if (out_valid && out_ready) begin
                out_valid <= 1'b0;
            end
        end
    end

endmodule

module karatsuba16x16 (
    input  [15:0] a,
    input  [15:0] b,
    output [31:0] product
);
    wire [7:0] a_high = a[15:8];
    wire [7:0] a_low  = a[7:0];
    wire [7:0] b_high = b[15:8];
    wire [7:0] b_low  = b[7:0];

    wire [15:0] z0;
    wire [15:0] z2;
    wire [16:0] a_sum;
    wire [16:0] b_sum;
    wire [17:0] z1_temp;
    wire [17:0] z1;

    assign z0 = a_low * b_low;
    assign z2 = a_high * b_high;
    assign a_sum = {1'b0, a_high} + {1'b0, a_low};
    assign b_sum = {1'b0, b_high} + {1'b0, b_low};
    assign z1_temp = a_sum * b_sum;
    assign z1 = z1_temp - z2 - z0;

    assign product = ({z2,16'b0}) + ({z1,8'b0}) + z0;
endmodule