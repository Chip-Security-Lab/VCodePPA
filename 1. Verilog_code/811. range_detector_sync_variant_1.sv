//SystemVerilog
module range_detector_sync(
    input wire clk, rst_n,
    input wire valid_in,
    output reg ready_out,
    input wire [7:0] data_in,
    input wire [7:0] lower_bound, upper_bound,
    output reg valid_out,
    input wire ready_in,
    output reg in_range
);
    reg compare_result;
    reg data_valid;
    
    optimized_comparator comp_inst (
        .data(data_in),
        .lower(lower_bound),
        .upper(upper_bound),
        .result(compare_result)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_range <= 1'b0;
            ready_out <= 1'b1;
            valid_out <= 1'b0;
            data_valid <= 1'b0;
        end
        else begin
            if (valid_in && ready_out) begin
                data_valid <= 1'b1;
                ready_out <= 1'b0;
            end
            
            if (data_valid && ready_in) begin
                in_range <= compare_result;
                valid_out <= 1'b1;
                ready_out <= 1'b1;
                data_valid <= 1'b0;
            end
            else if (!ready_in) begin
                valid_out <= 1'b0;
            end
        end
    end
endmodule

module optimized_comparator(
    input wire [7:0] data,
    input wire [7:0] lower,
    input wire [7:0] upper,
    output reg result
);
    wire [8:0] upper_diff, lower_diff;
    
    assign upper_diff = {1'b0, upper} - {1'b0, data};
    assign lower_diff = {1'b0, data} - {1'b0, lower};
    
    always @(*) begin
        result = ~(upper_diff[8] | lower_diff[8]);
    end
endmodule