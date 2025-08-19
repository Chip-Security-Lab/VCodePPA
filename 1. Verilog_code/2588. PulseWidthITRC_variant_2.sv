//SystemVerilog
module PulseWidthITRC #(parameter CHANNELS=4) (
    input wire clk, rstn,
    input wire [CHANNELS-1:0] irq_in,
    output reg irq_out,
    output reg [1:0] irq_src
);

    // Stage 1: Input sampling and edge detection
    reg [CHANNELS-1:0] prev_irq_stage1;
    reg [CHANNELS-1:0] irq_in_stage1;
    wire [CHANNELS-1:0] rising_edge_stage1 = irq_in & ~prev_irq_stage1;
    
    // Stage 2: Pulse counter
    reg [3:0] pulse_counter_stage2 [0:CHANNELS-1];
    reg [CHANNELS-1:0] irq_in_stage2;
    reg [CHANNELS-1:0] rising_edge_stage2;
    
    // Stage 3: Long pulse detection
    reg [CHANNELS-1:0] long_pulse_stage3;
    reg [CHANNELS-1:0] irq_in_stage3;
    
    // Stage 4: Priority encoding
    reg [CHANNELS-1:0] long_pulse_stage4;
    
    // Stage 1: Input sampling and edge detection
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            prev_irq_stage1 <= 0;
            irq_in_stage1 <= 0;
        end else begin
            irq_in_stage1 <= irq_in;
            prev_irq_stage1 <= irq_in;
        end
    end
    
    // Stage 2: Pulse counter
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (integer i = 0; i < CHANNELS; i = i + 1) begin
                pulse_counter_stage2[i] <= 0;
            end
            irq_in_stage2 <= 0;
            rising_edge_stage2 <= 0;
        end else begin
            irq_in_stage2 <= irq_in_stage1;
            rising_edge_stage2 <= rising_edge_stage1;
            
            for (integer i = 0; i < CHANNELS; i = i + 1) begin
                case ({rising_edge_stage1[i], irq_in_stage1[i]})
                    2'b10: pulse_counter_stage2[i] <= 4'd1;
                    2'b11: pulse_counter_stage2[i] <= pulse_counter_stage2[i] + 1;
                    default: pulse_counter_stage2[i] <= 0;
                endcase
            end
        end
    end
    
    // Stage 3: Long pulse detection
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            long_pulse_stage3 <= 0;
            irq_in_stage3 <= 0;
        end else begin
            irq_in_stage3 <= irq_in_stage2;
            
            for (integer i = 0; i < CHANNELS; i = i + 1) begin
                long_pulse_stage3[i] <= (pulse_counter_stage2[i] >= 8) ? 1'b1 : 
                                      (!irq_in_stage2[i]) ? 1'b0 : long_pulse_stage3[i];
            end
        end
    end
    
    // Stage 4: Priority encoding
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            long_pulse_stage4 <= 0;
            irq_out <= 0;
            irq_src <= 0;
        end else begin
            long_pulse_stage4 <= long_pulse_stage3;
            
            irq_out <= |long_pulse_stage3;
            casez (long_pulse_stage3)
                4'b1???: irq_src <= 2'd3;
                4'b01??: irq_src <= 2'd2;
                4'b001?: irq_src <= 2'd1;
                4'b0001: irq_src <= 2'd0;
                default: irq_src <= 2'd0;
            endcase
        end
    end

endmodule