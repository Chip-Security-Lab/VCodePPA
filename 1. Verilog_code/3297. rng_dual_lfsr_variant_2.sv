//SystemVerilog
module rng_dual_lfsr_17_axi_stream(
    input              clk,
    input              rst,
    output reg [7:0]   m_axis_tdata,
    output reg         m_axis_tvalid,
    input              m_axis_tready,
    output reg         m_axis_tlast
);
    reg [7:0] lfsr_a, lfsr_b;
    wire feedback_a = lfsr_a[7] ^ lfsr_a[5];
    wire feedback_b = lfsr_b[6] ^ lfsr_b[0];
    reg [7:0] next_lfsr_a, next_lfsr_b;
    reg [7:0] next_data;
    reg       data_valid;

    wire [7:0] wallace_in_a, wallace_in_b;
    wire [15:0] wallace_product;

    assign wallace_in_a = next_lfsr_a;
    assign wallace_in_b = next_lfsr_b;

    wallace_multiplier_8bit wallace_mult_inst (
        .a(wallace_in_a),
        .b(wallace_in_b),
        .product(wallace_product)
    );

    always @(*) begin
        next_lfsr_a = {lfsr_a[6:0], feedback_b};
        next_lfsr_b = {lfsr_b[6:0], feedback_a};
        next_data   = wallace_product[7:0];
    end

    always @(posedge clk) begin
        if (rst) begin
            lfsr_a        <= 8'hF3;
            lfsr_b        <= 8'h0D;
            m_axis_tdata  <= 8'd0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;
            data_valid    <= 1'b0;
        end else begin
            if (m_axis_tvalid && m_axis_tready) begin
                lfsr_a        <= next_lfsr_a;
                lfsr_b        <= next_lfsr_b;
                m_axis_tdata  <= wallace_product[7:0];
                m_axis_tvalid <= 1'b1;
                m_axis_tlast  <= 1'b0;
                data_valid    <= 1'b1;
            end else if (!m_axis_tvalid) begin
                lfsr_a        <= next_lfsr_a;
                lfsr_b        <= next_lfsr_b;
                m_axis_tdata  <= wallace_product[7:0];
                m_axis_tvalid <= 1'b1;
                m_axis_tlast  <= 1'b0;
                data_valid    <= 1'b1;
            end else begin
                m_axis_tvalid <= m_axis_tvalid;
                m_axis_tdata  <= m_axis_tdata;
                m_axis_tlast  <= m_axis_tlast;
                data_valid    <= data_valid;
            end
        end
    end
endmodule

module wallace_multiplier_8bit (
    input  [7:0] a,
    input  [7:0] b,
    output [15:0] product
);
    wire [7:0] pp [7:0];

    assign pp[0] = b[0] ? a : 8'b0;
    assign pp[1] = b[1] ? a : 8'b0;
    assign pp[2] = b[2] ? a : 8'b0;
    assign pp[3] = b[3] ? a : 8'b0;
    assign pp[4] = b[4] ? a : 8'b0;
    assign pp[5] = b[5] ? a : 8'b0;
    assign pp[6] = b[6] ? a : 8'b0;
    assign pp[7] = b[7] ? a : 8'b0;

    // First stage reduction
    wire [8:0] s1_0, c1_0, s1_1, c1_1, s1_2, c1_2, s1_3, c1_3;

    assign {c1_0[7:0], s1_0[7:0]} = {1'b0, pp[0]} + {1'b0, pp[1]} + {1'b0, pp[2]};
    assign {c1_1[7:0], s1_1[7:0]} = {1'b0, pp[3]} + {1'b0, pp[4]} + {1'b0, pp[5]};
    assign {c1_2[7:0], s1_2[7:0]} = {1'b0, pp[6]} + {1'b0, pp[7]} + 9'b0;

    // Second stage reduction
    wire [9:0] s2_0, c2_0, s2_1, c2_1;
    assign {c2_0[8:0], s2_0[8:0]} = {c1_0[7:0], s1_0[7:0]} + {c1_1[7:0], s1_1[7:0]} + {c1_2[7:0], s1_2[7:0]};
    assign {c2_1[8:0], s2_1[8:0]} = 10'b0;

    // Final stage (carry propagate adder)
    assign product = s2_0[7:0] + (c2_0[7:0] << 1);

endmodule