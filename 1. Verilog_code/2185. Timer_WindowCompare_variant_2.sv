//SystemVerilog
module Timer_WindowCompare (
    // Clock and reset
    input wire clk,
    input wire rst_n,
    
    // AXI-Stream Slave Interface
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    input wire [7:0] s_axis_tdata,
    input wire s_axis_tlast,
    
    // AXI-Stream Master Interface
    output wire m_axis_tvalid,
    input wire m_axis_tready,
    output wire [7:0] m_axis_tdata,
    output wire m_axis_tlast
);
    // Internal registers
    reg [7:0] timer;
    reg in_window;
    reg [7:0] low_th, high_th;
    reg data_valid;
    
    // Advanced control signals
    wire input_handshake = s_axis_tvalid & s_axis_tready;
    wire output_handshake = m_axis_tvalid & m_axis_tready;
    wire timer_active = data_valid & ~output_handshake;
    
    // Ready to accept data when not processing or when output is accepted
    assign s_axis_tready = ~data_valid | output_handshake;
    
    // Valid output when we have processed data
    assign m_axis_tvalid = data_valid;
    
    // Output data - the window comparison result (packed into data)
    assign m_axis_tdata = {7'b0, in_window};
    
    // Pass through tlast signal
    assign m_axis_tlast = s_axis_tlast;
    
    // Window comparison logic
    wire is_in_window;
    // Optimized comparison - single range check rather than two separate comparisons
    assign is_in_window = (timer - low_th) <= (high_th - low_th);
    
    // Threshold register update and timer logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer <= 8'b0;
            in_window <= 1'b0;
            low_th <= 8'b0;
            high_th <= 8'b0;
            data_valid <= 1'b0;
        end else begin
            // Input data handling
            if (input_handshake) begin
                if (!s_axis_tlast) begin
                    // First data is low threshold
                    low_th <= s_axis_tdata;
                end else begin
                    // Second data is high threshold
                    high_th <= s_axis_tdata;
                    // Start processing after receiving both thresholds
                    timer <= 8'b0;
                    data_valid <= 1'b1;
                end
            end
            
            // Timer increments when enabled
            if (timer_active) begin
                timer <= timer + 1'b1;
                in_window <= is_in_window;
            end
            
            // Clear data_valid when output is accepted
            if (output_handshake) begin
                data_valid <= 1'b0;
            end
        end
    end
endmodule