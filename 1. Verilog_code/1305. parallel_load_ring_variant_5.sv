//SystemVerilog
module parallel_load_ring (
    input  logic clk,
    input  logic rst_n,
    input  logic req,
    input  logic [3:0] parallel_in,
    output logic [3:0] ring,
    output logic ack
);
    // 内部连线
    logic req_stage1, req_stage2;
    logic [3:0] data_stage1, data_stage2;
    logic [3:0] shift_result;
    logic load_op;
    
    // 实例化请求检测和输入锁存模块
    input_stage input_processor (
        .clk(clk),
        .rst_n(rst_n),
        .req(req),
        .parallel_in(parallel_in),
        .req_stage1(req_stage1),
        .data_stage1(data_stage1),
        .load_op(load_op)
    );
    
    // 实例化数据处理模块
    processing_stage data_processor (
        .clk(clk),
        .rst_n(rst_n),
        .req_stage1(req_stage1),
        .data_stage1(data_stage1),
        .load_op(load_op),
        .ring(ring),
        .req_stage2(req_stage2),
        .data_stage2(data_stage2),
        .shift_result(shift_result)
    );
    
    // 实例化输出控制模块
    output_stage output_controller (
        .clk(clk),
        .rst_n(rst_n),
        .data_stage2(data_stage2),
        .load_op(load_op),
        .ring(ring),
        .ack(ack)
    );
    
endmodule

// 阶段1：请求检测和输入锁存模块
module input_stage (
    input  logic clk,
    input  logic rst_n,
    input  logic req,
    input  logic [3:0] parallel_in,
    output logic req_stage1,
    output logic [3:0] data_stage1,
    output logic load_op
);
    // 边沿检测逻辑
    logic req_prev;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_prev <= 1'b0;
            req_stage1 <= 1'b0;
            data_stage1 <= 4'b0000;
        end else begin
            req_prev <= req;
            req_stage1 <= req;
            data_stage1 <= parallel_in;
        end
    end
    
    // 上升沿检测电路，优化为组合逻辑
    assign load_op = req && !req_prev;
    
endmodule

// 阶段2：数据处理模块
module processing_stage (
    input  logic clk,
    input  logic rst_n,
    input  logic req_stage1,
    input  logic [3:0] data_stage1,
    input  logic load_op,
    input  logic [3:0] ring,
    output logic req_stage2,
    output logic [3:0] data_stage2,
    output logic [3:0] shift_result
);
    // 计算移位结果 - 优化为组合逻辑以减少时序关键路径
    assign shift_result = {ring[0], ring[3:1]};
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_stage2 <= 1'b0;
            data_stage2 <= 4'b0000;
        end else begin
            req_stage2 <= req_stage1;
            data_stage2 <= load_op ? data_stage1 : shift_result;
        end
    end
    
endmodule

// 阶段3：输出控制模块
module output_stage (
    input  logic clk,
    input  logic rst_n,
    input  logic [3:0] data_stage2,
    input  logic load_op,
    output logic [3:0] ring,
    output logic ack
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ring <= 4'b0000;
            ack <= 1'b0;
        end else begin
            ring <= data_stage2;
            ack <= load_op;
        end
    end
    
endmodule