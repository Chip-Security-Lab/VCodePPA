//SystemVerilog
module reg_config_reset(
    input wire clk,
    input wire rst_n,
    input wire [7:0] config_data,
    input wire config_valid,
    input wire reset_trigger,
    output reg [7:0] reset_out,
    output reg output_valid
);
    // Stage 1: Config registration
    reg [7:0] config_reg;
    reg config_valid_stage1;
    reg reset_trigger_stage1;
    
    // Stage 2: Reset processing
    reg [7:0] config_reg_stage2;
    reg reset_trigger_stage2;
    reg valid_stage2;
    
    // Pipeline stage 1: Save configuration data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            config_reg <= 8'h0;
            config_valid_stage1 <= 1'b0;
            reset_trigger_stage1 <= 1'b0;
        end else if (config_valid) begin
            config_reg <= config_data;
            config_valid_stage1 <= 1'b1;
            reset_trigger_stage1 <= reset_trigger;
        end else begin
            config_reg <= config_reg;
            config_valid_stage1 <= 1'b0;
            reset_trigger_stage1 <= reset_trigger;
        end
    end
    
    // Pipeline stage 2: Prepare reset value
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            config_reg_stage2 <= 8'h0;
            reset_trigger_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            config_reg_stage2 <= config_reg;
            reset_trigger_stage2 <= reset_trigger_stage1;
            valid_stage2 <= config_valid_stage1;
        end
    end
    
    // Output stage: Generate final output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_out <= 8'h0;
            output_valid <= 1'b0;
        end else if (valid_stage2 && reset_trigger_stage2) begin
            reset_out <= config_reg_stage2;
            output_valid <= 1'b1;
        end else if (valid_stage2 && !reset_trigger_stage2) begin
            reset_out <= 8'h0;
            output_valid <= 1'b1;
        end else begin
            reset_out <= 8'h0;
            output_valid <= 1'b0;
        end
    end
endmodule