//SystemVerilog
module RangeDetector_StateHold #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    output reg state_flag
);

    reg [1:0] compare_result_reg;
    reg [1:0] compare_result;
    
    always @(*) begin
        if (data_in > threshold)
            compare_result = 2'b01;
        else if (data_in < threshold)
            compare_result = 2'b10;
        else
            compare_result = 2'b00;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            compare_result_reg <= 2'b00;
            state_flag <= 1'b0;
        end else begin
            compare_result_reg <= compare_result;
            case (compare_result_reg)
                2'b01:   state_flag <= 1'b1;
                2'b10:   state_flag <= 1'b0;
                default: state_flag <= state_flag;
            endcase
        end
    end
    
endmodule