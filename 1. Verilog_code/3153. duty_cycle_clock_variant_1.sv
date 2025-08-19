//SystemVerilog
module duty_cycle_clock #(
    parameter WIDTH = 8
)(
    input wire clkin,
    input wire reset,
    input wire [WIDTH-1:0] high_time,
    input wire [WIDTH-1:0] low_time,
    output reg clkout
);
    reg [WIDTH-1:0] counter;
    reg [WIDTH-1:0] target_time;
    reg comp_result;
    wire [WIDTH-1:0] inverted_counter;
    wire [WIDTH-1:0] adder_result;
    wire carry_out;
    
    // 条件反相减法器实现
    assign inverted_counter = ~counter;
    assign {carry_out, adder_result} = inverted_counter + target_time + 1'b1;
    
    always @(*) begin
        if (clkout) begin
            target_time = high_time;
        end else begin
            target_time = low_time;
        end
        comp_result = carry_out;
    end
    
    always @(posedge clkin or posedge reset) begin
        if (reset) begin
            counter <= 0;
            clkout <= 0;
        end else begin
            if (comp_result) begin
                counter <= 0;
                clkout <= ~clkout;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end
endmodule