//SystemVerilog
// 顶层模块
module parallel_load_ring (
    input  wire       clk,
    input  wire       rst_n,         // 添加复位信号
    input  wire       load_req,      // 加载请求信号(原load)
    output reg        load_ack,      // 加载应答信号
    input  wire [3:0] parallel_in,
    output wire [3:0] ring
);
    // 内部连线
    wire [3:0] next_ring_value;
    wire       load_valid;
    reg        load_ready;
    
    // 请求-应答握手逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            load_ready <= 1'b0;
            load_ack <= 1'b0;
        end else begin
            load_ready <= load_req;
            load_ack <= load_ready & load_req;
        end
    end
    
    // 握手完成即为有效加载信号
    assign load_valid = load_req & load_ack;
    
    // 实例化数据路径子模块
    ring_datapath ring_data_inst (
        .load         (load_valid),
        .parallel_in  (parallel_in),
        .current_ring (ring),
        .next_ring    (next_ring_value)
    );
    
    // 实例化寄存器子模块
    ring_register ring_reg_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .next_value (next_ring_value),
        .ring_value (ring)
    );
    
endmodule

// 数据路径子模块 - 负责计算下一个环形状态
module ring_datapath (
    input  wire [3:0] parallel_in,
    input  wire [3:0] current_ring,
    input  wire       load,
    output reg  [3:0] next_ring
);
    // 实现多路复用器逻辑，使用if-else替代条件运算符
    always @(*) begin
        if (load) begin
            next_ring = parallel_in;
        end else begin
            next_ring = {current_ring[0], current_ring[3:1]};
        end
    end
    
endmodule

// 寄存器子模块 - 负责存储环形状态
module ring_register (
    input  wire       clk,
    input  wire       rst_n,         // 添加复位信号
    input  wire [3:0] next_value,
    output reg  [3:0] ring_value
);
    // 时序寄存器逻辑，增加复位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ring_value <= 4'b0000;
        end else begin
            ring_value <= next_value;
        end
    end
    
endmodule