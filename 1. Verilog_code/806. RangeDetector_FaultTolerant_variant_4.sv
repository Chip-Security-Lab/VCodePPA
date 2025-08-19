//SystemVerilog
module RangeDetector_FaultTolerant #(
    parameter WIDTH = 8,
    parameter TOLERANCE = 3
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] low_th,
    input [WIDTH-1:0] high_th,
    input valid_in,
    output ready_in,
    output reg alarm,
    output reg valid_out
);

    // Combinational logic signals
    wire out_of_range_comb;
    wire [1:0] err_count_next;
    
    // Sequential logic signals
    reg stage1_valid;
    reg [WIDTH-1:0] data_stage1, low_th_stage1, high_th_stage1;
    reg out_of_range_stage1;
    reg stage2_valid;
    reg [1:0] err_count;
    reg out_of_range_stage2;

    // Combinational logic
    assign ready_in = 1'b1;
    assign out_of_range_comb = (data_in < low_th || data_in > high_th);
    
    // Error counter next state logic
    assign err_count_next = (out_of_range_stage1) ? 
                           ((err_count < TOLERANCE) ? err_count + 1 : TOLERANCE) :
                           ((err_count > 0) ? err_count - 1 : 0);

    // Stage 1: Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            stage1_valid <= 1'b0;
            data_stage1 <= 0;
            low_th_stage1 <= 0;
            high_th_stage1 <= 0;
            out_of_range_stage1 <= 1'b0;
        end
        else begin
            stage1_valid <= valid_in;
            data_stage1 <= data_in;
            low_th_stage1 <= low_th;
            high_th_stage1 <= high_th;
            out_of_range_stage1 <= out_of_range_comb;
        end
    end

    // Stage 2: Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            stage2_valid <= 1'b0;
            err_count <= 0;
            out_of_range_stage2 <= 1'b0;
        end
        else begin
            stage2_valid <= stage1_valid;
            out_of_range_stage2 <= out_of_range_stage1;
            if(stage1_valid) begin
                err_count <= err_count_next;
            end
        end
    end

    // Output stage: Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            alarm <= 1'b0;
            valid_out <= 1'b0;
        end
        else begin
            valid_out <= stage2_valid;
            if(stage2_valid) begin
                alarm <= (err_count == TOLERANCE);
            end
        end
    end

endmodule