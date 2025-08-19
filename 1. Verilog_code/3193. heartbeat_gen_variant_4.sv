//SystemVerilog
module heartbeat_gen #(
    parameter IDLE_CYCLES = 1000,
    parameter PULSE_CYCLES = 50
)(
    input clk,
    input rst,
    output heartbeat
);
    // 计算所需的比特宽度
    localparam CNT_WIDTH = $clog2(IDLE_CYCLES + PULSE_CYCLES);
    
    // 内部连线
    wire [CNT_WIDTH-1:0] counter_value;
    wire counter_max_reached;
    
    // 实例化计数器子模块
    cycle_counter #(
        .CNT_WIDTH(CNT_WIDTH),
        .MAX_COUNT(IDLE_CYCLES + PULSE_CYCLES - 1)
    ) counter_inst (
        .clk(clk),
        .rst(rst),
        .enable(1'b1),
        .counter(counter_value),
        .max_reached(counter_max_reached)
    );
    
    // 实例化脉冲生成器子模块
    pulse_generator #(
        .CNT_WIDTH(CNT_WIDTH),
        .IDLE_CYCLES(IDLE_CYCLES),
        .PULSE_CYCLES(PULSE_CYCLES)
    ) pulse_gen_inst (
        .clk(clk),
        .rst(rst),
        .counter_value(counter_value),
        .counter_max_reached(counter_max_reached),
        .pulse_out(heartbeat)
    );
    
endmodule

//SystemVerilog
module cycle_counter #(
    parameter CNT_WIDTH = 10,
    parameter MAX_COUNT = 1049
)(
    input clk,
    input rst,
    input enable,
    output reg [CNT_WIDTH-1:0] counter,
    output reg max_reached
);
    // 使用参数化的计数器，减少资源使用
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            max_reached <= 0;
        end else if (enable) begin
            if (counter == MAX_COUNT) begin
                counter <= 0;
                max_reached <= 1;
            end else begin
                counter <= counter + 1'b1;
                max_reached <= 0;
            end
        end
    end
endmodule

//SystemVerilog
module pulse_generator #(
    parameter CNT_WIDTH = 10,
    parameter IDLE_CYCLES = 1000,
    parameter PULSE_CYCLES = 50
)(
    input clk,
    input rst,
    input [CNT_WIDTH-1:0] counter_value,
    input counter_max_reached,
    output reg pulse_out
);
    // 预计算比较值以提高效率
    localparam [CNT_WIDTH-1:0] IDLE_THRESHOLD = IDLE_CYCLES - 1;
    localparam [CNT_WIDTH-1:0] TOTAL_CYCLES = IDLE_CYCLES + PULSE_CYCLES - 1;
    
    // 脉冲生成逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pulse_out <= 0;
        end else begin
            // 优化的比较逻辑，使用单一等式检查提高性能
            pulse_out <= (counter_value >= IDLE_THRESHOLD) && (counter_value < TOTAL_CYCLES);
        end
    end
endmodule