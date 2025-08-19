//SystemVerilog
module PulseWidthITRC #(parameter CHANNELS=4) (
    input wire clk, rstn,
    input wire [CHANNELS-1:0] irq_in,
    output reg irq_out,
    output reg [1:0] irq_src
);
    reg [CHANNELS-1:0] prev_irq;
    reg [3:0] pulse_counter [0:CHANNELS-1];
    reg [CHANNELS-1:0] long_pulse;
    wire [CHANNELS-1:0] rising_edge;
    
    assign rising_edge = irq_in & ~prev_irq;
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            prev_irq <= 0;
            long_pulse <= 0;
            irq_out <= 0;
            irq_src <= 0;
            for (integer i = 0; i < CHANNELS; i = i + 1)
                pulse_counter[i] <= 0;
        end else begin
            for (integer i = 0; i < CHANNELS; i = i + 1) begin
                case ({rising_edge[i], irq_in[i]})
                    2'b10: pulse_counter[i] <= 1;
                    2'b11: pulse_counter[i] <= pulse_counter[i] + 1;
                    default: pulse_counter[i] <= pulse_counter[i];
                endcase
                
                case ({pulse_counter[i] >= 8, irq_in[i]})
                    2'b10: long_pulse[i] <= 1;
                    2'b01: long_pulse[i] <= 0;
                    default: long_pulse[i] <= long_pulse[i];
                endcase
            end
            
            prev_irq <= irq_in;
            
            irq_out <= |long_pulse;
            
            // Convert casex to case with explicit conditions
            case (1'b1)
                long_pulse[3]: irq_src <= 2'd3;
                long_pulse[2]: irq_src <= 2'd2;
                long_pulse[1]: irq_src <= 2'd1;
                long_pulse[0]: irq_src <= 2'd0;
                default: irq_src <= irq_src;
            endcase
        end
    end
endmodule