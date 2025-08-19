module PulseWidthITRC #(parameter CHANNELS=4) (
    input wire clk, rstn,
    input wire [CHANNELS-1:0] irq_in,
    output reg irq_out,
    output reg [1:0] irq_src
);
    reg [CHANNELS-1:0] prev_irq;
    reg [3:0] pulse_counter [0:CHANNELS-1];
    reg [CHANNELS-1:0] long_pulse;
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            prev_irq <= 0;
            long_pulse <= 0;
            irq_out <= 0;
            irq_src <= 0;
            pulse_counter[0] <= 0;
            pulse_counter[1] <= 0;
            pulse_counter[2] <= 0;
            pulse_counter[3] <= 0;
        end else begin
            // Process channel 0
            if (irq_in[0] && !prev_irq[0]) 
                pulse_counter[0] <= 1; // Start counting
            else if (irq_in[0])
                pulse_counter[0] <= pulse_counter[0] + 1;
            
            if (pulse_counter[0] >= 8)
                long_pulse[0] <= 1;
            else if (!irq_in[0])
                long_pulse[0] <= 0;
                
            // Process channel 1
            if (irq_in[1] && !prev_irq[1]) 
                pulse_counter[1] <= 1;
            else if (irq_in[1])
                pulse_counter[1] <= pulse_counter[1] + 1;
            
            if (pulse_counter[1] >= 8)
                long_pulse[1] <= 1;
            else if (!irq_in[1])
                long_pulse[1] <= 0;
                
            // Process channel 2
            if (irq_in[2] && !prev_irq[2]) 
                pulse_counter[2] <= 1;
            else if (irq_in[2])
                pulse_counter[2] <= pulse_counter[2] + 1;
            
            if (pulse_counter[2] >= 8)
                long_pulse[2] <= 1;
            else if (!irq_in[2])
                long_pulse[2] <= 0;
                
            // Process channel 3
            if (irq_in[3] && !prev_irq[3]) 
                pulse_counter[3] <= 1;
            else if (irq_in[3])
                pulse_counter[3] <= pulse_counter[3] + 1;
            
            if (pulse_counter[3] >= 8)
                long_pulse[3] <= 1;
            else if (!irq_in[3])
                long_pulse[3] <= 0;
            
            prev_irq <= irq_in;
            
            // Prioritize long pulses (priority encoder)
            irq_out <= |long_pulse;
            if (long_pulse[3]) irq_src <= 2'd3;
            else if (long_pulse[2]) irq_src <= 2'd2;
            else if (long_pulse[1]) irq_src <= 2'd1;
            else if (long_pulse[0]) irq_src <= 2'd0;
        end
    end
endmodule