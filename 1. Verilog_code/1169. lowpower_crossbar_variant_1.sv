//SystemVerilog
module lowpower_crossbar (
    // Clock and reset
    input wire clk,
    input wire rst_n,
    
    // AXI-Stream slave interface
    input wire [63:0] s_axis_tdata,
    input wire s_axis_tvalid,
    input wire [3:0] s_axis_tuser,  // Repurposed from in_valid
    input wire [7:0] s_axis_tstrb,  // Repurposed from out_sel
    output wire s_axis_tready,
    
    // AXI-Stream master interface
    output wire [63:0] m_axis_tdata,
    output wire m_axis_tvalid,
    input wire m_axis_tready
);
    // Internal signals
    reg [63:0] out_data_reg;
    wire [3:0] in_valid;
    wire [7:0] out_sel;
    wire [63:0] in_data;
    wire data_valid;
    
    // Map AXI-Stream signals to internal signals
    assign in_data = s_axis_tdata;
    assign in_valid = s_axis_tuser;
    assign out_sel = s_axis_tstrb;
    assign data_valid = s_axis_tvalid;
    
    // Always ready to accept data
    assign s_axis_tready = m_axis_tready;
    
    // Output AXI-Stream signals
    assign m_axis_tdata = out_data_reg;
    assign m_axis_tvalid = data_valid;
    
    // Pre-decode selector signals to reduce critical path
    // Compute destination mapping for each input segment
    wire [3:0] seg0_dest_onehot, seg1_dest_onehot, seg2_dest_onehot, seg3_dest_onehot;
    
    // Destination decoding using one-hot encoding to reduce multiplexer complexity
    assign seg0_dest_onehot[0] = (out_sel[1:0] == 2'b00) & in_valid[0];
    assign seg0_dest_onehot[1] = (out_sel[1:0] == 2'b01) & in_valid[0];
    assign seg0_dest_onehot[2] = (out_sel[1:0] == 2'b10) & in_valid[0];
    assign seg0_dest_onehot[3] = (out_sel[1:0] == 2'b11) & in_valid[0];
    
    assign seg1_dest_onehot[0] = (out_sel[3:2] == 2'b00) & in_valid[1];
    assign seg1_dest_onehot[1] = (out_sel[3:2] == 2'b01) & in_valid[1];
    assign seg1_dest_onehot[2] = (out_sel[3:2] == 2'b10) & in_valid[1];
    assign seg1_dest_onehot[3] = (out_sel[3:2] == 2'b11) & in_valid[1];
    
    assign seg2_dest_onehot[0] = (out_sel[5:4] == 2'b00) & in_valid[2];
    assign seg2_dest_onehot[1] = (out_sel[5:4] == 2'b01) & in_valid[2];
    assign seg2_dest_onehot[2] = (out_sel[5:4] == 2'b10) & in_valid[2];
    assign seg2_dest_onehot[3] = (out_sel[5:4] == 2'b11) & in_valid[2];
    
    assign seg3_dest_onehot[0] = (out_sel[7:6] == 2'b00) & in_valid[3];
    assign seg3_dest_onehot[1] = (out_sel[7:6] == 2'b01) & in_valid[3];
    assign seg3_dest_onehot[2] = (out_sel[7:6] == 2'b10) & in_valid[3];
    assign seg3_dest_onehot[3] = (out_sel[7:6] == 2'b11) & in_valid[3];
    
    // Optimized segment selection logic - Balanced paths
    wire [15:0] output_segment[0:3];
    
    // Optimized selection logic for each output segment
    // Using one-hot selection to avoid cascaded muxes
    assign output_segment[0] = 
        (seg0_dest_onehot[0] ? in_data[15:0]   : 16'h0000) |
        (seg1_dest_onehot[0] ? in_data[31:16]  : 16'h0000) |
        (seg2_dest_onehot[0] ? in_data[47:32]  : 16'h0000) |
        (seg3_dest_onehot[0] ? in_data[63:48]  : 16'h0000);
                
    assign output_segment[1] = 
        (seg0_dest_onehot[1] ? in_data[15:0]   : 16'h0000) |
        (seg1_dest_onehot[1] ? in_data[31:16]  : 16'h0000) |
        (seg2_dest_onehot[1] ? in_data[47:32]  : 16'h0000) |
        (seg3_dest_onehot[1] ? in_data[63:48]  : 16'h0000);
                
    assign output_segment[2] = 
        (seg0_dest_onehot[2] ? in_data[15:0]   : 16'h0000) |
        (seg1_dest_onehot[2] ? in_data[31:16]  : 16'h0000) |
        (seg2_dest_onehot[2] ? in_data[47:32]  : 16'h0000) |
        (seg3_dest_onehot[2] ? in_data[63:48]  : 16'h0000);
                
    assign output_segment[3] = 
        (seg0_dest_onehot[3] ? in_data[15:0]   : 16'h0000) |
        (seg1_dest_onehot[3] ? in_data[31:16]  : 16'h0000) |
        (seg2_dest_onehot[3] ? in_data[47:32]  : 16'h0000) |
        (seg3_dest_onehot[3] ? in_data[63:48]  : 16'h0000);
    
    // Power optimization: Enable clock only when there's valid data to process
    wire any_valid_data = data_valid & |in_valid;
    
    // Simplified clock gating signal - Reduces logic depth
    wire [3:0] clk_en;
    assign clk_en[0] = any_valid_data & (|seg0_dest_onehot[0] | |seg1_dest_onehot[0] | |seg2_dest_onehot[0] | |seg3_dest_onehot[0]);
    assign clk_en[1] = any_valid_data & (|seg0_dest_onehot[1] | |seg1_dest_onehot[1] | |seg2_dest_onehot[1] | |seg3_dest_onehot[1]);
    assign clk_en[2] = any_valid_data & (|seg0_dest_onehot[2] | |seg1_dest_onehot[2] | |seg2_dest_onehot[2] | |seg3_dest_onehot[2]);
    assign clk_en[3] = any_valid_data & (|seg0_dest_onehot[3] | |seg1_dest_onehot[3] | |seg2_dest_onehot[3] | |seg3_dest_onehot[3]);
    
    // Output register with AXI-Stream handshaking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_data_reg <= 64'h0000_0000_0000_0000;
        end else if (data_valid && m_axis_tready) begin
            // Parallel update of segments reduces logic depth
            out_data_reg[15:0]  <= clk_en[0] ? output_segment[0] : out_data_reg[15:0];
            out_data_reg[31:16] <= clk_en[1] ? output_segment[1] : out_data_reg[31:16];
            out_data_reg[47:32] <= clk_en[2] ? output_segment[2] : out_data_reg[47:32];
            out_data_reg[63:48] <= clk_en[3] ? output_segment[3] : out_data_reg[63:48];
        end
    end
endmodule