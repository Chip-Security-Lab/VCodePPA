module PriorityITRC #(parameter WIDTH=8) (
    input wire clk, rst_n, enable,
    input wire [WIDTH-1:0] irq_in,
    output reg [WIDTH-1:0] irq_ack,
    output reg [$clog2(WIDTH)-1:0] irq_id,
    output reg irq_valid
);
    integer i;
    reg found;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            irq_ack <= 0;
            irq_id <= 0;
            irq_valid <= 0;
            found <= 0;
        end else if (enable) begin
            irq_valid <= |irq_in;
            irq_ack <= 0;
            found <= 0;
            
            for (i = WIDTH-1; i >= 0; i=i-1) begin
                if (irq_in[i] && !found) begin
                    irq_id <= i[$clog2(WIDTH)-1:0];
                    irq_ack[i] <= 1;
                    found <= 1; // 使用标志位而不是跳出循环
                end
            end
        end
    end
endmodule