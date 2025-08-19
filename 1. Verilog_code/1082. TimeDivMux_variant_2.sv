//SystemVerilog
// Top-level TimeDivMux module with hierarchical structure

module TimeDivMux #(parameter DW=8) (
    input                  clk,
    input                  rst,
    input  [3:0][DW-1:0]   ch,
    output reg [DW-1:0]    out
);
    // Internal state signals
    wire [1:0]             cnt_next;
    reg  [1:0]             cnt_q;
    wire [DW-1:0]          mux_out;

    // Submodule interface signals
    wire [3:0]             sum;
    wire                   cout;

    // Counter Incrementer: 2-bit counter with 4-bit Brent-Kung adder
    Counter_Incrementer u_counter (
        .clk      (clk),
        .rst      (rst),
        .cnt_q    (cnt_q),
        .cnt_next (cnt_next),
        .sum      (sum)
    );

    // Time Division Multiplexer: Select channel based on cnt_q
    Channel_Mux #(.DW(DW)) u_mux (
        .sel      (cnt_q),
        .ch       (ch),
        .mux_out  (mux_out)
    );

    // Output Register: Register the muxed output
    Output_Register #(.DW(DW)) u_outreg (
        .clk      (clk),
        .rst      (rst),
        .data_in  (mux_out),
        .data_out (out)
    );

    // Update state register
    always @(posedge clk) begin
        if (rst)
            cnt_q <= 2'b00;
        else
            cnt_q <= cnt_next;
    end

endmodule

// -----------------------------------------------------------------------------
// Counter_Incrementer
// Function: Increments 2-bit counter using a 4-bit Brent-Kung adder
// -----------------------------------------------------------------------------
module Counter_Incrementer (
    input        clk,
    input        rst,
    input  [1:0] cnt_q,
    output [1:0] cnt_next,
    output [3:0] sum
);
    wire [3:0] a, b;
    wire       cout;

    assign a = {2'b00, cnt_q};   // Zero-extend 2-bit counter to 4 bits
    assign b = 4'b0001;          // Increment by 1

    brent_kung_adder_4bit u_bk_adder (
        .a    (a),
        .b    (b),
        .cin  (1'b0),
        .sum  (sum),
        .cout (cout)
    );

    assign cnt_next = sum[1:0];
endmodule

// -----------------------------------------------------------------------------
// Channel_Mux
// Function: 4-to-1 multiplexer selecting one of four DW-bit channels
// -----------------------------------------------------------------------------
module Channel_Mux #(parameter DW=8) (
    input      [1:0]      sel,
    input      [3:0][DW-1:0] ch,
    output reg [DW-1:0]   mux_out
);
    always @(*) begin
        case (sel)
            2'd0: mux_out = ch[0];
            2'd1: mux_out = ch[1];
            2'd2: mux_out = ch[2];
            2'd3: mux_out = ch[3];
            default: mux_out = {DW{1'b0}};
        endcase
    end
endmodule

// -----------------------------------------------------------------------------
// Output_Register
// Function: Synchronous register for output data
// -----------------------------------------------------------------------------
module Output_Register #(parameter DW=8) (
    input              clk,
    input              rst,
    input  [DW-1:0]    data_in,
    output reg [DW-1:0] data_out
);
    always @(posedge clk) begin
        if (rst)
            data_out <= {DW{1'b0}};
        else
            data_out <= data_in;
    end
endmodule

// -----------------------------------------------------------------------------
// brent_kung_adder_4bit
// Function: 4-bit Brent-Kung parallel-prefix adder
// -----------------------------------------------------------------------------
module brent_kung_adder_4bit (
    input  [3:0] a,
    input  [3:0] b,
    input        cin,
    output [3:0] sum,
    output       cout
);
    wire [3:0] p, g;
    wire [3:0] c;

    // Generate and Propagate
    assign p = a ^ b;
    assign g = a & b;

    // Level 1
    wire g1_0, p1_0;
    assign g1_0 = g[1] | (p[1] & g[0]);
    assign p1_0 = p[1] & p[0];

    wire g3_2, p3_2;
    assign g3_2 = g[3] | (p[3] & g[2]);
    assign p3_2 = p[3] & p[2];

    // Level 2
    wire g2_0, p2_0;
    assign g2_0 = g[2] | (p[2] & g1_0);
    assign p2_0 = p[2] & p1_0;

    wire g3_1;
    assign g3_1 = g[3] | (p[3] & g1_0);

    // Carry chain
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & cin);
    assign c[2] = g1_0 | (p1_0 & cin);
    assign c[3] = g2_0 | (p2_0 & cin);
    assign cout = g3_1 | (p[3] & p1_0 & cin);

    assign sum = p ^ c;

endmodule