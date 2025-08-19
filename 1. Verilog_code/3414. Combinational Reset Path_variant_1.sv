//SystemVerilog
module RD4 #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] in_data,
    input wire clk,
    input wire rst,
    output reg [WIDTH-1:0] out_data
);

    // Pipeline registers
    reg [WIDTH-1:0] data_stage1;
    reg [WIDTH-1:0] data_stage2;
    
    // Two's complement subtraction signals
    wire [WIDTH-1:0] inverted_data;
    wire [WIDTH-1:0] subtraction_result;
    
    // Invert bits for two's complement
    assign inverted_data = ~in_data;
    // Add 1 to complete two's complement
    assign subtraction_result = inverted_data + 1'b1;
    
    // First pipeline stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_stage1 <= {WIDTH{1'b0}};
        end else begin
            data_stage1 <= subtraction_result;
        end
    end
    
    // Second pipeline stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_stage2 <= {WIDTH{1'b0}};
        end else begin
            data_stage2 <= data_stage1;
        end
    end
    
    // Output assignment (registered to improve timing)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_data <= {WIDTH{1'b0}};
        end else begin
            out_data <= data_stage2;
        end
    end

endmodule