//SystemVerilog
module PulseWidthITRC #(parameter CHANNELS=4) (
    input wire clk, rstn,
    input wire [CHANNELS-1:0] irq_in,
    output reg irq_out,
    output reg [1:0] irq_src
);
    // Stage 1: Edge detection and pulse tracking
    reg [CHANNELS-1:0] prev_irq_stage1;
    reg [CHANNELS-1:0] rising_edge_stage1;
    reg [CHANNELS-1:0] pulse_active_stage1;
    
    // Stage 2: Counter update
    reg [3:0] pulse_counter_stage2 [0:CHANNELS-1];
    reg [CHANNELS-1:0] pulse_active_stage2;
    reg [CHANNELS-1:0] rising_edge_stage2;
    
    // Stage 3: Long pulse detection
    reg [CHANNELS-1:0] long_pulse_stage3;
    reg [3:0] pulse_counter_stage3 [0:CHANNELS-1];
    
    // Stage 4: Priority encoding
    reg [CHANNELS-1:0] long_pulse_stage4;
    
    // Stage 1 logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            prev_irq_stage1 <= 0;
            rising_edge_stage1 <= 0;
            pulse_active_stage1 <= 0;
        end else begin
            prev_irq_stage1 <= irq_in;
            rising_edge_stage1 <= irq_in & ~prev_irq_stage1;
            pulse_active_stage1 <= irq_in;
        end
    end
    
    // Stage 2 logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (int i = 0; i < CHANNELS; i = i + 1)
                pulse_counter_stage2[i] <= 0;
            pulse_active_stage2 <= 0;
            rising_edge_stage2 <= 0;
        end else begin
            pulse_active_stage2 <= pulse_active_stage1;
            rising_edge_stage2 <= rising_edge_stage1;
            
            for (int i = 0; i < CHANNELS; i = i + 1) begin
                if (rising_edge_stage1[i])
                    pulse_counter_stage2[i] <= 1;
                else if (pulse_active_stage1[i])
                    pulse_counter_stage2[i] <= pulse_counter_stage2[i] + 1;
            end
        end
    end
    
    // Stage 3 logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            long_pulse_stage3 <= 0;
            for (int i = 0; i < CHANNELS; i = i + 1)
                pulse_counter_stage3[i] <= 0;
        end else begin
            for (int i = 0; i < CHANNELS; i = i + 1) begin
                pulse_counter_stage3[i] <= pulse_counter_stage2[i];
                if (pulse_counter_stage2[i] >= 8)
                    long_pulse_stage3[i] <= 1;
                else if (!pulse_active_stage2[i])
                    long_pulse_stage3[i] <= 0;
            end
        end
    end
    
    // Stage 4 logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            long_pulse_stage4 <= 0;
            irq_out <= 0;
            irq_src <= 0;
        end else begin
            long_pulse_stage4 <= long_pulse_stage3;
            irq_out <= |long_pulse_stage3;
            casex (long_pulse_stage3)
                4'b1xxx: irq_src <= 2'd3;
                4'b01xx: irq_src <= 2'd2;
                4'b001x: irq_src <= 2'd1;
                4'b0001: irq_src <= 2'd0;
                default: irq_src <= 2'd0;
            endcase
        end
    end
endmodule