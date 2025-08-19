//SystemVerilog IEEE 1364-2005
module usb_frame_counter(
    // Clock and reset
    input wire aclk,                    // AXI clock
    input wire aresetn,                 // AXI active-low reset
    
    // Input AXI-Stream interface
    input wire [15:0] s_axis_tdata,     // Input data containing frame_number and flags
    input wire s_axis_tvalid,           // Input data valid
    output wire s_axis_tready,          // Ready to accept input
    input wire s_axis_tlast,            // End of frame marker
    
    // Output AXI-Stream interface
    output wire [31:0] m_axis_tdata,    // Output data containing counters and status
    output wire m_axis_tvalid,          // Output data valid
    input wire m_axis_tready,           // Downstream ready to accept
    output wire m_axis_tlast            // End of transfer marker
);

    // Internal signals
    reg [10:0] expected_frame;
    reg frame_missed;
    reg frame_mismatch;
    reg [15:0] sof_count;
    reg [15:0] error_count;
    wire [1:0] counter_status;
    
    reg [15:0] consecutive_good;
    reg initialized;
    
    // Extract signals from input AXI-Stream
    wire sof_received = s_axis_tvalid && s_axis_tready && s_axis_tdata[15];
    wire frame_error = s_axis_tvalid && s_axis_tready && s_axis_tdata[14];
    wire [10:0] frame_number = s_axis_tdata[10:0];
    
    // Always ready to receive new frame data
    assign s_axis_tready = 1'b1;
    
    // Output control signals
    reg output_valid_reg;
    assign m_axis_tvalid = output_valid_reg;
    assign m_axis_tlast = 1'b1;  // Each transfer is a complete data packet
    
    // Instantiate status and counter management module
    status_counter_manager status_manager (
        .aclk(aclk),
        .aresetn(aresetn),
        .sof_received(sof_received),
        .frame_error(frame_error),
        .frame_number(frame_number),
        .expected_frame(expected_frame),
        .frame_missed(frame_missed),
        .frame_mismatch(frame_mismatch),
        .sof_count(sof_count),
        .error_count(error_count),
        .consecutive_good(consecutive_good),
        .initialized(initialized),
        .counter_status(counter_status)
    );
    
    // Instantiate AXI output controller
    axi_output_controller output_ctrl (
        .aclk(aclk),
        .aresetn(aresetn),
        .sof_received(sof_received),
        .frame_error(frame_error),
        .m_axis_tready(m_axis_tready),
        .counter_status(counter_status),
        .error_count(error_count),
        .expected_frame(expected_frame),
        .output_valid_reg(output_valid_reg),
        .m_axis_tdata(m_axis_tdata)
    );
    
endmodule

// Module to manage status and error counting logic
module status_counter_manager (
    input wire aclk,
    input wire aresetn,
    input wire sof_received,
    input wire frame_error,
    input wire [10:0] frame_number,
    output reg [10:0] expected_frame,
    output reg frame_missed,
    output reg frame_mismatch,
    output reg [15:0] sof_count,
    output reg [15:0] error_count,
    output reg [15:0] consecutive_good,
    output reg initialized,
    output wire [1:0] counter_status
);
    
    // Status output based on error counts
    assign counter_status = (error_count > 16'd10) ? 2'b11 :   // Critical errors
                          (error_count > 16'd0)  ? 2'b01 :   // Warning
                          2'b00;                             // Good
    
    // Main processing logic
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            expected_frame <= 11'd0;
            frame_missed <= 1'b0;
            frame_mismatch <= 1'b0;
            sof_count <= 16'd0;
            error_count <= 16'd0;
            consecutive_good <= 16'd0;
            initialized <= 1'b0;
        end else begin
            // Clear single-cycle flags
            frame_missed <= 1'b0;
            frame_mismatch <= 1'b0;
            
            if (sof_received) begin
                sof_count <= sof_count + 16'd1;
                
                if (!initialized) begin
                    // First SOF received - initialize expected counter
                    expected_frame <= frame_number;
                    initialized <= 1'b1;
                    consecutive_good <= 16'd1;
                end else begin
                    // Check if received frame matches expected
                    if (frame_number != expected_frame) begin
                        frame_mismatch <= 1'b1;
                        error_count <= error_count + 16'd1;
                        consecutive_good <= 16'd0;
                    end else begin
                        consecutive_good <= consecutive_good + 16'd1;
                    end
                    
                    // Update expected frame for next SOF
                    expected_frame <= (frame_number + 11'd1) & 11'h7FF;
                end
            end else if (frame_error) begin
                error_count <= error_count + 16'd1;
                consecutive_good <= 16'd0;
            end
        end
    end
endmodule

// Module to handle AXI output interface
module axi_output_controller (
    input wire aclk,
    input wire aresetn,
    input wire sof_received,
    input wire frame_error,
    input wire m_axis_tready,
    input wire [1:0] counter_status,
    input wire [15:0] error_count,
    input wire [10:0] expected_frame,
    output reg output_valid_reg,
    output wire [31:0] m_axis_tdata
);

    // Output data packaging
    assign m_axis_tdata = {
        counter_status,       // [31:30]
        6'b0,                 // [29:24] reserved
        error_count,          // [23:8]
        expected_frame[7:0]   // [7:0] lower 8 bits of expected frame
    };
    
    // Update output valid signal
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            output_valid_reg <= 1'b0;
        end else begin
            if (sof_received || frame_error) begin
                output_valid_reg <= 1'b1;
            end else if (m_axis_tready && output_valid_reg) begin
                output_valid_reg <= 1'b0;
            end
        end
    end
    
endmodule