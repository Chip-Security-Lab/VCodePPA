//SystemVerilog
module sign_extension_shifter_axi_stream #(
    parameter DATA_WIDTH = 16,
    parameter SHIFT_WIDTH = 4
)(
    input                        aclk,
    input                        aresetn,
    // AXI-Stream Slave Interface (Input)
    input  [DATA_WIDTH-1:0]      s_axis_tdata,
    input  [SHIFT_WIDTH-1:0]     s_axis_tuser_shift,
    input                        s_axis_tuser_sign_extend,
    input                        s_axis_tvalid,
    output                       s_axis_tready,
    // AXI-Stream Master Interface (Output)
    output [DATA_WIDTH-1:0]      m_axis_tdata,
    output                       m_axis_tvalid,
    input                        m_axis_tready,
    output                       m_axis_tlast
);

    // Internal registers for pipelining
    reg [DATA_WIDTH-1:0]         input_data_reg;
    reg [SHIFT_WIDTH-1:0]        shift_right_reg;
    reg                          sign_extend_reg;
    reg                          valid_reg;
    wire                         ready_for_input;

    // AXI-Stream handshake: ready when output is ready or not holding data
    assign ready_for_input = !valid_reg || (m_axis_tready && valid_reg);
    assign s_axis_tready = ready_for_input;

    // Data latch on handshake
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            input_data_reg  <= {DATA_WIDTH{1'b0}};
            shift_right_reg <= {SHIFT_WIDTH{1'b0}};
            sign_extend_reg <= 1'b0;
            valid_reg       <= 1'b0;
        end else if (ready_for_input) begin
            if (s_axis_tvalid) begin
                input_data_reg  <= s_axis_tdata;
                shift_right_reg <= s_axis_tuser_shift;
                sign_extend_reg <= s_axis_tuser_sign_extend;
                valid_reg       <= 1'b1;
            end else begin
                valid_reg <= 1'b0;
            end
        end
    end

    // Instantiate reusable shifter/sign extender module
    wire [DATA_WIDTH-1:0] shift_logic_out;
    shift_sign_extend #(
        .DATA_WIDTH(DATA_WIDTH),
        .SHIFT_WIDTH(SHIFT_WIDTH)
    ) u_shift_sign_extend (
        .data_in      (input_data_reg),
        .shift_amount (shift_right_reg),
        .sign_extend  (sign_extend_reg),
        .data_out     (shift_logic_out)
    );

    // Output logic for AXI-Stream master interface
    reg [DATA_WIDTH-1:0]         result_data_reg;
    reg                          result_valid_reg;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            result_data_reg   <= {DATA_WIDTH{1'b0}};
            result_valid_reg  <= 1'b0;
        end else begin
            if (valid_reg && ready_for_input) begin
                result_data_reg  <= shift_logic_out;
                result_valid_reg <= 1'b1;
            end else if (m_axis_tready && result_valid_reg) begin
                result_valid_reg <= 1'b0;
            end
        end
    end

    assign m_axis_tdata  = result_data_reg;
    assign m_axis_tvalid = result_valid_reg;
    assign m_axis_tlast  = 1'b1; // Single transfer per transaction

endmodule

// Reusable parameterized shifter and sign extender module
module shift_sign_extend #(
    parameter DATA_WIDTH = 16,
    parameter SHIFT_WIDTH = 4
)(
    input  [DATA_WIDTH-1:0]  data_in,
    input  [SHIFT_WIDTH-1:0] shift_amount,
    input                    sign_extend,
    output [DATA_WIDTH-1:0]  data_out
);

    wire sign_bit = data_in[DATA_WIDTH-1];

    reg [DATA_WIDTH-1:0] shift_result;
    reg [DATA_WIDTH-1:0] sign_extend_result;
    integer i;

    always @(*) begin
        // Logical right shift
        shift_result = data_in >> shift_amount;
        // Fill vacated bits with zeros
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin
            if (i >= DATA_WIDTH - shift_amount)
                shift_result[i] = 1'b0;
        end
    end

    always @(*) begin
        // Shift and fill with sign bit if sign_extend requested
        sign_extend_result = data_in >> shift_amount;
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin
            if (i >= DATA_WIDTH - shift_amount)
                sign_extend_result[i] = sign_bit;
        end
    end

    assign data_out = sign_extend ? sign_extend_result : shift_result;

endmodule