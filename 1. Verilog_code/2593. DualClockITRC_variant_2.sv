//SystemVerilog
module DualClockITRC (
    input wire clk_a, rst_a,
    input wire clk_b, rst_b,
    input wire [3:0] irq_in_a,
    output reg irq_valid_b,
    output reg [1:0] irq_id_b,
    input wire irq_ready_b
);
    reg [3:0] irq_detected_a;
    reg irq_toggle_a;
    reg irq_sync1_b, irq_sync2_b;
    reg prev_irq_sync_b;
    reg [3:0] irq_data_b;
    
    always @(posedge clk_a or posedge rst_a) begin
        if (rst_a) begin
            irq_detected_a <= 4'b0;
            irq_toggle_a <= 1'b0;
        end else if (|irq_in_a && !irq_detected_a) begin
            irq_detected_a <= irq_in_a;
            irq_toggle_a <= ~irq_toggle_a;
        end
    end
    
    always @(posedge clk_b or posedge rst_b) begin
        if (rst_b) begin
            irq_sync1_b <= 1'b0;
            irq_sync2_b <= 1'b0;
            prev_irq_sync_b <= 1'b0;
            irq_data_b <= 4'b0;
            irq_valid_b <= 1'b0;
            irq_id_b <= 2'b00;
        end else begin
            irq_sync1_b <= irq_toggle_a;
            irq_sync2_b <= irq_sync1_b;
            
            if (irq_sync2_b != prev_irq_sync_b) begin
                irq_data_b <= irq_detected_a;
                irq_valid_b <= 1'b1;
                
                // Optimized priority encoder using case statement
                casex (irq_detected_a)
                    4'b1xxx: irq_id_b <= 2'd3;
                    4'b01xx: irq_id_b <= 2'd2;
                    4'b001x: irq_id_b <= 2'd1;
                    4'b0001: irq_id_b <= 2'd0;
                    default: irq_id_b <= 2'd0;
                endcase
            end else if (irq_valid_b && irq_ready_b) begin
                irq_valid_b <= 1'b0;
            end
            prev_irq_sync_b <= irq_sync2_b;
        end
    end
endmodule