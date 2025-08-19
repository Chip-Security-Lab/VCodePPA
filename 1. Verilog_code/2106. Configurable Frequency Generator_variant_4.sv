//SystemVerilog
module config_freq_gen_req_ack(
    input wire master_clk,
    input wire rstn,
    input wire req,                  // 请求信号
    output reg ack,                  // 应答信号
    input wire [7:0] freq_sel,
    output reg out_clk
);
    reg [7:0] counter;
    reg req_d;                       // 延迟请求信号
    reg handshake_active;            // 握手进行中标志

    wire [7:0] counter_next;
    wire adder_cout;

    han_carlson_adder_8bit u_han_carlson_adder_8bit (
        .a(counter),
        .b(8'd1),
        .sum(counter_next),
        .cout(adder_cout)
    );

    always @(posedge master_clk or negedge rstn) begin
        if (!rstn) begin
            counter <= 8'd0;
            out_clk <= 1'b0;
            ack <= 1'b0;
            req_d <= 1'b0;
            handshake_active <= 1'b0;
        end else begin
            req_d <= req;
            // 握手检测
            if (req && !req_d && !handshake_active) begin
                handshake_active <= 1'b1;
            end

            if (handshake_active) begin
                if (counter >= freq_sel) begin
                    counter <= 8'd0;
                    out_clk <= ~out_clk;
                    ack <= 1'b1;
                    handshake_active <= 1'b0;
                end else begin
                    counter <= counter_next;
                end
            end else begin
                ack <= 1'b0;
            end
        end
    end
endmodule

module han_carlson_adder_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] sum,
    output wire       cout
);
    // Pre-processing
    wire [7:0] g0, p0;
    assign g0 = a & b;
    assign p0 = a ^ b;

    // Stage 1: Black/Gray cells
    wire [7:0] g1, p1;
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

    // Stage 2: Further prefix ops
    wire [7:0] g2, p2;
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

    // Stage 3: Further prefix ops
    wire [7:0] g3;
    assign g3[0] = g2[0];
    assign g3[1] = g2[1];
    assign g3[2] = g2[2];
    assign g3[3] = g2[3];
    assign g3[4] = g2[4] | (p2[4] & g2[0]);
    assign g3[5] = g2[5] | (p2[5] & g2[1]);
    assign g3[6] = g2[6] | (p2[6] & g2[2]);
    assign g3[7] = g2[7] | (p2[7] & g2[3]);

    // Carry
    wire [7:0] carry;
    assign carry[0] = 1'b0;
    assign carry[1] = g0[0];
    assign carry[2] = g1[1];
    assign carry[3] = g2[2];
    assign carry[4] = g3[3];
    assign carry[5] = g3[4];
    assign carry[6] = g3[5];
    assign carry[7] = g3[6];

    // Sum
    assign sum[0] = p0[0] ^ carry[0];
    assign sum[1] = p0[1] ^ carry[1];
    assign sum[2] = p0[2] ^ carry[2];
    assign sum[3] = p0[3] ^ carry[3];
    assign sum[4] = p0[4] ^ carry[4];
    assign sum[5] = p0[5] ^ carry[5];
    assign sum[6] = p0[6] ^ carry[6];
    assign sum[7] = p0[7] ^ carry[7];

    assign cout = g3[7];
endmodule