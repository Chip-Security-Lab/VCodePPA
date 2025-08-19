//SystemVerilog
module rng_cnt_xor_11_axis #(
    parameter DATA_WIDTH = 8
)(
    input                   clk,
    input                   rst,
    // AXI-Stream Slave Interface (input)
    input                   s_axis_tvalid,
    output                  s_axis_tready,
    input  [DATA_WIDTH-1:0] s_axis_tdata, // 保留，未来可扩展
    // AXI-Stream Master Interface (output)
    output                  m_axis_tvalid,
    input                   m_axis_tready,
    output [DATA_WIDTH-1:0] m_axis_tdata,
    output                  m_axis_tlast
);

    reg [DATA_WIDTH-1:0] cnt_reg;
    reg                  cnt_valid_reg;
    wire [DATA_WIDTH-1:0] adder_sum;
    wire                  axis_handshake;

    assign axis_handshake = m_axis_tvalid && m_axis_tready;

    // Han-Carlson加法器实例
    han_carlson_adder_8 u_han_carlson_adder_8 (
        .a(cnt_reg),
        .b(8'b0000_0001),
        .sum(adder_sum)
    );

    // 优化：更高效的数据有效控制与AXIS握手
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_reg        <= {DATA_WIDTH{1'b0}};
            cnt_valid_reg  <= 1'b0;
        end else begin
            if (axis_handshake) begin
                cnt_reg       <= adder_sum;
                cnt_valid_reg <= 1'b1;
            end else if (!cnt_valid_reg && s_axis_tvalid) begin
                cnt_reg       <= cnt_reg; // 保持当前计数
                cnt_valid_reg <= 1'b1;
            end else if (axis_handshake) begin
                cnt_valid_reg <= 1'b0;
            end
        end
    end

    // 输出AXI-Stream信号
    assign m_axis_tdata  = cnt_reg ^ {cnt_reg[3:0], cnt_reg[7:4]};
    assign m_axis_tvalid = cnt_valid_reg;
    assign m_axis_tlast  = 1'b0; // 单包流，未使用
    assign s_axis_tready = !cnt_valid_reg || (cnt_valid_reg && axis_handshake);

endmodule

module han_carlson_adder_8(
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] sum
);
    wire [7:0] g0, p0;
    wire [7:0] g1, p1;
    wire [7:0] g2, p2;
    wire [7:0] g3, p3;
    wire [7:0] g4, p4;
    wire [7:0] g5, p5;
    wire [7:0] carry;

    // Stage 0: Generate and Propagate
    assign g0 = a & b;
    assign p0 = a ^ b;

    // Stage 1
    assign g1[0] = g0[0];
    assign p1[0] = p0[0];
    assign g1[1] = g0[1] | (p0[1] & g0[0]);
    assign p1[1] = p0[1] & p0[0];
    assign g1[2] = g0[2] | (p0[2] & g0[1]);
    assign p1[2] = p0[2] & p0[1];
    assign g1[3] = g0[3] | (p0[3] & g0[2]);
    assign p1[3] = p0[3] & p0[2];
    assign g1[4] = g0[4] | (p0[4] & g0[3]);
    assign p1[4] = p0[4] & p0[3];
    assign g1[5] = g0[5] | (p0[5] & g0[4]);
    assign p1[5] = p0[5] & p0[4];
    assign g1[6] = g0[6] | (p0[6] & g0[5]);
    assign p1[6] = p0[6] & p0[5];
    assign g1[7] = g0[7] | (p0[7] & g0[6]);
    assign p1[7] = p0[7] & p0[6];

    // Stage 2
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    assign g2[2] = g1[2] | (p1[2] & g1[0]);
    assign p2[2] = p1[2] & p1[0];
    assign g2[3] = g1[3] | (p1[3] & g1[1]);
    assign p2[3] = p1[3] & p1[1];
    assign g2[4] = g1[4] | (p1[4] & g1[2]);
    assign p2[4] = p1[4] & p1[2];
    assign g2[5] = g1[5] | (p1[5] & g1[3]);
    assign p2[5] = p1[5] & p1[3];
    assign g2[6] = g1[6] | (p1[6] & g1[4]);
    assign p2[6] = p1[6] & p1[4];
    assign g2[7] = g1[7] | (p1[7] & g1[5]);
    assign p2[7] = p1[7] & p1[5];

    // Stage 3
    assign g3[0] = g2[0];
    assign p3[0] = p2[0];
    assign g3[1] = g2[1];
    assign p3[1] = p2[1];
    assign g3[2] = g2[2];
    assign p3[2] = p2[2];
    assign g3[3] = g2[3];
    assign p3[3] = p2[3];
    assign g3[4] = g2[4] | (p2[4] & g2[0]);
    assign p3[4] = p2[4] & p2[0];
    assign g3[5] = g2[5] | (p2[5] & g2[1]);
    assign p3[5] = p2[5] & p2[1];
    assign g3[6] = g2[6] | (p2[6] & g2[2]);
    assign p3[6] = p2[6] & p2[2];
    assign g3[7] = g2[7] | (p2[7] & g2[3]);
    assign p3[7] = p2[7] & p2[3];

    // Stage 4 (Final stage)
    assign g4[0] = g3[0];
    assign p4[0] = p3[0];
    assign g4[1] = g3[1];
    assign p4[1] = p3[1];
    assign g4[2] = g3[2];
    assign p4[2] = p3[2];
    assign g4[3] = g3[3];
    assign p4[3] = p3[3];
    assign g4[4] = g3[4];
    assign p4[4] = p3[4];
    assign g4[5] = g3[5];
    assign p4[5] = p3[5];
    assign g4[6] = g3[6] | (p3[6] & g3[2]);
    assign p4[6] = p3[6] & p3[2];
    assign g4[7] = g3[7] | (p3[7] & g3[3]);
    assign p4[7] = p3[7] & p3[3];

    // Carry generation
    assign carry[0] = 1'b0;
    assign carry[1] = g0[0];
    assign carry[2] = g1[1];
    assign carry[3] = g2[2];
    assign carry[4] = g3[3];
    assign carry[5] = g4[4];
    assign carry[6] = g4[5];
    assign carry[7] = g4[6];

    // Sum
    assign sum[0] = p0[0] ^ carry[0];
    assign sum[1] = p0[1] ^ carry[1];
    assign sum[2] = p0[2] ^ carry[2];
    assign sum[3] = p0[3] ^ carry[3];
    assign sum[4] = p0[4] ^ carry[4];
    assign sum[5] = p0[5] ^ carry[5];
    assign sum[6] = p0[6] ^ carry[6];
    assign sum[7] = p0[7] ^ carry[7];
endmodule