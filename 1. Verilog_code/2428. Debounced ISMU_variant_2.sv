//SystemVerilog
module debounce_ismu #(parameter CNT_WIDTH = 4)(
    input wire clk, rst,
    input wire [7:0] raw_intr,
    output reg [7:0] stable_intr
);
    // Main storage registers
    reg [7:0] intr_r1, intr_r2;
    reg [CNT_WIDTH-1:0] counter [7:0];
    
    // Split processing into parallel channels to reduce critical path
    reg [7:0] counter_match;
    reg [7:0] intr_changed;
    
    // Pipeline registers for critical path isolation
    reg [7:0] raw_intr_q;
    
    // Counter for channels 0-3
    reg [CNT_WIDTH-1:0] counter_low_next [0:3];
    // Counter for channels 4-7
    reg [CNT_WIDTH-1:0] counter_high_next [0:3];
    
    integer i;
    
    // Pre-compute comparison values
    wire [CNT_WIDTH-1:0] cnt_max = {CNT_WIDTH{1'b1}};
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            intr_r1 <= 8'h0;
            intr_r2 <= 8'h0;
            stable_intr <= 8'h0;
            raw_intr_q <= 8'h0;
            
            for (i = 0; i < 8; i = i + 1) begin
                counter[i] <= 0;
            end
            
            counter_match <= 8'h0;
            intr_changed <= 8'h0;
        end else begin
            // Input stage with pipeline register
            raw_intr_q <= raw_intr;
            intr_r1 <= raw_intr_q;
            intr_r2 <= intr_r1;
            
            // Pre-compute status flags for all 8 bits in parallel
            for (i = 0; i < 8; i = i + 1) begin
                // Detect input changes
                intr_changed[i] <= (intr_r1[i] != intr_r2[i]);
                
                // Detect counter matches
                counter_match[i] <= (counter[i] == cnt_max);
            end
            
            // Update counters for all channels in parallel
            for (i = 0; i < 4; i = i + 1) begin
                // Lower channels (0-3)
                if (intr_changed[i])
                    counter[i] <= 0;
                else if (!counter_match[i])
                    counter[i] <= counter[i] + 1'b1;
                    
                // Update output when counter reaches maximum
                if (counter_match[i])
                    stable_intr[i] <= intr_r1[i];
            end
            
            for (i = 4; i < 8; i = i + 1) begin
                // Upper channels (4-7)
                if (intr_changed[i])
                    counter[i] <= 0;
                else if (!counter_match[i])
                    counter[i] <= counter[i] + 1'b1;
                    
                // Update output when counter reaches maximum
                if (counter_match[i])
                    stable_intr[i] <= intr_r1[i];
            end
        end
    end
endmodule