//SystemVerilog
module shadow_reg_sync #(parameter WIDTH=8) (
    input clk, rst_n, en,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    // Shadow register to temporarily store input data
    reg [WIDTH-1:0] shadow;
    reg borrow; // Borrow signal for the subtractor
    reg [WIDTH-1:0] sub_result; // Result of the subtraction

    // Shadow register update logic
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            shadow <= {WIDTH{1'b0}};
        else if(en)
            shadow <= data_in;
    end

    // Borrowing subtractor logic
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_out <= {WIDTH{1'b0}};
            borrow <= 1'b0;
        end else if(!en) begin
            {borrow, sub_result} <= {1'b0, shadow} - {1'b0, data_in}; // Borrowing subtraction
            data_out <= sub_result; // Update output with subtraction result
        end
    end
endmodule