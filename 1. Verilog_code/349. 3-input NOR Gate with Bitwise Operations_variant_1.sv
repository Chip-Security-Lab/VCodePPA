//SystemVerilog
module nor3_bitwise_axi_stream (
    input  wire        clk,
    input  wire        rst_n,
    // AXI-Stream slave interface (input)
    input  wire [2:0]  s_axis_tdata,   // 3-bit input data
    input  wire        s_axis_tvalid,  // Input data valid
    output wire        s_axis_tready,  // Ready to accept input
    // AXI-Stream master interface (output)
    output wire [0:0]  m_axis_tdata,   // 1-bit output data
    output wire        m_axis_tvalid,  // Output data valid
    input  wire        m_axis_tready   // Output ready
);

//====================
// Stage 1: Input Register with TVALID/TREADY handshake
//====================
reg [2:0]  input_reg;
reg        input_valid;
wire       input_ready;

assign input_ready = !input_valid || (output_ready && output_valid);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        input_reg   <= 3'b0;
        input_valid <= 1'b0;
    end else if (input_ready) begin
        input_reg   <= s_axis_tdata;
        input_valid <= s_axis_tvalid;
    end else if (output_ready && output_valid) begin
        input_valid <= 1'b0;
    end
end

assign s_axis_tready = input_ready;

//====================
// Stage 2: OR Reduction
//====================
reg or_result_reg;
reg or_valid;
wire or_ready;

assign or_ready = !or_valid || (output_ready && output_valid);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        or_result_reg <= 1'b0;
        or_valid      <= 1'b0;
    end else if (or_ready) begin
        or_result_reg <= (input_reg[0] | input_reg[1] | input_reg[2]);
        or_valid      <= input_valid;
    end else if (output_ready && output_valid) begin
        or_valid <= 1'b0;
    end
end

//====================
// Stage 3: NOR Output Register
//====================
reg        output_reg;
reg        output_valid;
wire       output_ready;

assign output_ready = m_axis_tready;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        output_reg   <= 1'b0;
        output_valid <= 1'b0;
    end else if (output_ready) begin
        output_reg   <= ~or_result_reg;
        output_valid <= or_valid;
    end else if (output_ready && output_valid) begin
        output_valid <= 1'b0;
    end
end

assign m_axis_tdata  = output_reg;
assign m_axis_tvalid = output_valid;

endmodule