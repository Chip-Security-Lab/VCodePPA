//SystemVerilog
module compact_spi_slave(
    input  wire        sclk,
    input  wire        cs,
    input  wire        mosi,
    output wire        miso,
    input  wire [7:0]  tx_byte,
    output reg  [7:0]  rx_byte
);
    reg  [7:0] tx_shift;
    reg  [2:0] bit_count;
    reg  [7:0] rx_shift;
    wire [7:0] count_plus_one;

    // Han-Carlson 8-bit adder instantiation for bit_count + 1
    han_carlson_adder_8bit u_han_carlson_adder_8bit (
        .a    ({5'd0, bit_count}),
        .b    (8'd1),
        .sum  (count_plus_one),
        .cin  (1'b0)
    );

    assign miso = tx_shift[7];

    always @(posedge sclk or posedge cs) begin
        if (cs) begin
            bit_count <= 3'b000;
            tx_shift  <= tx_byte;
            rx_shift  <= 8'b0;
            rx_byte   <= 8'b0;
        end else begin
            rx_shift  <= {rx_shift[6:0], mosi};
            tx_shift  <= {tx_shift[6:0], 1'b0};
            bit_count <= count_plus_one[2:0];
            if (count_plus_one[2:0] == 3'b111)
                rx_byte <= {rx_shift[6:0], mosi};
        end
    end
endmodule

// Han-Carlson 8-bit adder module
module han_carlson_adder_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] sum,
    input  wire       cin
);
    wire [7:0] g, p;
    wire [7:0] c;

    // Preprocessing
    assign p = a ^ b;
    assign g = a & b;

    // Black cells and gray cells for Han-Carlson structure
    // Stage 1
    wire [7:0] g1, p1;
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin : gen_g1p1
            assign g1[i] = g[i] | (p[i] & g[i-1]);
            assign p1[i] = p[i] & p[i-1];
        end
    endgenerate

    // Stage 2
    wire [7:0] g2, p2;
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    generate
        for (i = 2; i < 8; i = i + 1) begin : gen_g2p2
            assign g2[i] = g1[i] | (p1[i] & g1[i-2]);
            assign p2[i] = p1[i] & p1[i-2];
        end
    endgenerate

    // Stage 3
    wire [7:0] g3;
    assign g3[0] = g2[0];
    assign g3[1] = g2[1];
    assign g3[2] = g2[2];
    assign g3[3] = g2[3];
    assign g3[4] = g2[4] | (p2[4] & g2[0]);
    assign g3[5] = g2[5] | (p2[5] & g2[1]);
    assign g3[6] = g2[6] | (p2[6] & g2[2]);
    assign g3[7] = g2[7] | (p2[7] & g2[3]);

    // Carry generation
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & cin);
    assign c[2] = g1[1] | (p1[1] & cin);
    assign c[3] = g2[2] | (p2[2] & cin);
    assign c[4] = g3[3] | (p2[3] & cin);
    assign c[5] = g3[4] | (p2[4] & cin);
    assign c[6] = g3[5] | (p2[5] & cin);
    assign c[7] = g3[6] | (p2[6] & cin);

    // Sum computation
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];
    assign sum[4] = p[4] ^ c[4];
    assign sum[5] = p[5] ^ c[5];
    assign sum[6] = p[6] ^ c[6];
    assign sum[7] = p[7] ^ c[7];
endmodule