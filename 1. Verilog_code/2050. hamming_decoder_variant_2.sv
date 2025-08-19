//SystemVerilog
module hamming_decoder_axi_stream (
    input wire clk,
    input wire rst_n,
    // AXI-Stream slave (input) interface
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire [6:0]  s_axis_tdata,
    input  wire        s_axis_tlast,
    // AXI-Stream master (output) interface
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready,
    output reg  [3:0]  m_axis_tdata,
    output reg         m_axis_tuser, // error_detected mapped to tuser
    output reg         m_axis_tlast
);

    reg s_axis_handshake;
    reg [6:0] input_reg;
    reg [2:0] syndrome;
    wire [6:0] booth_mul_a;
    wire [6:0] booth_mul_b;
    wire [13:0] booth_product;
    reg error_detected;

    // AXI-Stream handshake logic
    assign s_axis_tready = !s_axis_handshake || (m_axis_tvalid && m_axis_tready);

    assign booth_mul_a = input_reg;
    assign booth_mul_b = {input_reg[3:0], input_reg[3:1]};

    // Booth multiplier instance
    booth_multiplier_7bit booth_mult_inst (
        .multiplicand(booth_mul_a),
        .multiplier(booth_mul_b),
        .product(booth_product)
    );

    // Input register and handshake logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_reg        <= 7'd0;
            s_axis_handshake <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                input_reg        <= s_axis_tdata;
                s_axis_handshake <= 1'b1;
            end else if (m_axis_tvalid && m_axis_tready) begin
                s_axis_handshake <= 1'b0;
            end
        end
    end

    // Output AXI-Stream signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tdata  <= 4'd0;
            m_axis_tuser  <= 1'b0;
            m_axis_tlast  <= 1'b0;
            syndrome      <= 3'd0;
            error_detected<= 1'b0;
        end else begin
            if (s_axis_handshake && (!m_axis_tvalid || (m_axis_tvalid && m_axis_tready))) begin
                syndrome[0]      <= input_reg[0] ^ input_reg[2] ^ input_reg[4] ^ input_reg[6];
                syndrome[1]      <= input_reg[1] ^ input_reg[2] ^ input_reg[5] ^ input_reg[6];
                syndrome[2]      <= input_reg[3] ^ input_reg[4] ^ input_reg[5] ^ input_reg[6];
                error_detected   <= |({input_reg[0] ^ input_reg[2] ^ input_reg[4] ^ input_reg[6],
                                       input_reg[1] ^ input_reg[2] ^ input_reg[5] ^ input_reg[6],
                                       input_reg[3] ^ input_reg[4] ^ input_reg[5] ^ input_reg[6]});
                m_axis_tdata     <= {input_reg[6], input_reg[5], input_reg[4], input_reg[2]};
                m_axis_tuser     <= |({input_reg[0] ^ input_reg[2] ^ input_reg[4] ^ input_reg[6],
                                       input_reg[1] ^ input_reg[2] ^ input_reg[5] ^ input_reg[6],
                                       input_reg[3] ^ input_reg[4] ^ input_reg[5] ^ input_reg[6]});
                m_axis_tlast     <= s_axis_tlast;
                m_axis_tvalid    <= 1'b1;
            end else if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid    <= 1'b0;
            end
        end
    end

endmodule

module booth_multiplier_7bit (
    input  wire [6:0] multiplicand,
    input  wire [6:0] multiplier,
    output reg  [13:0] product
);
    reg [14:0] booth_accumulator;
    reg [7:0]  booth_multiplier_reg;
    reg [6:0]  booth_multiplicand_reg;
    integer    i;

    always @(*) begin
        booth_accumulator = 15'd0;
        booth_multiplier_reg = {multiplier, 1'b0}; // Append extra zero for Booth encoding
        booth_multiplicand_reg = multiplicand;

        for (i = 0; i < 7; i = i + 1) begin
            case ({booth_multiplier_reg[i+1], booth_multiplier_reg[i]})
                2'b01: booth_accumulator[14:7] = booth_accumulator[14:7] + booth_multiplicand_reg;
                2'b10: booth_accumulator[14:7] = booth_accumulator[14:7] - booth_multiplicand_reg;
                default: ; // No operation
            endcase
            // Arithmetic right shift accumulator and multiplier
            booth_accumulator = {booth_accumulator[14], booth_accumulator[14:1]};
        end
        product = booth_accumulator[13:0];
    end
endmodule