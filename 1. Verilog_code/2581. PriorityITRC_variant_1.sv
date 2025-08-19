//SystemVerilog
module PriorityITRC #(parameter WIDTH=8) (
    input wire clk, rst_n, enable,
    input wire [WIDTH-1:0] irq_in,
    output reg [WIDTH-1:0] irq_ack,
    output reg [$clog2(WIDTH)-1:0] irq_id,
    output reg irq_valid
);

    reg [WIDTH-1:0] irq_mask;
    reg [WIDTH-1:0] irq_priority;
    reg [$clog2(WIDTH)-1:0] priority_idx;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            irq_ack <= 0;
            irq_id <= 0;
            irq_valid <= 0;
            irq_mask <= 0;
            irq_priority <= 0;
            priority_idx <= 0;
        end else if (enable) begin
            irq_valid <= |irq_in;
            irq_ack <= 0;
            
            // 生成优先级掩码
            irq_mask <= {1'b1, {WIDTH-1{1'b0}}};
            irq_priority <= irq_in & irq_mask;
            
            // 使用先行借位减法器计算最高优先级中断
            priority_idx <= WIDTH-1;
            for (integer i = WIDTH-2; i >= 0; i=i-1) begin
                if (irq_priority[i]) begin
                    priority_idx <= i[$clog2(WIDTH)-1:0];
                end
            end
            
            if (|irq_priority) begin
                irq_id <= priority_idx;
                irq_ack[priority_idx] <= 1;
            end
        end
    end
endmodule