//SystemVerilog
module bidir_demux_axi_stream (
    // AXI-Stream Interface
    input  wire        s_axis_tvalid,    // Input data valid
    output wire        s_axis_tready,    // Ready to accept data
    input  wire [3:0]  s_axis_tdata,     // Input data
    input  wire        s_axis_tlast,     // End of packet indicator
    
    output wire        m_axis_tvalid,    // Output data valid
    input  wire        m_axis_tready,    // Downstream ready
    output wire [3:0]  m_axis_tdata,     // Output data
    output wire        m_axis_tlast,     // End of packet indicator
    
    // Control signals
    input  wire [1:0]  channel_sel,      // Channel selection
    input  wire        direction,         // 0: in→out, 1: out→in
    
    // Clock and reset
    input  wire        clk,
    input  wire        rst_n
);

    // Registered control signals moved after combinational logic
    reg [1:0]  channel_sel_reg;
    reg        direction_reg;
    
    // Register control inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            channel_sel_reg <= 2'b00;
            direction_reg <= 1'b0;
        end else begin
            channel_sel_reg <= channel_sel;
            direction_reg <= direction;
        end
    end
    
    // Decoded channel selection (moved after register)
    reg [3:0] selected_channel;
    
    // Channel decoder logic
    always @(*) begin
        selected_channel = 4'b0000;
        case (channel_sel_reg)
            2'b00: selected_channel[0] = 1'b1;
            2'b01: selected_channel[1] = 1'b1;
            2'b10: selected_channel[2] = 1'b1;
            2'b11: selected_channel[3] = 1'b1;
        endcase
    end
    
    // Register AXI-Stream input signals
    reg [3:0] s_axis_tdata_reg;
    reg       s_axis_tlast_reg;
    reg       s_axis_tvalid_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axis_tdata_reg <= 4'b0;
            s_axis_tlast_reg <= 1'b0;
            s_axis_tvalid_reg <= 1'b0;
        end else if (s_axis_tready) begin
            s_axis_tdata_reg <= s_axis_tdata;
            s_axis_tlast_reg <= s_axis_tlast;
            s_axis_tvalid_reg <= s_axis_tvalid;
        end
    end
    
    // Data path logic after registers
    wire valid_channel = |selected_channel;
    
    // Optimized data path with registered inputs
    assign m_axis_tdata = direction_reg ? 4'b0 : s_axis_tdata_reg & selected_channel;
    assign m_axis_tvalid = direction_reg ? 1'b0 : s_axis_tvalid_reg & valid_channel;
    assign m_axis_tlast = direction_reg ? 1'b0 : s_axis_tlast_reg;
    
    // Backpressure handling
    assign s_axis_tready = direction_reg ? 1'b0 : m_axis_tready & valid_channel;
    
endmodule