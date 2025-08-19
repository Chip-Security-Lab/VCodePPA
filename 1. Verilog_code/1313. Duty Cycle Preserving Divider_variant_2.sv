//SystemVerilog
module duty_preserve_divider (
    input wire clock_in, 
    input wire n_reset, 
    input wire [3:0] div_ratio,
    output reg clock_out
);
    reg [3:0] counter;
    wire counter_max;
    
    // 使用比较器而非减法运算，减少逻辑深度
    assign counter_max = (counter == (div_ratio - 1'b1));
    
    always @(posedge clock_in or negedge n_reset) begin
        if (!n_reset) begin
            counter <= 4'd0;
            clock_out <= 1'b0;
        end else begin
            if (counter_max) begin
                counter <= 4'd0;
                clock_out <= ~clock_out; // 翻转输出以保持50%占空比
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end
endmodule