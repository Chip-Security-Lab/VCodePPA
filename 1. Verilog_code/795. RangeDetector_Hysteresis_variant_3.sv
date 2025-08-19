//SystemVerilog
module RangeDetector_Hysteresis #(
    parameter WIDTH = 8,
    parameter HYST = 3
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] center,
    output reg out_high
);

    // Stage 1: Calculate threshold values and comparisons
    reg [WIDTH-1:0] upper_stage1, lower_stage1;
    reg [WIDTH-1:0] data_in_stage1;
    
    // Stage 2: Perform comparisons
    reg upper_comp_stage2, lower_comp_stage2;
    reg [1:0] state_sel_stage2;
    
    // Stage 3: Update output state
    reg out_high_next;
    
    // Stage 1: Calculate thresholds
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            upper_stage1 <= 0;
            lower_stage1 <= 0;
            data_in_stage1 <= 0;
        end else begin
            upper_stage1 <= center + HYST;
            lower_stage1 <= center - HYST;
            data_in_stage1 <= data_in;
        end
    end
    
    // Stage 2: Perform comparisons
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            upper_comp_stage2 <= 1'b0;
            lower_comp_stage2 <= 1'b0;
            state_sel_stage2 <= 2'b00;
        end else begin
            upper_comp_stage2 <= (data_in_stage1 >= upper_stage1);
            lower_comp_stage2 <= (data_in_stage1 <= lower_stage1);
            state_sel_stage2 <= {upper_comp_stage2, lower_comp_stage2};
        end
    end
    
    // Stage 3: Determine next output state
    always @(*) begin
        case(state_sel_stage2)
            2'b10: out_high_next = 1'b1;
            2'b01: out_high_next = 1'b0;
            default: out_high_next = out_high;
        endcase
    end
    
    // Register the output
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            out_high <= 1'b0;
        else
            out_high <= out_high_next;
    end

endmodule