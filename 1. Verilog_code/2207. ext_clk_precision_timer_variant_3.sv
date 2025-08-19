//SystemVerilog
module ext_clk_precision_timer #(
    parameter WIDTH = 20
)(
    input wire ext_clk,
    input wire sys_clk,
    input wire rst_n,
    input wire start,
    input wire stop,
    output reg busy,
    output reg [WIDTH-1:0] elapsed_time
);
    // Reduced pipeline stages for counter (from 3 to 2)
    reg [WIDTH-1:0] counter_stage1;
    reg [WIDTH-1:0] counter_stage2;
    
    // Reduced pipeline control signals
    reg running_stage1;
    reg running_stage2;
    
    // Reduced pipeline busy signals
    reg busy_stage1;
    reg busy_stage2;
    
    // Optimized synchronization registers (reduced pipeline depth)
    reg start_sync1, start_sync2, start_sync_d;
    reg stop_sync1, stop_sync2, stop_sync_d;
    
    // LUT-assisted increment implementation
    reg [7:0] lut_increment [0:255];  // 8-bit increment lookup table
    reg [WIDTH-8-1:0] high_bits_counter;  // Upper bits of counter
    wire [7:0] low_bits_incremented;
    wire carry_out;
    
    // Initialize increment lookup table
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            lut_increment[i] = i + 1;
        end
    end
    
    // Synchronize control signals to sys_clk domain with reduced pipeline depth
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            start_sync1 <= 1'b0;
            start_sync2 <= 1'b0;
            start_sync_d <= 1'b0;
            
            stop_sync1 <= 1'b0;
            stop_sync2 <= 1'b0;
            stop_sync_d <= 1'b0;
        end else begin
            // First stage
            start_sync1 <= start;
            stop_sync1 <= stop;
            
            // Second stage
            start_sync2 <= start_sync1;
            stop_sync2 <= stop_sync1;
            
            // Delayed signals for edge detection (combined previous stages)
            start_sync_d <= start_sync2;
            stop_sync_d <= stop_sync2;
        end
    end
    
    // LUT-assisted increment logic
    assign low_bits_incremented = lut_increment[counter_stage1[7:0]];
    assign carry_out = (counter_stage1[7:0] == 8'hFF) ? 1'b1 : 1'b0;
    
    // Stage 1 pipeline - Handle start/stop detection and counting
    always @(posedge ext_clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage1 <= {WIDTH{1'b0}};
            running_stage1 <= 1'b0;
            busy_stage1 <= 1'b0;
            high_bits_counter <= {(WIDTH-8){1'b0}};
        end else begin
            if (start_sync_d && !running_stage1) begin
                counter_stage1 <= {WIDTH{1'b0}};
                high_bits_counter <= {(WIDTH-8){1'b0}};
                running_stage1 <= 1'b1;
                busy_stage1 <= 1'b1;
            end else if (stop_sync_d && running_stage1) begin
                running_stage1 <= 1'b0;
                busy_stage1 <= 1'b0;
            end else if (running_stage1) begin
                // LUT-assisted increment operation for lower 8 bits
                counter_stage1[7:0] <= low_bits_incremented;
                
                // Increment upper bits only on carry
                if (carry_out) begin
                    high_bits_counter <= high_bits_counter + 1'b1;
                end
                
                // Combine lower and upper parts
                counter_stage1[WIDTH-1:8] <= high_bits_counter;
            end
        end
    end
    
    // Stage 2 pipeline - Final stage for output preparation (merged previous stages 2 and 3)
    always @(posedge ext_clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage2 <= {WIDTH{1'b0}};
            running_stage2 <= 1'b0;
            busy_stage2 <= 1'b0;
            elapsed_time <= {WIDTH{1'b0}};
            busy <= 1'b0;
        end else begin
            counter_stage2 <= counter_stage1;
            running_stage2 <= running_stage1;
            busy_stage2 <= busy_stage1;
            
            // Update outputs
            if (stop_sync_d && running_stage1) begin
                elapsed_time <= counter_stage1;  // Updated to use stage1 directly
            end
            
            busy <= busy_stage2;
        end
    end
endmodule