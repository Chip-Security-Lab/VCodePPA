//SystemVerilog
// SystemVerilog IEEE 1364-2005
module round_robin_arbiter #(parameter WIDTH=4) (
    input  logic clk,
    input  logic rst_n,
    input  logic [WIDTH-1:0] req_i,
    output logic [WIDTH-1:0] grant_o
);
    logic [WIDTH-1:0] last_grant;
    logic [WIDTH-1:0] next_grant;
    logic [31:0] priority_idx;

    // 优先级计算模块
    priority_index_generator #(
        .WIDTH(WIDTH)
    ) priority_gen (
        .last_grant(last_grant),
        .priority_idx(priority_idx)
    );

    // 仲裁决策模块
    arbiter_decision_logic #(
        .WIDTH(WIDTH)
    ) arbiter_logic (
        .req_i(req_i),
        .priority_idx(priority_idx),
        .next_grant(next_grant)
    );

    // 状态更新模块
    state_update #(
        .WIDTH(WIDTH)
    ) state_update_inst (
        .clk(clk),
        .rst_n(rst_n),
        .next_grant(next_grant),
        .grant_o(grant_o),
        .last_grant(last_grant)
    );
endmodule

//优先级索引生成模块
module priority_index_generator #(parameter WIDTH=4) (
    input  logic [WIDTH-1:0] last_grant,
    output logic [31:0] priority_idx
);
    // 使用补码加法实现加1操作
    logic [31:0] one_complement; // 1的补码表示
    logic [31:0] width_complement; // WIDTH的补码表示
    logic [31:0] temp_sum;
    logic [31:0] wrapped_idx;
    
    assign one_complement = 32'h00000001; // 1的补码表示就是1本身
    assign width_complement = WIDTH; // WIDTH的补码表示
    
    // 使用补码加法实现 last_grant + 1
    assign temp_sum = {28'b0, last_grant} + one_complement;
    
    // 使用补码加法实现取模操作
    // 如果 temp_sum >= WIDTH，则需要减去WIDTH
    // 使用补码加法实现减法：temp_sum + (~WIDTH + 1)
    assign wrapped_idx = (temp_sum >= width_complement) ? 
                          temp_sum + (~width_complement + 32'h00000001) : 
                          temp_sum;
    
    assign priority_idx = wrapped_idx;
endmodule

//仲裁决策逻辑模块
module arbiter_decision_logic #(parameter WIDTH=4) (
    input  logic [WIDTH-1:0] req_i,
    input  logic [31:0] priority_idx,
    output logic [WIDTH-1:0] next_grant
);
    logic [WIDTH-1:0] masked_req;
    logic [WIDTH-1:0] priority_grant;
    logic [WIDTH-1:0] default_grant;
    logic no_priority_req;
    logic [31:0] current_idx;
    logic [31:0] one_complement;

    // 实现循环优先级仲裁逻辑
    always_comb begin
        next_grant = 0;
        masked_req = 0;
        priority_grant = 0;
        default_grant = 0;
        no_priority_req = 1;
        current_idx = priority_idx;
        one_complement = 32'h00000001;

        // 计算从优先级位置开始的请求
        for (int i = 0; i < WIDTH; i = i + 1) begin
            // 使用补码加法计算索引，替代 (priority_idx + i) % WIDTH
            if (req_i[current_idx[1:0]] && no_priority_req) begin
                priority_grant[current_idx[1:0]] = 1'b1;
                no_priority_req = 0;
            end
            
            // 更新索引，使用补码加法实现加1并取模
            current_idx = current_idx + one_complement;
            if (current_idx >= WIDTH) begin
                current_idx = current_idx + (~32'(WIDTH) + 32'h00000001);
            end
        end

        // 如果有请求，选择第一个
        if (|priority_grant) begin
            next_grant = priority_grant;
        end
    end
endmodule

//状态更新模块
module state_update #(parameter WIDTH=4) (
    input  logic clk,
    input  logic rst_n,
    input  logic [WIDTH-1:0] next_grant,
    output logic [WIDTH-1:0] grant_o,
    output logic [WIDTH-1:0] last_grant
);
    // 时序逻辑：更新输出授权和上一次授权记录
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_o <= 0;
            last_grant <= 0;
        end 
        else begin
            grant_o <= next_grant;
            if (|next_grant) begin
                for (int i = 0; i < WIDTH; i = i + 1) begin
                    if (next_grant[i]) begin
                        last_grant <= i;
                    end
                end
            end
        end
    end
endmodule