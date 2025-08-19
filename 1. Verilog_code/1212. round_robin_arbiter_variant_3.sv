//SystemVerilog
// 顶层模块 - 连接各子模块的主控模块
module round_robin_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output [WIDTH-1:0] grant_o
);
    // 内部信号定义
    wire [WIDTH-1:0] priority_mask;
    wire [31:0] next_priority;
    wire [WIDTH-1:0] grant_combo;
    reg [31:0] last_priority;

    // 优先级掩码计算模块实例化 (纯组合逻辑)
    priority_mask_generator #(
        .WIDTH(WIDTH)
    ) priority_mask_gen_inst (
        .last_priority(last_priority),
        .priority_mask(priority_mask)
    );

    // 优先级编码器模块实例化 (纯组合逻辑)
    priority_encoder #(
        .WIDTH(WIDTH)
    ) priority_enc_inst (
        .req_i(req_i),
        .priority_mask(priority_mask),
        .next_priority(next_priority)
    );

    // 请求处理模块实例化 (纯组合逻辑)
    request_processor #(
        .WIDTH(WIDTH)
    ) req_proc_inst (
        .req_i(req_i),
        .priority_mask(priority_mask),
        .grant_o(grant_combo)
    );

    // 状态更新模块实例化 (纯时序逻辑)
    state_register #(
        .WIDTH(WIDTH)
    ) state_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .next_priority(next_priority),
        .grant_i(grant_combo),
        .last_priority(last_priority)
    );

    // 输出赋值
    assign grant_o = grant_combo;
endmodule

// 优先级掩码生成器 - 纯组合逻辑模块
module priority_mask_generator #(parameter WIDTH=4) (
    input [31:0] last_priority,
    output [WIDTH-1:0] priority_mask
);
    // 生成优先级掩码
    genvar i;
    generate
        for(i=0; i<WIDTH; i=i+1) begin : gen_priority_mask
            assign priority_mask[i] = ((last_priority + i + 1) % WIDTH);
        end
    endgenerate
endmodule

// 优先级编码器 - 纯组合逻辑模块
module priority_encoder #(parameter WIDTH=4) (
    input [WIDTH-1:0] req_i,
    input [WIDTH-1:0] priority_mask,
    output [31:0] next_priority
);
    // 内部组合逻辑信号
    reg [31:0] next_priority_combo;
    reg found_combo;
    integer j;
    
    // 组合逻辑块
    always @(*) begin
        found_combo = 1'b0;
        next_priority_combo = 32'd0;
        
        for(j=0; j<WIDTH; j=j+1) begin
            if(req_i[priority_mask[j]] && !found_combo) begin
                next_priority_combo = priority_mask[j];
                found_combo = 1'b1;
            end
        end
    end
    
    // 输出赋值
    assign next_priority = next_priority_combo;
endmodule

// 请求处理模块 - 纯组合逻辑模块
module request_processor #(parameter WIDTH=4) (
    input [WIDTH-1:0] req_i,
    input [WIDTH-1:0] priority_mask,
    output [WIDTH-1:0] grant_o
);
    // 内部组合逻辑信号
    reg [WIDTH-1:0] grant_combo;
    reg found_combo;
    integer k;
    
    // 组合逻辑块
    always @(*) begin
        found_combo = 1'b0;
        grant_combo = {WIDTH{1'b0}};
        
        for(k=0; k<WIDTH; k=k+1) begin
            if(req_i[priority_mask[k]] && !found_combo) begin
                grant_combo = (1'b1 << priority_mask[k]);
                found_combo = 1'b1;
            end
        end
    end
    
    // 输出赋值
    assign grant_o = grant_combo;
endmodule

// 状态寄存器模块 - 纯时序逻辑模块
module state_register #(parameter WIDTH=4) (
    input clk, rst_n,
    input [31:0] next_priority,
    input [WIDTH-1:0] grant_i,
    output reg [31:0] last_priority
);
    // 仅时序逻辑块 - 状态更新
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            last_priority <= 32'd0;
        end else if(|grant_i) begin
            last_priority <= next_priority;
        end
    end
endmodule