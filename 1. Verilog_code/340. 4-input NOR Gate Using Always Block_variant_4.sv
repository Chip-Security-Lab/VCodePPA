//SystemVerilog
module nor4_axi_stream (
    input  wire                 aclk,
    input  wire                 aresetn,
    input  wire [7:0]           s_axis_a_tdata,
    input  wire                 s_axis_a_tvalid,
    output wire                 s_axis_a_tready,
    input  wire [7:0]           s_axis_b_tdata,
    input  wire                 s_axis_b_tvalid,
    output wire                 s_axis_b_tready,
    output reg  [15:0]          m_axis_y_tdata,
    output reg                  m_axis_y_tvalid,
    input  wire                 m_axis_y_tready
);

    reg [7:0] operand_a_reg;
    reg [7:0] operand_b_reg;
    reg       input_valid_reg;
    reg       input_ready_reg;
    reg       processing_reg;
    reg [3:0] bit_index_reg;
    reg signed [15:0] product_reg;
    wire input_handshake;
    wire output_handshake;

    assign input_handshake  = s_axis_a_tvalid && s_axis_b_tvalid && input_ready_reg;
    assign output_handshake = m_axis_y_tvalid && m_axis_y_tready;

    assign s_axis_a_tready = input_ready_reg;
    assign s_axis_b_tready = input_ready_reg;

    always @(posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            operand_a_reg   <= 8'sd0;
            operand_b_reg   <= 8'sd0;
            input_valid_reg <= 1'b0;
            input_ready_reg <= 1'b1;
            processing_reg  <= 1'b0;
            bit_index_reg   <= 4'd0;
            product_reg     <= 16'sd0;
            m_axis_y_tdata  <= 16'sd0;
            m_axis_y_tvalid <= 1'b0;
        end else begin
            // Input handshake: latch inputs
            if (input_handshake && input_ready_reg) begin
                operand_a_reg   <= s_axis_a_tdata;
                operand_b_reg   <= s_axis_b_tdata;
                product_reg     <= 16'sd0;
                bit_index_reg   <= 4'd0;
                processing_reg  <= 1'b1;
                input_ready_reg <= 1'b0;
                input_valid_reg <= 1'b1;
                m_axis_y_tvalid <= 1'b0;
            end

            // Processing multiplication (shift-add, sequential for PPA optimization)
            if (processing_reg) begin
                if (bit_index_reg < 8) begin
                    if (operand_b_reg[bit_index_reg]) begin
                        product_reg <= product_reg + ($signed(operand_a_reg) <<< bit_index_reg);
                    end
                    bit_index_reg <= bit_index_reg + 1'b1;
                end else begin
                    m_axis_y_tdata  <= product_reg;
                    m_axis_y_tvalid <= 1'b1;
                    processing_reg  <= 1'b0;
                end
            end

            // Output handshake: output accepted
            if (output_handshake) begin
                m_axis_y_tvalid <= 1'b0;
                input_ready_reg <= 1'b1;
                input_valid_reg <= 1'b0;
            end
        end
    end

endmodule