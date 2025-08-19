//SystemVerilog
module LevelITRC #(parameter CHANNELS=4, TIMEOUT=8) (
    input clk, rst,
    input [CHANNELS-1:0] level_irq,
    output reg irq_valid,
    output reg [$clog2(CHANNELS)-1:0] active_channel
);
    reg [CHANNELS-1:0] irq_active;
    reg [$clog2(TIMEOUT):0] timeout_counter [0:CHANNELS-1];
    wire [$clog2(TIMEOUT):0] next_timeout [0:CHANNELS-1];
    wire [CHANNELS-1:0] borrow;
    integer i;
    
    genvar j;
    generate
        for (j = 0; j < CHANNELS; j = j + 1) begin : SUBTRACTOR
            wire [$clog2(TIMEOUT):0] inverted_timeout;
            wire [$clog2(TIMEOUT):0] inverted_result;
            wire [$clog2(TIMEOUT):0] final_result;
            
            // Invert timeout value
            assign inverted_timeout = ~timeout_counter[j];
            
            // Add 1 to inverted value
            assign inverted_result = inverted_timeout + 1'b1;
            
            // Invert result back
            assign final_result = ~inverted_result;
            
            // Generate borrow signals
            assign borrow[j] = (timeout_counter[j] == 0) ? 1'b1 : 1'b0;
            
            // Use conditional inversion subtractor result
            assign next_timeout[j] = final_result;
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
            if (level_irq[0] && !irq_active[0]) begin
                irq_active[0] <= 1;
                timeout_counter[0] <= TIMEOUT;
            end else if (irq_active[0] && !borrow[0]) begin
                timeout_counter[0] <= next_timeout[0];
            end else if (irq_active[0]) begin
                irq_active[0] <= 0;
            end
            
            if (level_irq[1] && !irq_active[1]) begin
                irq_active[1] <= 1;
                timeout_counter[1] <= TIMEOUT;
            end else if (irq_active[1] && !borrow[1]) begin
                timeout_counter[1] <= next_timeout[1];
            end else if (irq_active[1]) begin
                irq_active[1] <= 0;
            end
            
            if (level_irq[2] && !irq_active[2]) begin
                irq_active[2] <= 1;
                timeout_counter[2] <= TIMEOUT;
            end else if (irq_active[2] && !borrow[2]) begin
                timeout_counter[2] <= next_timeout[2];
            end else if (irq_active[2]) begin
                irq_active[2] <= 0;
            end
            
            if (level_irq[3] && !irq_active[3]) begin
                irq_active[3] <= 1;
                timeout_counter[3] <= TIMEOUT;
            end else if (irq_active[3] && !borrow[3]) begin
                timeout_counter[3] <= next_timeout[3];
            end else if (irq_active[3]) begin
                irq_active[3] <= 0;
            end
            
            irq_valid <= |irq_active;
            if (irq_active[3]) active_channel <= 2'd3;
            else if (irq_active[2]) active_channel <= 2'd2;
            else if (irq_active[1]) active_channel <= 2'd1;
            else if (irq_active[0]) active_channel <= 2'd0;
        end
    end
endmodule