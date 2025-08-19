//SystemVerilog
// SystemVerilog - IEEE 1364-2005
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
    reg [NUM_ENDPOINTS-1:0] pending_next;
    reg [NUM_ENDPOINTS-1:0] masked_pending;
    reg [NUM_ENDPOINTS-1:0] masked_pending_pipe;
    reg any_masked_pending;
    reg global_enable_pipe;
    
    // Pipeline stage 1: Calculate next pending state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending_next <= {NUM_ENDPOINTS{1'b0}};
            pending <= {NUM_ENDPOINTS{1'b0}};
        end else begin
            pending_next <= (pending | ep_interrupt) & ~clear;
            pending <= pending_next;
        end
    end
    
    // Pipeline stage 2: Calculate masked pending interrupts
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_pending <= {NUM_ENDPOINTS{1'b0}};
            masked_pending_pipe <= {NUM_ENDPOINTS{1'b0}};
        end else begin
            masked_pending <= pending & mask;
            masked_pending_pipe <= masked_pending;
        end
    end
    
    // Pipeline stage 3: OR reduction and final output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            any_masked_pending <= 1'b0;
            global_enable_pipe <= 1'b0;
            status <= {NUM_ENDPOINTS{1'b0}};
            interrupt <= 1'b0;
        end else begin
            any_masked_pending <= |masked_pending;
            global_enable_pipe <= global_enable;
            status <= masked_pending_pipe;
            interrupt <= global_enable_pipe & any_masked_pending;
        end
    end
endmodule