//SystemVerilog
//==================== 顶层模块 ====================
module int_ctrl_delayed #(
    parameter CYCLE = 2
)(
    input wire clk,
    input wire rst,
    input wire [7:0] req_in,
    output wire [2:0] delayed_grant
);
    // 内部连线
    wire [7:0] delayed_req;
    
    // 实例化管道延迟模块
    request_pipeline #(
        .PIPELINE_DEPTH(CYCLE)
    ) req_pipe_inst (
        .clk(clk),
        .rst(rst),
        .req_in(req_in),
        .req_out(delayed_req)
    );
    
    // 实例化优先级编码器模块
    priority_encoder pr_encoder_inst (
        .clk(clk),
        .rst(rst),
        .req_in(delayed_req),
        .grant_out(delayed_grant)
    );
    
endmodule

//==================== 管道延迟模块 ====================
module request_pipeline #(
    parameter PIPELINE_DEPTH = 2
)(
    input wire clk,
    input wire rst,
    input wire [7:0] req_in,
    output wire [7:0] req_out
);
    // 管道寄存器
    reg [7:0] req_pipe_0;
    reg [7:0] req_pipe_1;
    
    always @(posedge clk) begin
        if (rst) begin
            req_pipe_0 <= 8'b0;
            req_pipe_1 <= 8'b0;
        end else begin
            req_pipe_0 <= req_in;
            req_pipe_1 <= req_pipe_0;
        end
    end
    
    // 连接输出
    assign req_out = req_pipe_1;
    
endmodule

//==================== 优先级编码器模块 ====================
module priority_encoder (
    input wire clk,
    input wire rst,
    input wire [7:0] req_in,
    output reg [2:0] grant_out
);
    
    // 优先级编码逻辑
    wire [2:0] encoded_value;
    
    // 组合逻辑部分
    priority_encoder_logic pr_logic (
        .req_value(req_in),
        .encoded_value(encoded_value)
    );
    
    // 时序逻辑部分
    always @(posedge clk) begin
        if (rst) begin
            grant_out <= 3'b0;
        end else begin
            grant_out <= encoded_value;
        end
    end
    
endmodule

//==================== 优先级编码组合逻辑 ====================
module priority_encoder_logic (
    input wire [7:0] req_value,
    output wire [2:0] encoded_value
);
    
    reg [2:0] result;
    
    always @(*) begin
        casez(req_value)
            8'b1???????: result = 3'd7;
            8'b01??????: result = 3'd6;
            8'b001?????: result = 3'd5;
            8'b0001????: result = 3'd4;
            8'b00001???: result = 3'd3;
            8'b000001??: result = 3'd2;
            8'b0000001?: result = 3'd1;
            8'b00000001: result = 3'd0;
            default: result = 3'd0;
        endcase
    end
    
    assign encoded_value = result;
    
endmodule