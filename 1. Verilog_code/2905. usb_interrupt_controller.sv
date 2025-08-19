module usb_interrupt_controller #(
    parameter NUM_ENDPOINTS = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [NUM_ENDPOINTS-1:0] ep_interrupt,
    input wire [NUM_ENDPOINTS-1:0] mask,
    input wire global_enable,
    input wire [NUM_ENDPOINTS-1:0] clear,
    output reg interrupt,
    output reg [NUM_ENDPOINTS-1:0] status
);
    reg [NUM_ENDPOINTS-1:0] pending;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending <= {NUM_ENDPOINTS{1'b0}};
            status <= {NUM_ENDPOINTS{1'b0}};
            interrupt <= 1'b0;
        end else begin
            // Set pending bits when endpoints trigger interrupts
            pending <= (pending | ep_interrupt) & ~clear;
            
            // Update status register based on pending and mask
            status <= pending & mask;
            
            // Generate main interrupt if any masked interrupt is pending
            interrupt <= global_enable & |(pending & mask);
        end
    end
endmodule