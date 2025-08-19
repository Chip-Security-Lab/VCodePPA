//SystemVerilog
//IEEE 1364-2005
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
    reg [NUM_ENDPOINTS-1:0] pending_stage1;
    reg [NUM_ENDPOINTS-1:0] pending_stage2;
    reg [NUM_ENDPOINTS-1:0] pending_stage3;
    
    reg [NUM_ENDPOINTS-1:0] pending_masked_stage1;
    reg [NUM_ENDPOINTS-1:0] pending_masked_stage2;
    reg [NUM_ENDPOINTS-1:0] pending_masked_stage3;
    
    reg pending_any_stage1;
    reg pending_any_stage2;
    reg pending_any_stage3;
    
    reg global_enable_stage1;
    reg global_enable_stage2;
    reg global_enable_stage3;
    reg global_enable_stage4;
    
    reg [NUM_ENDPOINTS-1:0] clear_stage1;
    reg [NUM_ENDPOINTS-1:0] mask_stage1;
    reg [NUM_ENDPOINTS-1:0] mask_stage2;
    
    reg [NUM_ENDPOINTS-1:0] ep_interrupt_stage1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline registers
            pending_stage1 <= {NUM_ENDPOINTS{1'b0}};
            pending_stage2 <= {NUM_ENDPOINTS{1'b0}};
            pending_stage3 <= {NUM_ENDPOINTS{1'b0}};
            
            pending_masked_stage1 <= {NUM_ENDPOINTS{1'b0}};
            pending_masked_stage2 <= {NUM_ENDPOINTS{1'b0}};
            pending_masked_stage3 <= {NUM_ENDPOINTS{1'b0}};
            
            pending_any_stage1 <= 1'b0;
            pending_any_stage2 <= 1'b0;
            pending_any_stage3 <= 1'b0;
            
            global_enable_stage1 <= 1'b0;
            global_enable_stage2 <= 1'b0;
            global_enable_stage3 <= 1'b0;
            global_enable_stage4 <= 1'b0;
            
            clear_stage1 <= {NUM_ENDPOINTS{1'b0}};
            mask_stage1 <= {NUM_ENDPOINTS{1'b0}};
            mask_stage2 <= {NUM_ENDPOINTS{1'b0}};
            
            ep_interrupt_stage1 <= {NUM_ENDPOINTS{1'b0}};
            
            status <= {NUM_ENDPOINTS{1'b0}};
            interrupt <= 1'b0;
        end else begin
            // Pipeline Stage 0: Register inputs
            ep_interrupt_stage1 <= ep_interrupt;
            clear_stage1 <= clear;
            mask_stage1 <= mask;
            global_enable_stage1 <= global_enable;
            
            // Pipeline Stage 1: Update pending bits when endpoints trigger interrupts
            pending_stage1 <= (pending_stage3 | ep_interrupt_stage1) & ~clear_stage1;
            mask_stage2 <= mask_stage1;
            global_enable_stage2 <= global_enable_stage1;
            
            // Pipeline Stage 2: Calculate initial masked pending interrupts 
            pending_stage2 <= pending_stage1;
            pending_masked_stage1 <= pending_stage1 & mask_stage2;
            global_enable_stage3 <= global_enable_stage2;
            
            // Pipeline Stage 3: Further process masked pending interrupts
            pending_stage3 <= pending_stage2;
            pending_masked_stage2 <= pending_masked_stage1;
            pending_any_stage1 <= |pending_masked_stage1;
            global_enable_stage4 <= global_enable_stage3;
            
            // Pipeline Stage 4: Calculate final status
            pending_masked_stage3 <= pending_masked_stage2;
            pending_any_stage2 <= pending_any_stage1;
            
            // Pipeline Stage 5: Generate final output
            pending_any_stage3 <= pending_any_stage2;
            status <= pending_masked_stage3;
            interrupt <= global_enable_stage4 & pending_any_stage3;
        end
    end
endmodule