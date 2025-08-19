//SystemVerilog
module var_dir_shifter_axi_stream #(
    parameter DATA_WIDTH = 16
)(
    input                      clk,
    input                      rst_n,
    // AXI-Stream Slave Interface (Input)
    input  [DATA_WIDTH-1:0]    s_axis_tdata,
    input  [3:0]               s_axis_tuser_shift_amt,
    input                      s_axis_tuser_dir,         // 0:right, 1:left
    input                      s_axis_tuser_fill,
    input                      s_axis_tvalid,
    output                     s_axis_tready,
    // AXI-Stream Master Interface (Output)
    output [DATA_WIDTH-1:0]    m_axis_tdata,
    output                     m_axis_tvalid,
    input                      m_axis_tready,
    output                     m_axis_tlast
);

    // Internal registers for handshake and data
    reg [DATA_WIDTH-1:0]       input_data_reg;
    reg [3:0]                  shift_amt_reg;
    reg                        direction_reg;
    reg                        fill_value_reg;
    reg                        valid_reg;
    reg                        last_reg;

    wire                       input_handshake;
    wire                       output_handshake;

    assign input_handshake  = s_axis_tvalid & s_axis_tready;
    assign output_handshake = m_axis_tvalid & m_axis_tready;

    // Input ready: only ready when output register is not full
    assign s_axis_tready = !valid_reg;

    // Output valid: data is valid when valid_reg is set
    assign m_axis_tvalid = valid_reg;

    // Output TLAST: always 1 for single data beat
    assign m_axis_tlast = last_reg;

    // Output data
    reg [DATA_WIDTH-1:0]       shifted_data;

    // Han-Carlson adder signals (for fill logic, as in original)
    wire [DATA_WIDTH-1:0]      left_fill;
    wire [DATA_WIDTH-1:0]      right_fill;

    han_carlson_adder_16 left_fill_adder (
        .a({DATA_WIDTH{fill_value_reg}}),
        .b({DATA_WIDTH{1'b0}}),
        .cin(1'b0),
        .sum(left_fill),
        .cout()
    );

    han_carlson_adder_16 right_fill_adder (
        .a({DATA_WIDTH{1'b0}}),
        .b({DATA_WIDTH{fill_value_reg}}),
        .cin(1'b0),
        .sum(right_fill),
        .cout()
    );

    // Variable left shift with fill
    function [DATA_WIDTH-1:0] variable_left_shift_fill;
        input [DATA_WIDTH-1:0] data_in;
        input [3:0]            amt;
        input                  fill;
        reg   [DATA_WIDTH-1:0] temp;
        integer i;
        begin
            temp = data_in;
            for (i = 0; i < amt; i = i + 1)
                temp = {temp[DATA_WIDTH-2:0], fill};
            variable_left_shift_fill = temp;
        end
    endfunction

    // Variable right shift with fill
    function [DATA_WIDTH-1:0] variable_right_shift_fill;
        input [DATA_WIDTH-1:0] data_in;
        input [3:0]            amt;
        input                  fill;
        reg   [DATA_WIDTH-1:0] temp;
        integer i;
        begin
            temp = data_in;
            for (i = 0; i < amt; i = i + 1)
                temp = {fill, temp[DATA_WIDTH-1:1]};
            variable_right_shift_fill = temp;
        end
    endfunction

    // Pipeline for input latching and output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_data_reg   <= {DATA_WIDTH{1'b0}};
            shift_amt_reg    <= 4'b0;
            direction_reg    <= 1'b0;
            fill_value_reg   <= 1'b0;
            valid_reg        <= 1'b0;
            last_reg         <= 1'b0;
        end else begin
            // Latch input on handshake
            if (input_handshake) begin
                input_data_reg   <= s_axis_tdata;
                shift_amt_reg    <= s_axis_tuser_shift_amt;
                direction_reg    <= s_axis_tuser_dir;
                fill_value_reg   <= s_axis_tuser_fill;
                valid_reg        <= 1'b1;
                last_reg         <= 1'b1; // always last for single-beat
            end else if (output_handshake) begin
                valid_reg        <= 1'b0;
                last_reg         <= 1'b0;
            end
        end
    end

    // Combinational shifted data logic
    always @(*) begin
        if (direction_reg) begin
            shifted_data = variable_left_shift_fill(input_data_reg, shift_amt_reg, fill_value_reg);
        end else begin
            shifted_data = variable_right_shift_fill(input_data_reg, shift_amt_reg, fill_value_reg);
        end
    end

    assign m_axis_tdata = shifted_data;

endmodule

// Han-Carlson 16-bit Adder Implementation
module han_carlson_adder_16(
    input  [15:0] a,
    input  [15:0] b,
    input         cin,
    output [15:0] sum,
    output        cout
);
    // Generate and Propagate signals
    wire [15:0] G, P;
    assign G = a & b;
    assign P = a ^ b;

    // Level 1
    wire [15:0] H1, K1;
    assign H1[0] = G[0];
    assign K1[0] = P[0];
    genvar i;
    generate
        for (i = 1; i < 16; i = i + 1) begin : level1
            assign H1[i] = G[i] | (P[i] & G[i-1]);
            assign K1[i] = P[i] & P[i-1];
        end
    endgenerate

    // Level 2
    wire [15:0] H2, K2;
    assign H2[0] = H1[0];
    assign K2[0] = K1[0];
    assign H2[1] = H1[1];
    assign K2[1] = K1[1];
    generate
        for (i = 2; i < 16; i = i + 1) begin : level2
            assign H2[i] = H1[i] | (K1[i] & H1[i-2]);
            assign K2[i] = K1[i] & K1[i-2];
        end
    endgenerate

    // Level 3
    wire [15:0] H3, K3;
    assign H3[0] = H2[0];
    assign K3[0] = K2[0];
    assign H3[1] = H2[1];
    assign K3[1] = K2[1];
    assign H3[2] = H2[2];
    assign K3[2] = K2[2];
    assign H3[3] = H2[3];
    assign K3[3] = K2[3];
    generate
        for (i = 4; i < 16; i = i + 1) begin : level3
            assign H3[i] = H2[i] | (K2[i] & H2[i-4]);
            assign K3[i] = K2[i] & K2[i-4];
        end
    endgenerate

    // Level 4
    wire [15:0] H4, K4;
    assign H4[0] = H3[0];
    assign K4[0] = K3[0];
    assign H4[1] = H3[1];
    assign K4[1] = K3[1];
    assign H4[2] = H3[2];
    assign K4[2] = K3[2];
    assign H4[3] = H3[3];
    assign K4[3] = K3[3];
    assign H4[4] = H3[4];
    assign K4[4] = K3[4];
    assign H4[5] = H3[5];
    assign K4[5] = K3[5];
    assign H4[6] = H3[6];
    assign K4[6] = K3[6];
    assign H4[7] = H3[7];
    assign K4[7] = K3[7];
    generate
        for (i = 8; i < 16; i = i + 1) begin : level4
            assign H4[i] = H3[i] | (K3[i] & H3[i-8]);
            assign K4[i] = K3[i] & K3[i-8];
        end
    endgenerate

    // Pre-compute carries
    wire [16:0] carry;
    assign carry[0] = cin;
    assign carry[1] = H4[0] | (K4[0] & cin);
    assign carry[2] = H4[1] | (K4[1] & carry[1]);
    assign carry[3] = H4[2] | (K4[2] & carry[2]);
    assign carry[4] = H4[3] | (K4[3] & carry[3]);
    assign carry[5] = H4[4] | (K4[4] & carry[4]);
    assign carry[6] = H4[5] | (K4[5] & carry[5]);
    assign carry[7] = H4[6] | (K4[6] & carry[6]);
    assign carry[8] = H4[7] | (K4[7] & carry[7]);
    assign carry[9] = H4[8] | (K4[8] & carry[8]);
    assign carry[10] = H4[9] | (K4[9] & carry[9]);
    assign carry[11] = H4[10] | (K4[10] & carry[10]);
    assign carry[12] = H4[11] | (K4[11] & carry[11]);
    assign carry[13] = H4[12] | (K4[12] & carry[12]);
    assign carry[14] = H4[13] | (K4[13] & carry[13]);
    assign carry[15] = H4[14] | (K4[14] & carry[14]);
    assign carry[16] = H4[15] | (K4[15] & carry[15]);

    // Sum
    assign sum[0]  = P[0]  ^ carry[0];
    assign sum[1]  = P[1]  ^ carry[1];
    assign sum[2]  = P[2]  ^ carry[2];
    assign sum[3]  = P[3]  ^ carry[3];
    assign sum[4]  = P[4]  ^ carry[4];
    assign sum[5]  = P[5]  ^ carry[5];
    assign sum[6]  = P[6]  ^ carry[6];
    assign sum[7]  = P[7]  ^ carry[7];
    assign sum[8]  = P[8]  ^ carry[8];
    assign sum[9]  = P[9]  ^ carry[9];
    assign sum[10] = P[10] ^ carry[10];
    assign sum[11] = P[11] ^ carry[11];
    assign sum[12] = P[12] ^ carry[12];
    assign sum[13] = P[13] ^ carry[13];
    assign sum[14] = P[14] ^ carry[14];
    assign sum[15] = P[15] ^ carry[15];

    assign cout = carry[16];

endmodule