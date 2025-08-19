//SystemVerilog
//IEEE 1364-2005 Verilog standard
module can_interrupt_controller (
    input  wire        clk,
    input  wire        rst_n,
    
    // AXI-Stream Slave Interface
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire [7:0]  s_axis_tdata,
    input  wire        s_axis_tlast,
    
    // AXI-Stream Master Interface
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire [7:0]  m_axis_tdata,
    output wire        m_axis_tlast
);

    // Internal signals
    reg [3:0] pending_interrupts;
    reg [3:0] prev_status;
    reg [3:0] interrupt_status;
    reg interrupt;
    
    // Extract control signals from AXI-Stream input
    wire [3:0] current_status = s_axis_tdata[3:0];
    wire [3:0] interrupt_mask = s_axis_tdata[7:4];
    
    // Always ready to receive data
    assign s_axis_tready = 1'b1;
    
    // Core interrupt logic with optimized comparison structure
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending_interrupts <= 4'b0000;
            prev_status <= 4'b0000;
            interrupt_status <= 4'b0000;
            interrupt <= 1'b0;
        end else begin
            // Optimized edge detection using XOR and bit masking
            pending_interrupts <= pending_interrupts | (prev_status ^ current_status) & current_status;
            
            // Update previous status for next cycle
            prev_status <= current_status;
            
            // Update interrupt status register
            interrupt_status <= pending_interrupts;
            
            // Generate interrupt signal using reduction OR
            // This leverages hardware optimizations for bit reduction operations
            interrupt <= |(pending_interrupts & interrupt_mask);
        end
    end
    
    // AXI-Stream output mapping
    assign m_axis_tvalid = s_axis_tvalid;
    assign m_axis_tdata = {interrupt_status, 3'b000, interrupt};
    assign m_axis_tlast = s_axis_tlast;
    
endmodule