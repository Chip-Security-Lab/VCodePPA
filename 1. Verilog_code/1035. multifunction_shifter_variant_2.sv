//SystemVerilog
module multifunction_shifter_axi_stream (
    input  wire         aclk,
    input  wire         aresetn,

    // AXI-Stream Slave Interface (Input)
    input  wire [31:0]  s_axis_operand_tdata,
    input  wire [4:0]   s_axis_shift_amt_tdata,
    input  wire [1:0]   s_axis_operation_tdata,
    input  wire         s_axis_tvalid,
    output wire         s_axis_tready,
    input  wire         s_axis_tlast, // Optional, not used in this module

    // AXI-Stream Master Interface (Output)
    output reg  [31:0]  m_axis_shifted_tdata,
    output reg          m_axis_tvalid,
    input  wire         m_axis_tready,
    output reg          m_axis_tlast // Always 1'b1 for single-beat output
);

    // Internal pipeline registers
    reg  [31:0] operand_reg;
    reg  [4:0]  shift_amt_reg;
    reg  [1:0]  operation_reg;
    reg         operand_valid_reg;
    reg         operand_last_reg;

    // Input AXI-Stream handshake
    assign s_axis_tready = ~operand_valid_reg || (m_axis_tvalid && m_axis_tready);

    // Register the input when handshake occurs
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            operand_reg       <= 32'b0;
            shift_amt_reg     <= 5'b0;
            operation_reg     <= 2'b0;
            operand_valid_reg <= 1'b0;
            operand_last_reg  <= 1'b0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            operand_reg       <= s_axis_operand_tdata;
            shift_amt_reg     <= s_axis_shift_amt_tdata;
            operation_reg     <= s_axis_operation_tdata;
            operand_valid_reg <= 1'b1;
            operand_last_reg  <= s_axis_tlast;
        end else if (m_axis_tvalid && m_axis_tready) begin
            operand_valid_reg <= 1'b0;
        end
    end

    // Stage 2: Preprocessing
    reg sign_reg;
    reg [63:0] rotate_operand_reg;
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            sign_reg            <= 1'b0;
            rotate_operand_reg  <= 64'b0;
        end else if (operand_valid_reg && (m_axis_tvalid && m_axis_tready || !m_axis_tvalid)) begin
            sign_reg           <= operand_reg[31];
            rotate_operand_reg <= {operand_reg, operand_reg};
        end
    end

    // Stage 3: Barrel Shifters
    wire [31:0] logical_shift_1, logical_shift_2, logical_shift_3, logical_shift_4, logical_shift_5;
    assign logical_shift_1 = shift_amt_reg[0] ? {1'b0, operand_reg[31:1]}   : operand_reg;
    assign logical_shift_2 = shift_amt_reg[1] ? {2'b00, logical_shift_1[31:2]} : logical_shift_1;
    assign logical_shift_3 = shift_amt_reg[2] ? {4'b0000, logical_shift_2[31:4]} : logical_shift_2;
    assign logical_shift_4 = shift_amt_reg[3] ? {8'b00000000, logical_shift_3[31:8]} : logical_shift_3;
    assign logical_shift_5 = shift_amt_reg[4] ? {16'b0, logical_shift_4[31:16]} : logical_shift_4;

    wire [31:0] arithmetic_shift_1, arithmetic_shift_2, arithmetic_shift_3, arithmetic_shift_4, arithmetic_shift_5;
    assign arithmetic_shift_1 = shift_amt_reg[0] ? {{1{sign_reg}}, operand_reg[31:1]} : operand_reg;
    assign arithmetic_shift_2 = shift_amt_reg[1] ? {{2{sign_reg}}, arithmetic_shift_1[31:2]} : arithmetic_shift_1;
    assign arithmetic_shift_3 = shift_amt_reg[2] ? {{4{sign_reg}}, arithmetic_shift_2[31:4]} : arithmetic_shift_2;
    assign arithmetic_shift_4 = shift_amt_reg[3] ? {{8{sign_reg}}, arithmetic_shift_3[31:8]} : arithmetic_shift_3;
    assign arithmetic_shift_5 = shift_amt_reg[4] ? {{16{sign_reg}}, arithmetic_shift_4[31:16]} : arithmetic_shift_4;

    wire [63:0] rotate_shift_1, rotate_shift_2, rotate_shift_3, rotate_shift_4, rotate_shift_5;
    assign rotate_shift_1 = shift_amt_reg[0] ? {1'b0, rotate_operand_reg[63:1]} : rotate_operand_reg;
    assign rotate_shift_2 = shift_amt_reg[1] ? {2'b00, rotate_shift_1[63:2]} : rotate_shift_1;
    assign rotate_shift_3 = shift_amt_reg[2] ? {4'b0000, rotate_shift_2[63:4]} : rotate_shift_2;
    assign rotate_shift_4 = shift_amt_reg[3] ? {8'b00000000, rotate_shift_3[63:8]} : rotate_shift_3;
    assign rotate_shift_5 = shift_amt_reg[4] ? {16'b0, rotate_shift_4[63:16]} : rotate_shift_4;

    reg [31:0] logical_shifted_reg;
    reg [31:0] arithmetic_shifted_reg;
    reg [31:0] rotate_shifted_reg;
    reg [31:0] byte_swapped_reg;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            logical_shifted_reg    <= 32'b0;
            arithmetic_shifted_reg <= 32'b0;
            rotate_shifted_reg     <= 32'b0;
            byte_swapped_reg       <= 32'b0;
        end else if (operand_valid_reg && (m_axis_tvalid && m_axis_tready || !m_axis_tvalid)) begin
            logical_shifted_reg    <= logical_shift_5;
            arithmetic_shifted_reg <= arithmetic_shift_5;
            rotate_shifted_reg     <= rotate_shift_5[31:0];
            byte_swapped_reg       <= {operand_reg[15:0], operand_reg[31:16]};
        end
    end

    // Output selection and handshake
    reg output_valid_reg;
    reg output_last_reg;
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            m_axis_shifted_tdata <= 32'b0;
            m_axis_tvalid        <= 1'b0;
            m_axis_tlast         <= 1'b0;
            output_valid_reg     <= 1'b0;
            output_last_reg      <= 1'b0;
        end else if (operand_valid_reg && (!m_axis_tvalid || (m_axis_tvalid && m_axis_tready))) begin
            case (operation_reg)
                2'b00: m_axis_shifted_tdata <= logical_shifted_reg;
                2'b01: m_axis_shifted_tdata <= arithmetic_shifted_reg;
                2'b10: m_axis_shifted_tdata <= rotate_shifted_reg;
                2'b11: m_axis_shifted_tdata <= byte_swapped_reg;
                default: m_axis_shifted_tdata <= 32'b0;
            endcase
            m_axis_tvalid    <= 1'b1;
            m_axis_tlast     <= operand_last_reg;
            output_valid_reg <= 1'b1;
            output_last_reg  <= operand_last_reg;
        end else if (m_axis_tvalid && m_axis_tready) begin
            m_axis_tvalid    <= 1'b0;
            m_axis_tlast     <= 1'b0;
            output_valid_reg <= 1'b0;
            output_last_reg  <= 1'b0;
        end
    end

endmodule