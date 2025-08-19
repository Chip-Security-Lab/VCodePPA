//SystemVerilog
module range_detector_with_axi_stream(
    // Clock and reset
    input wire clk,
    input wire rst,
    
    // AXI-Stream input interface
    input wire [15:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    
    // Range parameters input
    input wire [15:0] range_min, range_max,
    
    // AXI-Stream output interface
    output reg [0:0] m_axis_tdata,
    output reg m_axis_tvalid,
    input wire m_axis_tready,
    output reg m_axis_tlast
);
    // Internal signals
    wire comp_out;
    reg processing;
    
    // Ready signal generation - we're ready when not processing
    assign s_axis_tready = !processing || m_axis_tready;
    
    // Comparator module instantiation
    comparator_module comp1(
        .data(s_axis_tdata),
        .lower(range_min),
        .upper(range_max),
        .in_range(comp_out)
    );
    
    // Processing state management
    always @(posedge clk) begin
        if (rst) begin
            processing <= 1'b0;
        end
        else begin
            if (s_axis_tvalid && s_axis_tready) begin
                processing <= 1'b1;
            end
            else if (m_axis_tready && m_axis_tvalid) begin
                processing <= 1'b0;
            end
        end
    end
    
    // Output generation
    always @(posedge clk) begin
        if (rst) begin
            m_axis_tdata <= 1'b0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
        end
        else begin
            // Valid data is available and we're ready to process
            if (s_axis_tvalid && s_axis_tready) begin
                m_axis_tdata <= comp_out;
                m_axis_tvalid <= 1'b1;
                m_axis_tlast <= 1'b1; // Each input produces one output
            end
            else if (m_axis_tready && m_axis_tvalid) begin
                // Transaction completed
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
            end
        end
    end
endmodule

// Comparator module remains functionally the same
module comparator_module(
    input wire [15:0] data,
    input wire [15:0] lower,
    input wire [15:0] upper,
    output wire in_range
);
    assign in_range = (data >= lower) && (data <= upper);
endmodule