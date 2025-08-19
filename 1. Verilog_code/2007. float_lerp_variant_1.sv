//SystemVerilog
module float_lerp_axi_stream #(
    parameter MANT = 10,
    parameter EXP = 5
)(
    input  wire                         clk,
    input  wire                         rst_n,

    // AXI-Stream Slave Interface (Input)
    input  wire                         s_axis_tvalid,
    output wire                         s_axis_tready,
    input  wire [MANT+EXP:0]            s_axis_tdata_a,
    input  wire [MANT+EXP:0]            s_axis_tdata_b,
    input  wire [7:0]                   s_axis_tdata_t,
    input  wire                         s_axis_tlast,

    // AXI-Stream Master Interface (Output)
    output wire                         m_axis_tvalid,
    input  wire                         m_axis_tready,
    output wire [MANT+EXP:0]            m_axis_tdata_c,
    output wire                         m_axis_tlast
);

    // Internal handshake signals
    reg                                 input_accept;
    reg                                 output_valid;
    reg  [MANT+EXP:0]                   result_c;
    reg                                 result_tlast;
    reg                                 output_valid_next;
    reg                                 result_tlast_next;

    // Data registers
    reg  [MANT+EXP:0]                   reg_a;
    reg  [MANT+EXP:0]                   reg_b;
    reg  [7:0]                          reg_t;
    reg                                 reg_tlast;

    // AXI-Stream handshake
    assign s_axis_tready = !output_valid;
    assign m_axis_tvalid = output_valid;
    assign m_axis_tdata_c = result_c;
    assign m_axis_tlast = result_tlast;

    // Pipeline register input
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_a      <= { (MANT+EXP+1){1'b0} };
            reg_b      <= { (MANT+EXP+1){1'b0} };
            reg_t      <= 8'd0;
            reg_tlast  <= 1'b0;
            input_accept <= 1'b0;
        end else begin
            input_accept <= 1'b0;
            if (s_axis_tvalid && s_axis_tready) begin
                reg_a     <= s_axis_tdata_a;
                reg_b     <= s_axis_tdata_b;
                reg_t     <= s_axis_tdata_t;
                reg_tlast <= s_axis_tlast;
                input_accept <= 1'b1;
            end
        end
    end

    // Chebyshev and calculation pipeline
    wire [15:0] chebyshev_approx;
    wire [MANT+EXP:0] weight_a, weight_b;
    wire [MANT*2+EXP*2+3:0] weighted_sum;

    chebyshev_approx8 cheb_inst (
        .x(reg_t),
        .y(chebyshev_approx)
    );

    assign weight_a = reg_a * (8'd255 - chebyshev_approx[7:0]);
    assign weight_b = reg_b * chebyshev_approx[7:0];
    assign weighted_sum = weight_a + weight_b;

    // Output register stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            output_valid   <= 1'b0;
            result_c       <= { (MANT+EXP+1){1'b0} };
            result_tlast   <= 1'b0;
        end else begin
            output_valid_next   = output_valid;
            result_tlast_next   = result_tlast;
            if (input_accept) begin
                result_c     <= weighted_sum >> 8;
                output_valid <= 1'b1;
                result_tlast <= reg_tlast;
            end else if (m_axis_tvalid && m_axis_tready) begin
                output_valid <= 1'b0;
                result_tlast <= 1'b0;
            end
        end
    end

endmodule

// Chebyshev polynomial approximation module for 8-bit input
module chebyshev_approx8 (
    input  wire [7:0] x,
    output reg  [15:0] y
);
    reg signed [15:0] x_mapped;
    reg signed [15:0] t1, t2, t3;
    reg signed [15:0] term1, term2, term3;
    always @* begin
        x_mapped = (x << 8) - 16'd32768;
        t1 = x_mapped;
        t2 = ((2 * (x_mapped * x_mapped) >>> 15) - 16'd32768);
        t3 = ((4 * (x_mapped * x_mapped * x_mapped) >>> 30) - (3 * x_mapped));
        term1 = t1 >>> 1;
        term2 = t2 >>> 3;
        term3 = -(t3 >>> 4);
        y = 16'd128 + term1 + term2 + term3;
        if (y < 0)
            y = 0;
        else if (y > 255)
            y = 255;
    end
endmodule