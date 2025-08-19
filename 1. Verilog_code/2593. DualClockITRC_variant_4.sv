//SystemVerilog
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
    
    // Pre-computed signals
    wire irq_detected_valid = |irq_in_a && !irq_detected_a;
    wire irq_toggle_next = ~irq_toggle_a;
    wire irq_sync_changed = irq_sync2_b != prev_irq_sync_b;
    
    // Domain A: IRQ detection
    always @(posedge clk_a or posedge rst_a) begin
        if (rst_a) begin
            irq_detected_a <= 4'b0;
        end else if (irq_detected_valid) begin
            irq_detected_a <= irq_in_a;
        end
    end
    
    // Domain A: Toggle generation
    always @(posedge clk_a or posedge rst_a) begin
        if (rst_a) begin
            irq_toggle_a <= 1'b0;
        end else if (irq_detected_valid) begin
            irq_toggle_a <= irq_toggle_next;
        end
    end
    
    // Domain B: First stage synchronizer
    always @(posedge clk_b or posedge rst_b) begin
        if (rst_b) begin
            irq_sync1_b <= 1'b0;
        end else begin
            irq_sync1_b <= irq_toggle_a;
        end
    end
    
    // Domain B: Second stage synchronizer
    always @(posedge clk_b or posedge rst_b) begin
        if (rst_b) begin
            irq_sync2_b <= 1'b0;
            prev_irq_sync_b <= 1'b0;
        end else begin
            irq_sync2_b <= irq_sync1_b;
            prev_irq_sync_b <= irq_sync2_b;
        end
    end
    
    // Domain B: IRQ data capture
    always @(posedge clk_b or posedge rst_b) begin
        if (rst_b) begin
            irq_data_b <= 4'b0;
        end else if (irq_sync_changed) begin
            irq_data_b <= irq_detected_a;
        end
    end
    
    // Domain B: IRQ output generation
    always @(posedge clk_b or posedge rst_b) begin
        if (rst_b) begin
            irq_out_b <= 1'b0;
        end else if (irq_sync_changed) begin
            irq_out_b <= 1'b1;
        end else if (irq_out_b) begin
            irq_out_b <= 1'b0;
        end
    end
    
    // Domain B: Priority encoder
    always @(posedge clk_b or posedge rst_b) begin
        if (rst_b) begin
            irq_id_b <= 2'b00;
        end else if (irq_sync_changed) begin
            irq_id_b <= irq_detected_a[3] ? 2'd3 :
                       irq_detected_a[2] ? 2'd2 :
                       irq_detected_a[1] ? 2'd1 : 2'd0;
        end
    end

endmodule