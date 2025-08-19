//SystemVerilog
module nibble_rotation_shifter_axi_stream #(
    parameter DATA_WIDTH = 16
)(
    input  wire                  aclk,
    input  wire                  aresetn,
    // AXI-Stream slave (input) interface
    input  wire [DATA_WIDTH-1:0] s_axis_tdata,
    input  wire [1:0]            s_axis_tuser_nibble_sel,
    input  wire [1:0]            s_axis_tuser_specific_nibble,
    input  wire [1:0]            s_axis_tuser_rotate_amount,
    input  wire                  s_axis_tvalid,
    output wire                  s_axis_tready,
    // AXI-Stream master (output) interface
    output wire [DATA_WIDTH-1:0] m_axis_tdata,
    output wire                  m_axis_tvalid,
    input  wire                  m_axis_tready,
    output wire                  m_axis_tlast
);

    // Internal handshaking and pipeline registers
    reg [DATA_WIDTH-1:0] data_reg;
    reg [1:0] nibble_sel_reg;
    reg [1:0] specific_nibble_reg;
    reg [1:0] rotate_amount_reg;
    reg       data_valid_reg;
    reg       last_reg;

    wire      load_data;
    assign load_data = s_axis_tvalid && s_axis_tready;

    // Input handshake
    assign s_axis_tready = !data_valid_reg || (m_axis_tvalid && m_axis_tready);

    // AXI-Stream output handshake
    assign m_axis_tvalid = data_valid_reg;
    assign m_axis_tlast  = last_reg;

    // Pipeline data capture
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            data_reg            <= {DATA_WIDTH{1'b0}};
            nibble_sel_reg      <= 2'b00;
            specific_nibble_reg <= 2'b00;
            rotate_amount_reg   <= 2'b00;
            data_valid_reg      <= 1'b0;
            last_reg            <= 1'b0;
        end else begin
            if (load_data) begin
                data_reg            <= s_axis_tdata;
                nibble_sel_reg      <= s_axis_tuser_nibble_sel;
                specific_nibble_reg <= s_axis_tuser_specific_nibble;
                rotate_amount_reg   <= s_axis_tuser_rotate_amount;
                data_valid_reg      <= 1'b1;
                last_reg            <= 1'b1; // Single transfer per beat (can be adjusted)
            end else if (m_axis_tvalid && m_axis_tready) begin
                data_valid_reg      <= 1'b0;
                last_reg            <= 1'b0;
            end
        end
    end

    // Nibble extraction
    wire [3:0] nibble0 = data_reg[3:0];
    wire [3:0] nibble1 = data_reg[7:4];
    wire [3:0] nibble2 = data_reg[11:8];
    wire [3:0] nibble3 = data_reg[15:12];

    // Multiplexer for rotated_nibble0
    reg [3:0] rotated_nibble0_mux;
    always @(*) begin
        if (rotate_amount_reg == 2'b00)
            rotated_nibble0_mux = nibble0;
        else if (rotate_amount_reg == 2'b01)
            rotated_nibble0_mux = {nibble0[2:0], nibble0[3]};
        else if (rotate_amount_reg == 2'b10)
            rotated_nibble0_mux = {nibble0[1:0], nibble0[3:2]};
        else if (rotate_amount_reg == 2'b11)
            rotated_nibble0_mux = {nibble0[0], nibble0[3:1]};
        else
            rotated_nibble0_mux = nibble0;
    end

    // Multiplexer for rotated_nibble1
    reg [3:0] rotated_nibble1_mux;
    always @(*) begin
        if (rotate_amount_reg == 2'b00)
            rotated_nibble1_mux = nibble1;
        else if (rotate_amount_reg == 2'b01)
            rotated_nibble1_mux = {nibble1[2:0], nibble1[3]};
        else if (rotate_amount_reg == 2'b10)
            rotated_nibble1_mux = {nibble1[1:0], nibble1[3:2]};
        else if (rotate_amount_reg == 2'b11)
            rotated_nibble1_mux = {nibble1[0], nibble1[3:1]};
        else
            rotated_nibble1_mux = nibble1;
    end

    // Multiplexer for rotated_nibble2
    reg [3:0] rotated_nibble2_mux;
    always @(*) begin
        if (rotate_amount_reg == 2'b00)
            rotated_nibble2_mux = nibble2;
        else if (rotate_amount_reg == 2'b01)
            rotated_nibble2_mux = {nibble2[2:0], nibble2[3]};
        else if (rotate_amount_reg == 2'b10)
            rotated_nibble2_mux = {nibble2[1:0], nibble2[3:2]};
        else if (rotate_amount_reg == 2'b11)
            rotated_nibble2_mux = {nibble2[0], nibble2[3:1]};
        else
            rotated_nibble2_mux = nibble2;
    end

    // Multiplexer for rotated_nibble3
    reg [3:0] rotated_nibble3_mux;
    always @(*) begin
        if (rotate_amount_reg == 2'b00)
            rotated_nibble3_mux = nibble3;
        else if (rotate_amount_reg == 2'b01)
            rotated_nibble3_mux = {nibble3[2:0], nibble3[3]};
        else if (rotate_amount_reg == 2'b10)
            rotated_nibble3_mux = {nibble3[1:0], nibble3[3:2]};
        else if (rotate_amount_reg == 2'b11)
            rotated_nibble3_mux = {nibble3[0], nibble3[3:1]};
        else
            rotated_nibble3_mux = nibble3;
    end

    reg [DATA_WIDTH-1:0] result_reg;

    // Multiplexer for result_reg
    always @(*) begin
        if (nibble_sel_reg == 2'b00) begin
            result_reg = {rotated_nibble3_mux, rotated_nibble2_mux, rotated_nibble1_mux, rotated_nibble0_mux};
        end else if (nibble_sel_reg == 2'b01) begin
            result_reg = {rotated_nibble3_mux, rotated_nibble2_mux, nibble1, nibble0};
        end else if (nibble_sel_reg == 2'b10) begin
            result_reg = {nibble3, nibble2, rotated_nibble1_mux, rotated_nibble0_mux};
        end else if (nibble_sel_reg == 2'b11) begin
            if (specific_nibble_reg == 2'b00)
                result_reg = {nibble3, nibble2, nibble1, rotated_nibble0_mux};
            else if (specific_nibble_reg == 2'b01)
                result_reg = {nibble3, nibble2, rotated_nibble1_mux, nibble0};
            else if (specific_nibble_reg == 2'b10)
                result_reg = {nibble3, rotated_nibble2_mux, nibble1, nibble0};
            else if (specific_nibble_reg == 2'b11)
                result_reg = {rotated_nibble3_mux, nibble2, nibble1, nibble0};
            else
                result_reg = data_reg;
        end else begin
            result_reg = data_reg;
        end
    end

    assign m_axis_tdata = result_reg;

endmodule