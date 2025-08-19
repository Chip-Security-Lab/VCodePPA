//SystemVerilog
// SystemVerilog
// IEEE 1364-2005 Verilog Standard
module timeout_shadow_reg #(
    parameter WIDTH = 8,
    parameter TIMEOUT = 4
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire data_valid,
    output reg [WIDTH-1:0] shadow_out
);
    // Pipeline stage 1: Input data registration
    reg [WIDTH-1:0] data_reg_stage1;
    reg data_valid_stage1;
    
    // Pipeline stage 2: Intermediate data storage
    reg [WIDTH-1:0] data_reg_stage2;
    
    // Timeout counter with multiple stages
    reg [$clog2(TIMEOUT)-1:0] timeout_cnt_stage1;
    reg [$clog2(TIMEOUT)-1:0] timeout_cnt_stage2;
    reg [$clog2(TIMEOUT)-1:0] timeout_cnt_stage3;
    
    // Timeout detection signals
    reg timeout_detected_stage2;
    reg timeout_detected_stage3;
    
    // Stage 1: Input registration and initial timeout processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg_stage1 <= 0;
            data_valid_stage1 <= 0;
            timeout_cnt_stage1 <= 0;
        end else begin
            data_reg_stage1 <= data_in;
            data_valid_stage1 <= data_valid;
            
            case (data_valid)
                1'b1: timeout_cnt_stage1 <= TIMEOUT;
                1'b0: timeout_cnt_stage1 <= (timeout_cnt_stage1 > 0) ? timeout_cnt_stage1 - 1 : 0;
            endcase
        end
    end
    
    // Stage 2: Timeout counter processing and data propagation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg_stage2 <= 0;
            timeout_cnt_stage2 <= 0;
            timeout_detected_stage2 <= 0;
        end else begin
            data_reg_stage2 <= data_reg_stage1;
            timeout_cnt_stage2 <= timeout_cnt_stage1;
            timeout_detected_stage2 <= (timeout_cnt_stage1 == 1);
        end
    end
    
    // Stage 3: Final timeout processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout_cnt_stage3 <= 0;
            timeout_detected_stage3 <= 0;
        end else begin
            timeout_cnt_stage3 <= timeout_cnt_stage2;
            timeout_detected_stage3 <= timeout_detected_stage2;
        end
    end
    
    // Shadow register update (final pipeline stage)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_out <= 0;
        else begin
            case (timeout_detected_stage3)
                1'b1: shadow_out <= data_reg_stage2;
                1'b0: shadow_out <= shadow_out;
            endcase
        end
    end
endmodule