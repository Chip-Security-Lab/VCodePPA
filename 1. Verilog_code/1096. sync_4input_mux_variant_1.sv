//SystemVerilog
module sync_4input_mux_axi_stream (
    input  wire        clk,               // Clock input
    input  wire        rst_n,             // Active-low synchronous reset
    input  wire        s_axis_tvalid,     // AXI-Stream TVALID (input handshake)
    output wire        s_axis_tready,     // AXI-Stream TREADY (output handshake)
    input  wire [3:0]  s_axis_tdata,      // AXI-Stream TDATA (4-bit input data)
    input  wire [1:0]  s_axis_tuser,      // AXI-Stream TUSER (2-bit address)
    output wire        m_axis_tvalid,     // AXI-Stream TVALID (output handshake)
    input  wire        m_axis_tready,     // AXI-Stream TREADY (input handshake)
    output wire [0:0]  m_axis_tdata,      // AXI-Stream TDATA (1-bit output)
    output wire        m_axis_tlast       // AXI-Stream TLAST (set to 1'b1 for single data beat)
);

//----------------------------------------
// Pipeline Stage 1: Input Capture
//----------------------------------------
reg [3:0] data_stage1;
reg [1:0] addr_stage1;
reg       valid_stage1;
reg       ready_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_stage1  <= 4'b0;
        addr_stage1  <= 2'b0;
        valid_stage1 <= 1'b0;
        ready_stage1 <= 1'b1;
    end else begin
        if (s_axis_tvalid && ready_stage1) begin
            data_stage1  <= s_axis_tdata;
            addr_stage1  <= s_axis_tuser;
            valid_stage1 <= 1'b1;
            ready_stage1 <= 1'b0;
        end else if (ready_stage1 && !s_axis_tvalid) begin
            valid_stage1 <= 1'b0;
        end else if (ready_stage2) begin
            valid_stage1 <= 1'b0;
            ready_stage1 <= 1'b1;
        end
    end
end

assign s_axis_tready = ready_stage1;

//----------------------------------------
// Pipeline Stage 2: Address Decode & Mux
//----------------------------------------
reg        muxed_data_stage2;
reg [1:0]  addr_stage2;
reg        valid_stage2;
reg        ready_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        muxed_data_stage2 <= 1'b0;
        addr_stage2       <= 2'b0;
        valid_stage2      <= 1'b0;
        ready_stage2      <= 1'b1;
    end else begin
        if (valid_stage1 && ready_stage2) begin
            case (addr_stage1)
                2'b00: muxed_data_stage2 <= data_stage1[0];
                2'b01: muxed_data_stage2 <= data_stage1[1];
                2'b10: muxed_data_stage2 <= data_stage1[2];
                2'b11: muxed_data_stage2 <= data_stage1[3];
                default: muxed_data_stage2 <= 1'b0;
            endcase
            addr_stage2  <= addr_stage1;
            valid_stage2 <= 1'b1;
            ready_stage2 <= 1'b0;
        end else if (ready_stage2 && !valid_stage1) begin
            valid_stage2 <= 1'b0;
        end else if (ready_stage3) begin
            valid_stage2 <= 1'b0;
            ready_stage2 <= 1'b1;
        end
    end
end

//----------------------------------------
// Pipeline Stage 3: Output Register
//----------------------------------------
reg        data_stage3;
reg        valid_stage3;
reg        last_stage3;
reg        ready_stage3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_stage3  <= 1'b0;
        valid_stage3 <= 1'b0;
        last_stage3  <= 1'b0;
        ready_stage3 <= 1'b1;
    end else begin
        if (valid_stage2 && ready_stage3) begin
            data_stage3  <= muxed_data_stage2;
            valid_stage3 <= 1'b1;
            last_stage3  <= 1'b1;
            ready_stage3 <= 1'b0;
        end else if (m_axis_tvalid && m_axis_tready) begin
            valid_stage3 <= 1'b0;
            last_stage3  <= 1'b0;
            ready_stage3 <= 1'b1;
        end
    end
end

//----------------------------------------
// AXI-Stream Output Assignments
//----------------------------------------
assign m_axis_tdata  = data_stage3;
assign m_axis_tvalid = valid_stage3;
assign m_axis_tlast  = last_stage3;

endmodule