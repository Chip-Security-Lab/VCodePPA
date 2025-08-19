//SystemVerilog
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
    // Stage 1: Pending computation
    reg [NUM_ENDPOINTS-1:0] pending;
    reg [NUM_ENDPOINTS-1:0] pending_stage1;
    reg [NUM_ENDPOINTS-1:0] ep_interrupt_stage1;
    reg [NUM_ENDPOINTS-1:0] clear_stage1;
    reg valid_stage1;
    
    // Stage 2: Status computation
    reg [NUM_ENDPOINTS-1:0] pending_stage2;
    reg [NUM_ENDPOINTS-1:0] mask_stage2;
    reg valid_stage2;
    
    // Stage 3: Interrupt generation
    reg global_enable_stage3;
    reg [NUM_ENDPOINTS-1:0] status_internal;
    reg valid_stage3;
    
    // Pipeline Stage 1: Pending calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending <= {NUM_ENDPOINTS{1'b0}};
            pending_stage1 <= {NUM_ENDPOINTS{1'b0}};
            ep_interrupt_stage1 <= {NUM_ENDPOINTS{1'b0}};
            clear_stage1 <= {NUM_ENDPOINTS{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            ep_interrupt_stage1 <= ep_interrupt;
            clear_stage1 <= clear;
            pending_stage1 <= (pending | ep_interrupt) & ~clear;
            pending <= pending_stage1;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Pipeline Stage 2: Status calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending_stage2 <= {NUM_ENDPOINTS{1'b0}};
            mask_stage2 <= {NUM_ENDPOINTS{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            pending_stage2 <= pending_stage1;
            mask_stage2 <= mask;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline Stage 3: Interrupt generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            status_internal <= {NUM_ENDPOINTS{1'b0}};
            global_enable_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
            status <= {NUM_ENDPOINTS{1'b0}};
            interrupt <= 1'b0;
        end else begin
            status_internal <= pending_stage2 & mask_stage2;
            global_enable_stage3 <= global_enable;
            valid_stage3 <= valid_stage2;
            
            if (valid_stage3) begin
                status <= status_internal;
                interrupt <= global_enable_stage3 & (|status_internal);
            end
        end
    end
endmodule