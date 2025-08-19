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
    // Register input signals to reduce input-to-register delay
    reg [WIDTH-1:0] data_in_reg, center_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_in_reg <= 0;
            center_reg <= 0;
        end else begin
            data_in_reg <= data_in;
            center_reg <= center;
        end
    end
    
    // Compute thresholds on registered inputs
    wire [WIDTH-1:0] upper = center_reg + HYST;
    wire [WIDTH-1:0] lower = center_reg - HYST;
    
    // Generate control signals based on registered inputs
    reg [1:0] range_status;
    
    always @(*) begin
        if(data_in_reg >= upper) 
            range_status = 2'b01;      // 高于上限
        else if(data_in_reg <= lower) 
            range_status = 2'b10;      // 低于下限
        else 
            range_status = 2'b00;      // 在中间范围
    end
    
    // Update output based on range status
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) 
            out_high <= 1'b0;
        else begin
            case(range_status)
                2'b01: out_high <= 1'b1;    // 高于上限
                2'b10: out_high <= 1'b0;    // 低于下限
                default: out_high <= out_high; // 保持状态不变
            endcase
        end
    end
endmodule