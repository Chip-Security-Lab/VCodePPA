//SystemVerilog
module can_interrupt_controller (
    // Clock and reset
    input  wire        clk,
    input  wire        rst_n,
    
    // AXI-Stream slave interface
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire [3:0]  s_axis_tdata,  // interrupt_mask
    
    // AXI-Stream master interface
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready,
    output reg  [3:0]  m_axis_tdata,  // interrupt_status
    output reg         m_axis_tlast,
    
    // CAN status signals
    input  wire        tx_done,
    input  wire        rx_done, 
    input  wire        error_detected,
    input  wire        bus_off,
    
    // Interrupt output
    output reg         interrupt
);

    // Internal registers
    reg [3:0] pending_interrupts;
    reg [3:0] interrupt_mask;
    reg prev_tx_done, prev_rx_done, prev_error, prev_bus_off;
    
    // Buffered versions with better fanout control
    reg [3:0] pending_buff_status;
    reg [3:0] pending_buff_int;
    
    // AXI-Stream handshaking logic
    assign s_axis_tready = 1'b1;  // Always ready to receive mask updates
    
    // Capture interrupt mask from AXI-Stream
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            interrupt_mask <= 4'b0000;
        end else if (s_axis_tvalid && s_axis_tready) begin
            interrupt_mask <= s_axis_tdata;
        end
    end
    
    // Edge detection and interrupt logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending_interrupts <= 4'b0000;
            pending_buff_status <= 4'b0000;
            pending_buff_int <= 4'b0000;
            interrupt <= 1'b0;
            prev_tx_done <= 1'b0;
            prev_rx_done <= 1'b0;
            prev_error <= 1'b0;
            prev_bus_off <= 1'b0;
        end else begin
            // Edge detection registers
            prev_tx_done <= tx_done;
            prev_rx_done <= rx_done;
            prev_error <= error_detected;
            prev_bus_off <= bus_off;
            
            // Update pending interrupts on rising edges
            if (!prev_tx_done && tx_done) pending_interrupts[0] <= 1'b1;
            if (!prev_rx_done && rx_done) pending_interrupts[1] <= 1'b1;
            if (!prev_error && error_detected) pending_interrupts[2] <= 1'b1;
            if (!prev_bus_off && bus_off) pending_interrupts[3] <= 1'b1;
            
            // Buffer stage for improved PPA
            pending_buff_status <= pending_interrupts;
            pending_buff_int <= pending_interrupts;
            
            // Generate interrupt using buffered signal
            interrupt <= |(pending_buff_int & interrupt_mask);
        end
    end
    
    // AXI-Stream master interface logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= 4'b0000;
            m_axis_tlast <= 1'b0;
        end else begin
            // Update tdata with interrupt status
            m_axis_tdata <= pending_buff_status;
            
            // Generate valid signal on any change in interrupt status
            if (m_axis_tdata != pending_buff_status) begin
                m_axis_tvalid <= 1'b1;
                m_axis_tlast <= 1'b1;  // Each transfer is a complete transaction
            end else if (m_axis_tvalid && m_axis_tready) begin
                // Once handshake is complete, deassert valid
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
            end
        end
    end

endmodule