module cam_1 (
    input wire clk,
    input wire rst,
    
    // AXI-Stream input interface
    input wire [7:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    
    // AXI-Stream output interface
    output wire [7:0] m_axis_tdata,
    output wire m_axis_tvalid,
    input wire m_axis_tready,
    output wire m_axis_tlast
);
    // Internal signals
    wire [7:0] store_data;
    wire match_flag;
    wire mode_is_write;
    wire mode_is_compare;
    wire processing_active;
    
    // Mode detection
    assign mode_is_write = s_axis_tdata[7];
    assign mode_is_compare = ~s_axis_tdata[7];
    
    // Data storage module instantiation
    cam_storage u_storage (
        .clk            (clk),
        .rst            (rst),
        .write_en       (processing_active && mode_is_write),
        .data_in        (s_axis_tdata),
        .stored_data    (store_data)
    );
    
    // Data comparison module instantiation
    cam_compare u_compare (
        .stored_data    (store_data),
        .compare_data   (s_axis_tdata),
        .match_result   (match_flag)
    );
    
    // AXI-Stream control module instantiation
    cam_axi_controller u_axi_ctrl (
        .clk            (clk),
        .rst            (rst),
        .s_axis_tvalid  (s_axis_tvalid),
        .s_axis_tready  (s_axis_tready),
        .m_axis_tvalid  (m_axis_tvalid),
        .m_axis_tready  (m_axis_tready),
        .m_axis_tlast   (m_axis_tlast),
        .mode_is_write  (mode_is_write),
        .mode_is_compare(mode_is_compare),
        .match_flag     (match_flag),
        .m_axis_tdata   (m_axis_tdata),
        .processing_active(processing_active)
    );
endmodule

module cam_storage (
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire [7:0] data_in,
    output reg [7:0] stored_data
);
    always @(posedge clk) begin
        if (rst) begin
            stored_data <= 8'b0;
        end else if (write_en) begin
            stored_data <= data_in;
        end
    end
endmodule

module cam_compare (
    input wire [7:0] stored_data,
    input wire [7:0] compare_data,
    output wire match_result
);
    // Combinational comparison logic for better timing
    assign match_result = (stored_data == compare_data);
endmodule

module cam_axi_controller (
    input wire clk,
    input wire rst,
    
    // AXI-Stream control signals
    input wire s_axis_tvalid,
    output reg s_axis_tready,
    output reg m_axis_tvalid,
    input wire m_axis_tready,
    output reg m_axis_tlast,
    
    // Control signals
    input wire mode_is_write,
    input wire mode_is_compare,
    input wire match_flag,
    output reg [7:0] m_axis_tdata,
    output wire processing_active
);
    // Internal FSM state
    reg waiting_for_output_ack;
    
    // Signal to indicate active processing
    assign processing_active = s_axis_tvalid && s_axis_tready;
    
    // AXI-Stream control logic with FSM approach
    always @(posedge clk) begin
        if (rst) begin
            s_axis_tready <= 1'b1;
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= 8'b0;
            m_axis_tlast <= 1'b0;
            waiting_for_output_ack <= 1'b0;
        end else begin
            // Default states
            if (waiting_for_output_ack && m_axis_tready) begin
                // Output has been accepted, return to ready state
                waiting_for_output_ack <= 1'b0;
                s_axis_tready <= 1'b1;
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
            end else if (s_axis_tvalid && s_axis_tready) begin
                if (mode_is_write) begin
                    // Write mode - remain ready for next input
                    s_axis_tready <= 1'b1;
                end else if (mode_is_compare) begin
                    // Compare mode - prepare output
                    m_axis_tdata <= {7'b0, match_flag};
                    m_axis_tvalid <= 1'b1;
                    m_axis_tlast <= 1'b1;
                    
                    // Block new inputs until current output is accepted
                    waiting_for_output_ack <= 1'b1;
                    s_axis_tready <= 1'b0;
                end
            end
        end
    end
endmodule