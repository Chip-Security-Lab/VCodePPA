//SystemVerilog
module LevelITRC #(parameter CHANNELS=4, TIMEOUT=8) (
    input clk, rst,
    input [CHANNELS-1:0] level_irq,
    output reg irq_valid,
    output reg [$clog2(CHANNELS)-1:0] active_channel
);
    reg [CHANNELS-1:0] irq_active;
    reg [$clog2(TIMEOUT):0] timeout_counter [0:CHANNELS-1];
    wire [CHANNELS-1:0] timeout_expired;
    wire [CHANNELS-1:0] timeout_active;
    wire [CHANNELS-1:0] new_irq;
    integer i;
    
    // Generate timeout status signals
    genvar ch;
    generate
        for (ch = 0; ch < CHANNELS; ch = ch + 1) begin : gen_timeout
            assign timeout_expired[ch] = (timeout_counter[ch] == 0);
            assign timeout_active[ch] = (timeout_counter[ch] > 0);
            assign new_irq[ch] = level_irq[ch] & ~irq_active[ch];
        end
    endgenerate
    
    always @(posedge clk) begin
        if (rst) begin
            irq_active <= 0;
            irq_valid <= 0;
            active_channel <= 0;
            for (i = 0; i < CHANNELS; i = i + 1)
                timeout_counter[i] <= 0;
        end else begin
            // Update irq_active and timeout counters
            for (i = 0; i < CHANNELS; i = i + 1) begin
                if (new_irq[i]) begin
                    irq_active[i] <= 1'b1;
                    timeout_counter[i] <= TIMEOUT;
                end else if (irq_active[i]) begin
                    if (timeout_active[i]) begin
                        timeout_counter[i] <= timeout_counter[i] - 1'b1;
                    end else begin
                        irq_active[i] <= 1'b0;
                    end
                end
            end
            
            // Priority encoder for active channel
            irq_valid <= |irq_active;
            active_channel <= (irq_active[3]) ? 2'd3 :
                             (irq_active[2]) ? 2'd2 :
                             (irq_active[1]) ? 2'd1 :
                             (irq_active[0]) ? 2'd0 : 2'd0;
        end
    end
endmodule