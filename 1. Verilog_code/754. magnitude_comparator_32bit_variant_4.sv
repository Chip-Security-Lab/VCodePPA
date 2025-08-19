//SystemVerilog
module magnitude_comparator_32bit(
    input [31:0] a_vector,
    input [31:0] b_vector,
    output [1:0] comp_result  // 2'b00: equal, 2'b01: a<b, 2'b10: a>b
);
    // Priority encoded comparison result
    reg [1:0] result;
    
    always @(*) begin
        if (a_vector > b_vector) begin
            result = 2'b10;  // A greater than B
        end else if (a_vector == b_vector) begin
            result = 2'b00;  // Equal
        end else begin
            result = 2'b01;  // A less than B
        end
    end
    
    assign comp_result = result;
endmodule