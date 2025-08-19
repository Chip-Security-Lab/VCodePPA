//SystemVerilog
module DualClockITRC (
    input wire clk_a, rst_a,
    input wire clk_b, rst_b,
    input wire [3:0] irq_in_a,
    output reg irq_valid_b,
    output reg [1:0] irq_id_b,
    input wire irq_ready_b
);
    // Domain A signals
    reg [3:0] irq_detected_a;
    reg irq_toggle_a;
    
    // Synchronizers for domain B
    reg irq_sync1_b, irq_sync2_b, irq_sync3_b;
    reg prev_irq_sync_b;
    reg [3:0] irq_data_b;
    reg irq_valid_next_b;
    reg [1:0] irq_id_next_b;
    
    // Domain A logic
    always @(posedge clk_a or posedge rst_a) begin
        if (rst_a) begin
            irq_detected_a <= 4'b0;
            irq_toggle_a <= 1'b0;
        end else if (|irq_in_a && !irq_detected_a) begin
            irq_detected_a <= irq_in_a;
            irq_toggle_a <= ~irq_toggle_a;
        end
    end
    
    // Domain B logic - Stage 1: Synchronization
    always @(posedge clk_b or posedge rst_b) begin
        if (rst_b) begin
            {irq_sync1_b, irq_sync2_b, irq_sync3_b} <= 3'b0;
        end else begin
            {irq_sync1_b, irq_sync2_b, irq_sync3_b} <= {irq_toggle_a, irq_sync1_b, irq_sync2_b};
        end
    end
    
    // Domain B logic - Stage 2: Edge Detection and Data Capture
    always @(posedge clk_b or posedge rst_b) begin
        if (rst_b) begin
            prev_irq_sync_b <= 1'b0;
            irq_data_b <= 4'b0;
            irq_valid_next_b <= 1'b0;
            irq_id_next_b <= 2'b0;
        end else begin
            prev_irq_sync_b <= irq_sync3_b;
            
            if (irq_sync3_b != prev_irq_sync_b) begin
                irq_data_b <= irq_detected_a;
                irq_valid_next_b <= 1'b1;
                irq_id_next_b <= (irq_detected_a[3] ? 2'd3 :
                                 irq_detected_a[2] ? 2'd2 :
                                 irq_detected_a[1] ? 2'd1 : 2'd0);
            end else if (irq_valid_next_b && irq_ready_b) begin
                irq_valid_next_b <= 1'b0;
            end
        end
    end
    
    // Domain B logic - Stage 3: Output Registers
    always @(posedge clk_b or posedge rst_b) begin
        if (rst_b) begin
            irq_valid_b <= 1'b0;
            irq_id_b <= 2'b0;
        end else begin
            irq_valid_b <= irq_valid_next_b;
            irq_id_b <= irq_id_next_b;
        end
    end
endmodule