//SystemVerilog
module shadow_reg_hier #(parameter DW=16) (
    input wire clk,
    input wire rst_n,
    input wire main_en,
    input wire sub_en,
    input wire [DW-1:0] main_data,
    input wire data_valid_in,
    output wire [DW-1:0] final_data,
    output wire data_valid_out
);
    // Pipeline stage registers with combined valid-data registers for better resource utilization
    reg [DW-1:0] stage1_data, stage2_data;
    reg stage1_valid, stage2_valid;
    
    // Optimized Stage 1: Input capture with simplified control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= {DW{1'b0}};
            stage1_valid <= 1'b0;
        end else begin
            // Simplified condition logic - only update when both main_en and data_valid_in are true
            stage1_valid <= main_en & data_valid_in;
            if (main_en & data_valid_in) begin
                stage1_data <= main_data;
            end
        end
    end

    // Optimized Stage 2: Shadow register with simplified control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_data <= {DW{1'b0}};
            stage2_valid <= 1'b0;
        end else begin
            // Simplified condition logic - only update when both sub_en and stage1_valid are true
            stage2_valid <= sub_en & stage1_valid;
            if (sub_en & stage1_valid) begin
                stage2_data <= stage1_data;
            end
        end
    end

    // Direct output assignment
    assign final_data = stage2_data;
    assign data_valid_out = stage2_valid;
endmodule