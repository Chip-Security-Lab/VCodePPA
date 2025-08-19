//SystemVerilog
module programmable_shadow_reg_pipeline #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire [1:0] update_mode,
    input wire manual_trigger,
    input wire [WIDTH-1:0] threshold,
    output reg [WIDTH-1:0] shadow_data,
    output reg updated
);

    // Pipeline registers
    reg [WIDTH-1:0] main_reg_stage1;
    reg [WIDTH-1:0] main_reg_stage2;
    reg [1:0] update_mode_stage1;
    reg manual_trigger_stage1;
    reg [WIDTH-1:0] threshold_stage1;

    // Stage 1: Update main register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            main_reg_stage1 <= 0;
        else
            main_reg_stage1 <= data_in;
    end

    // Stage 2: Propagate main register to next stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            main_reg_stage2 <= 0;
        else
            main_reg_stage2 <= main_reg_stage1;
    end

    // Pipeline control signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            update_mode_stage1 <= 0;
            manual_trigger_stage1 <= 0;
            threshold_stage1 <= 0;
        end else begin
            update_mode_stage1 <= update_mode;
            manual_trigger_stage1 <= manual_trigger;
            threshold_stage1 <= threshold;
        end
    end

    // Stage 3: Programmable shadow update logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_data <= 0;
            updated <= 0;
        end else begin
            updated <= 0;

            case (update_mode_stage1)
                2'b00: begin // Manual update
                    if (manual_trigger_stage1) begin
                        shadow_data <= main_reg_stage2;
                        updated <= 1;
                    end
                end
                
                2'b01: begin // Threshold-based update
                    if (main_reg_stage2 > threshold_stage1) begin
                        shadow_data <= main_reg_stage2;
                        updated <= 1;
                    end
                end
                
                2'b10: begin // Change-based update
                    if (main_reg_stage2 != shadow_data) begin
                        shadow_data <= main_reg_stage2;
                        updated <= 1;
                    end
                end
                
                2'b11: begin // Periodic update
                    if (main_reg_stage2 != data_in) begin
                        shadow_data <= main_reg_stage2;
                        updated <= 1;
                    end
                end
            endcase
        end
    end
endmodule