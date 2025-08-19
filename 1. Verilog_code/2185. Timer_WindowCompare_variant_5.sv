//SystemVerilog
module Timer_WindowCompare (
    // Clock and Reset
    input wire clk,
    input wire rst_n,
    
    // AXI-Stream Slave Interface
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    input wire [7:0] s_axis_tdata,
    input wire s_axis_tlast,
    
    // AXI-Stream Master Interface
    output reg m_axis_tvalid,
    input wire m_axis_tready,
    output reg [7:0] m_axis_tdata,
    output reg m_axis_tlast
);
    // Internal registers
    reg [7:0] timer;
    reg [7:0] low_th, high_th;
    reg timer_ge_low, timer_le_high;
    reg in_window;
    reg data_valid;
    reg threshold_update;
    reg [1:0] th_select;
    
    // Ready signal assertion - always ready to receive data
    assign s_axis_tready = 1'b1;
    
    // Capture thresholds from input stream
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            low_th <= 8'h00;
            high_th <= 8'hFF;
            th_select <= 2'b00;
            threshold_update <= 1'b0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            // When valid data arrives
            if (s_axis_tlast) begin
                // End of transaction
                th_select <= 2'b00;
                threshold_update <= 1'b1;
            end else begin
                case (th_select)
                    2'b00: begin
                        low_th <= s_axis_tdata;
                        th_select <= 2'b01;
                    end
                    2'b01: begin
                        high_th <= s_axis_tdata;
                        th_select <= 2'b10;
                    end
                    default: th_select <= th_select;
                endcase
                threshold_update <= 1'b0;
            end
        end else begin
            threshold_update <= 1'b0;
        end
    end
    
    // Timer logic with window comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer <= 8'h00;
            timer_ge_low <= 1'b0;
            timer_le_high <= 1'b0;
            in_window <= 1'b0;
            data_valid <= 1'b0;
        end else begin
            timer <= timer + 1'b1;
            
            // Register the comparisons separately to reduce critical path
            timer_ge_low <= (timer >= low_th);
            timer_le_high <= (timer <= high_th);
            
            // Use pre-registered comparison results
            in_window <= timer_ge_low && timer_le_high;
            
            // Generate valid data pulse at regular intervals or on threshold update
            data_valid <= (timer[2:0] == 3'b000) || threshold_update;
        end
    end
    
    // Output stream generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= 8'h00;
            m_axis_tlast <= 1'b0;
        end else begin
            // Set valid when we have data to transmit
            if (data_valid) begin
                m_axis_tvalid <= 1'b1;
                m_axis_tdata <= {7'b0000000, in_window};
                m_axis_tlast <= 1'b1; // Mark end of transaction
            end else if (m_axis_tready && m_axis_tvalid) begin
                // Clear valid after handshake completes
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
            end
        end
    end
    
endmodule