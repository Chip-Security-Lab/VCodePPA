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
    
    // Domain B pipeline registers
    reg irq_sync1_b, irq_sync2_b;
    reg prev_irq_sync_b;
    reg [3:0] irq_data_stage1_b;
    reg [3:0] irq_data_stage2_b;
    reg irq_valid_stage1_b;
    reg irq_valid_stage2_b;
    reg [1:0] irq_id_stage1_b;
    
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
    
    // Domain B pipeline stage 1: Synchronization
    always @(posedge clk_b or posedge rst_b) begin
        if (rst_b) begin
            irq_sync1_b <= 1'b0;
            irq_sync2_b <= 1'b0;
            prev_irq_sync_b <= 1'b0;
            irq_data_stage1_b <= 4'b0;
            irq_valid_stage1_b <= 1'b0;
        end else begin
            irq_sync1_b <= irq_toggle_a;
            irq_sync2_b <= irq_sync1_b;
            
            if (irq_sync2_b != prev_irq_sync_b) begin
                irq_data_stage1_b <= irq_detected_a;
                irq_valid_stage1_b <= 1'b1;
            end else begin
                irq_valid_stage1_b <= 1'b0;
            end
            prev_irq_sync_b <= irq_sync2_b;
        end
    end
    
    // Domain B pipeline stage 2: Priority Encoding
    always @(posedge clk_b or posedge rst_b) begin
        if (rst_b) begin
            irq_data_stage2_b <= 4'b0;
            irq_valid_stage2_b <= 1'b0;
            irq_id_stage1_b <= 2'b00;
        end else begin
            irq_data_stage2_b <= irq_data_stage1_b;
            irq_valid_stage2_b <= irq_valid_stage1_b;
            
            if (irq_valid_stage1_b) begin
                if (irq_data_stage1_b[3]) 
                    irq_id_stage1_b <= 2'd3;
                else if (irq_data_stage1_b[2]) 
                    irq_id_stage1_b <= 2'd2;
                else if (irq_data_stage1_b[1]) 
                    irq_id_stage1_b <= 2'd1;
                else if (irq_data_stage1_b[0]) 
                    irq_id_stage1_b <= 2'd0;
            end
        end
    end
    
    // Domain B pipeline stage 3: Output Generation
    always @(posedge clk_b or posedge rst_b) begin
        if (rst_b) begin
            irq_out_b <= 1'b0;
            irq_id_b <= 2'b00;
        end else begin
            irq_out_b <= irq_valid_stage2_b;
            irq_id_b <= irq_id_stage1_b;
        end
    end
endmodule