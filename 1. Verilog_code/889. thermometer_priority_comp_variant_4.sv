//SystemVerilog
module thermometer_priority_comp #(parameter WIDTH = 8)(
    input wire clk, rst_n,
    input wire [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] thermometer_out,
    output reg [$clog2(WIDTH)-1:0] priority_pos
);

    reg [$clog2(WIDTH)-1:0] next_priority_pos;
    reg [WIDTH-1:0] next_thermometer;
    reg [WIDTH-1:0] priority_mask;
    reg [WIDTH-1:0] thermometer_mask;

    // 优先级位置查找
    always @(*) begin
        next_priority_pos = {$clog2(WIDTH){1'b0}};
        for (integer i = 0; i < WIDTH; i = i + 1) begin
            if (data_in[i]) begin
                next_priority_pos = i[$clog2(WIDTH)-1:0];
            end
        end
    end

    // 优先级掩码生成
    always @(*) begin
        priority_mask = {WIDTH{1'b0}};
        for (integer i = 0; i < WIDTH; i = i + 1) begin
            if (i <= next_priority_pos) begin
                priority_mask[i] = 1'b1;
            end
        end
    end

    // 热度计输出生成
    always @(*) begin
        next_thermometer = priority_mask;
    end

    // 时序逻辑 - 优先级位置寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_pos <= {$clog2(WIDTH){1'b0}};
        end else begin
            priority_pos <= next_priority_pos;
        end
    end

    // 时序逻辑 - 热度计输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            thermometer_out <= {WIDTH{1'b0}};
        end else begin
            thermometer_out <= next_thermometer;
        end
    end

endmodule