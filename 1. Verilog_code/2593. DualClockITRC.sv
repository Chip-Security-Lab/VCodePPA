module DualClockITRC (
    input wire clk_a, rst_a,
    input wire clk_b, rst_b,
    input wire [3:0] irq_in_a,
    output reg irq_out_b,
    output reg [1:0] irq_id_b
);
    // Domain A signals
    reg [3:0] irq_detected_a;
    reg irq_toggle_a;
    
    // Synchronizers for domain B
    reg irq_sync1_b, irq_sync2_b;
    reg prev_irq_sync_b;
    reg [3:0] irq_data_b;
    
    // Domain A logic
    always @(posedge clk_a or posedge rst_a) begin
        if (rst_a) begin
            irq_detected_a <= 4'b0;
            irq_toggle_a <= 1'b0;
        end else if (|irq_in_a && !irq_detected_a) begin
            irq_detected_a <= irq_in_a;
            irq_toggle_a <= ~irq_toggle_a; // Toggle on new interrupt
        end
    end
    
    // Domain B synchronizer
    always @(posedge clk_b or posedge rst_b) begin
        if (rst_b) begin
            irq_sync1_b <= 1'b0;
            irq_sync2_b <= 1'b0;
            prev_irq_sync_b <= 1'b0;
            irq_data_b <= 4'b0;
            irq_out_b <= 1'b0;
            irq_id_b <= 2'b00;
        end else begin
            irq_sync1_b <= irq_toggle_a;
            irq_sync2_b <= irq_sync1_b;
            
            // Detect toggle transition
            if (irq_sync2_b != prev_irq_sync_b) begin
                irq_data_b <= irq_detected_a;
                irq_out_b <= 1'b1;
                
                // Priority encoder instead of loop
                if (irq_detected_a[3]) 
                    irq_id_b <= 2'd3;
                else if (irq_detected_a[2]) 
                    irq_id_b <= 2'd2;
                else if (irq_detected_a[1]) 
                    irq_id_b <= 2'd1;
                else if (irq_detected_a[0]) 
                    irq_id_b <= 2'd0;
            end else if (irq_out_b) begin
                irq_out_b <= 1'b0; // Auto-clear after one cycle
            end
            prev_irq_sync_b <= irq_sync2_b;
        end
    end
endmodule