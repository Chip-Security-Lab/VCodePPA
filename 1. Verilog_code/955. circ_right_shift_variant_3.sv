//SystemVerilog
module circ_right_shift #(parameter BITS = 8) (
    input wire clk,
    input wire rst_n,
    input wire en,
    output wire [BITS-1:0] q
);
    reg [BITS-1:0] shifter;
    reg [BITS-1:0] next_shifter;
    wire borrow;
    wire [BITS-1:0] sub_result;
    
    // 条件求和减法算法实现
    assign {borrow, sub_result} = {1'b0, shifter} - {1'b0, {BITS{1'b0}}};
    
    always @(*) begin
        if (en) begin
            next_shifter = {shifter[0], shifter[BITS-1:1]};
        end else begin
            next_shifter = shifter;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shifter <= {{BITS-1{1'b0}}, 1'b1};  // Initialize with one hot
        else
            shifter <= next_shifter;
    end
    
    assign q = shifter;
endmodule