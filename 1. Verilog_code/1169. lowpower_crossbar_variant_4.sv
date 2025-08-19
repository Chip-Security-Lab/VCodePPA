//SystemVerilog - IEEE 1364-2005

//----------------------------------------------------------------------
// Top-level module
//----------------------------------------------------------------------
module lowpower_crossbar (
    // Clock and reset
    input wire clk, rst_n,
    
    // Input AXI-Stream interface
    input wire [63:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    
    // Configuration inputs
    input wire [7:0] out_sel,
    
    // Output AXI-Stream interface
    output wire [63:0] m_axis_tdata,
    output wire m_axis_tvalid,
    input wire m_axis_tready,
    output wire m_axis_tlast
);
    // Internal signals
    wire [3:0] in_valid;
    wire [63:0] in_data;
    wire [63:0] out_data_next;
    wire data_processed;
    wire [3:0] clk_en;
    wire [15:0] output_segment[0:3];
    wire m_axis_tlast_i;

    // Handshaking module instantiation
    axi_handshake_controller handshake_ctrl (
        .s_axis_tvalid(s_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tvalid(m_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .in_valid(in_valid),
        .in_data(in_data),
        .s_axis_tdata(s_axis_tdata)
    );

    // Power management module instantiation
    power_gating_controller power_ctrl (
        .in_valid(in_valid),
        .s_axis_tready(s_axis_tready),
        .clk_en(clk_en)
    );

    // Crossbar switch module instantiation
    crossbar_switch crossbar (
        .in_valid(in_valid),
        .in_data(in_data),
        .out_sel(out_sel),
        .output_segment(output_segment)
    );

    // Output data generator module instantiation
    output_data_generator output_gen (
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .clk_en(clk_en),
        .output_segment(output_segment),
        .m_axis_tdata(m_axis_tdata),
        .out_data_next(out_data_next),
        .data_processed(data_processed),
        .in_valid(in_valid),
        .m_axis_tlast(m_axis_tlast_i)
    );

    // Output register module instantiation
    output_register_controller output_reg (
        .clk(clk),
        .rst_n(rst_n),
        .data_processed(data_processed),
        .out_data_next(out_data_next),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast_i(m_axis_tlast_i),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tlast(m_axis_tlast)
    );
    
endmodule

//----------------------------------------------------------------------
// AXI Handshake Controller - Manages handshaking between input and output
//----------------------------------------------------------------------
module axi_handshake_controller (
    input wire s_axis_tvalid,
    input wire m_axis_tready,
    input wire m_axis_tvalid,
    output wire s_axis_tready,
    output wire [3:0] in_valid,
    output wire [63:0] in_data,
    input wire [63:0] s_axis_tdata
);
    // Input handshaking
    assign s_axis_tready = m_axis_tready || !m_axis_tvalid;
    assign in_valid = {4{s_axis_tvalid & s_axis_tready}};
    assign in_data = s_axis_tdata;
    
endmodule

//----------------------------------------------------------------------
// Power Gating Controller - Manages clock gating for power optimization
//----------------------------------------------------------------------
module power_gating_controller (
    input wire [3:0] in_valid,
    input wire s_axis_tready,
    output wire [3:0] clk_en
);
    // Enable clock only for outputs that have valid data
    genvar g;
    generate
        for (g = 0; g < 4; g = g + 1) begin : gen_clk_en
            assign clk_en[g] = |in_valid & s_axis_tready;
        end
    endgenerate
    
endmodule

//----------------------------------------------------------------------
// Crossbar Switch - Routes data according to selection control
//----------------------------------------------------------------------
module crossbar_switch (
    input wire [3:0] in_valid,
    input wire [63:0] in_data,
    input wire [7:0] out_sel,
    output wire [15:0] output_segment[0:3]
);
    // Create output generation for each segment
    genvar g;
    generate
        for (g = 0; g < 4; g = g + 1) begin : gen_output
            // Default values
            reg [15:0] segment_value;
            
            always @(*) begin
                segment_value = 16'h0000;
                if (in_valid[0] && out_sel[1:0] == g) segment_value = in_data[15:0];
                if (in_valid[1] && out_sel[3:2] == g) segment_value = in_data[31:16];
                if (in_valid[2] && out_sel[5:4] == g) segment_value = in_data[47:32];
                if (in_valid[3] && out_sel[7:6] == g) segment_value = in_data[63:48];
            end
            
            assign output_segment[g] = segment_value;
        end
    endgenerate
    
endmodule

//----------------------------------------------------------------------
// Output Data Generator - Creates the next output data word
//----------------------------------------------------------------------
module output_data_generator (
    input wire s_axis_tvalid,
    input wire s_axis_tready,
    input wire [3:0] clk_en,
    input wire [15:0] output_segment[0:3],
    input wire [63:0] m_axis_tdata,
    output reg [63:0] out_data_next,
    output reg data_processed,
    input wire [3:0] in_valid,
    output reg m_axis_tlast
);
    // Compute next output data
    always @(*) begin
        out_data_next = m_axis_tdata;
        data_processed = 1'b0;
        m_axis_tlast = 1'b0;
        
        if (s_axis_tvalid & s_axis_tready) begin
            if (clk_en[0]) out_data_next[15:0] = output_segment[0];
            if (clk_en[1]) out_data_next[31:16] = output_segment[1];
            if (clk_en[2]) out_data_next[47:32] = output_segment[2];
            if (clk_en[3]) out_data_next[63:48] = output_segment[3];
            data_processed = 1'b1;
            
            // Assert tlast every 4 transfers for burst handling
            m_axis_tlast = &in_valid;
        end
    end
    
endmodule

//----------------------------------------------------------------------
// Output Register Controller - Manages output registers with handshaking
//----------------------------------------------------------------------
module output_register_controller (
    input wire clk,
    input wire rst_n,
    input wire data_processed,
    input wire [63:0] out_data_next,
    input wire m_axis_tready,
    input wire m_axis_tlast_i,
    output reg [63:0] m_axis_tdata,
    output reg m_axis_tvalid,
    output reg m_axis_tlast
);
    // Output registers with AXI-Stream handshaking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tdata <= 64'h0000_0000_0000_0000;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
        end else begin
            if (data_processed) begin
                m_axis_tdata <= out_data_next;
                m_axis_tvalid <= 1'b1;
                m_axis_tlast <= m_axis_tlast_i;
            end else if (m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
            end
        end
    end
    
endmodule