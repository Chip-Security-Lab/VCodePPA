//SystemVerilog IEEE 1364-2005
module config_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    input [1:0] mode,
    input [WIDTH-1:0] cfg_reg,
    output reg [WIDTH-1:0] grant_o,
    // 流水线控制信号
    input valid_i,
    output reg valid_o,
    input ready_i,
    output reg ready_o
);
    // 第一级流水线:处理输入和解码模式
    reg [WIDTH-1:0] req_stage1;
    reg [1:0] mode_stage1;
    reg [WIDTH-1:0] cfg_reg_stage1;
    reg [$clog2(WIDTH)-1:0] ptr, ptr_stage1;
    reg valid_stage1;
    
    // 第二级流水线:仲裁计算
    reg [WIDTH-1:0] fixed_grant;
    reg [WIDTH-1:0] rr_grant;
    reg [WIDTH-1:0] prio_grant;
    reg [WIDTH-1:0] rand_grant;
    reg [WIDTH-1:0] mask, mask_stage1, mask_stage2;
    reg valid_stage2;
    
    // 第三级流水线:输出选择
    reg [1:0] mode_stage2;
    
    integer i, j;
    reg [WIDTH-1:0] masked_req;
    wire [$clog2(WIDTH)-1:0] winner_idx;
    wire [WIDTH-1:0] onehot_winner;
    reg no_req_found;
    
    // 用于优化的Round Robin仲裁计算
    function [WIDTH-1:0] find_first_set;
        input [WIDTH-1:0] request;
        input [$clog2(WIDTH)-1:0] start_pos;
        reg [2*WIDTH-1:0] double_req;
        reg [WIDTH-1:0] result;
        begin
            double_req = {request, request};
            result = 0;
            for (j = 0; j < WIDTH; j = j + 1) begin
                if (double_req[start_pos+j] && (result == 0)) begin
                    result = 1 << ((start_pos+j) % WIDTH);
                end
            end
            find_first_set = result;
        end
    endfunction
    
    // 阶段1: 输入处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_stage1 <= 0;
            mode_stage1 <= 0;
            cfg_reg_stage1 <= 0;
            ptr_stage1 <= 0;
            mask_stage1 <= 0;
            valid_stage1 <= 0;
            ready_o <= 1;
        end else begin
            if (ready_o && valid_i) begin
                req_stage1 <= req_i;
                mode_stage1 <= mode;
                cfg_reg_stage1 <= cfg_reg;
                ptr_stage1 <= ptr;
                mask_stage1 <= mask;
                valid_stage1 <= 1;
            end else if (valid_stage1 && !valid_stage2) begin
                valid_stage1 <= 0;
                ready_o <= 1;
            end else if (!valid_i) begin
                valid_stage1 <= 0;
            end
        end
    end
    
    // 优化的固定优先级仲裁 - 使用更高效的方法
    always @(*) begin
        fixed_grant = 0;
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (req_stage1[i] && fixed_grant == 0) begin
                fixed_grant = 1 << i;
            end
        end
    end
    
    // 优化的Round Robin仲裁
    always @(*) begin
        rr_grant = find_first_set(req_stage1, ptr_stage1);
    end
    
    // 优化的优先级仲裁
    always @(*) begin
        masked_req = req_stage1 & cfg_reg_stage1;
        prio_grant = masked_req == 0 ? 0 : (masked_req & (~masked_req + 1));
    end
    
    // 阶段2: 计算各种仲裁结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mode_stage2 <= 0;
            mask_stage2 <= 0;
            ptr <= 0;
            valid_stage2 <= 0;
        end else if (valid_stage1) begin
            // 伪随机掩码更新 - 使用LFSR模式实现更好的分布
            mask_stage2 <= {mask_stage1[WIDTH-2:0], 
                           mask_stage1[WIDTH-1] ^ mask_stage1[WIDTH/2]};
            
            // 计算随机仲裁 - 使用掩码避免死锁
            rand_grant <= (req_stage1 & mask_stage2) ? 
                         (req_stage1 & mask_stage2 & (~(req_stage1 & mask_stage2) + 1)) :
                         (req_stage1 ? (req_stage1 & (~req_stage1 + 1)) : 0);
            
            // 更新Round Robin指针
            no_req_found = (rr_grant == 0);
            if (!no_req_found) begin
                for (i = 0; i < WIDTH; i = i + 1) begin
                    if (rr_grant[i]) begin
                        ptr <= (i + 1) % WIDTH;
                    end
                end
            end
            
            mode_stage2 <= mode_stage1;
            valid_stage2 <= 1;
        end else if (valid_stage2 && !valid_o) begin
            valid_stage2 <= 0;
        end
    end
    
    // 阶段3: 选择最终输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_o <= 0;
            valid_o <= 0;
        end else if (valid_stage2 && ready_i) begin
            case(mode_stage2)
                2'b00: grant_o <= fixed_grant;
                2'b01: grant_o <= rr_grant;
                2'b10: grant_o <= prio_grant;
                2'b11: grant_o <= rand_grant;
            endcase
            valid_o <= 1;
        end else if (valid_o && ready_i) begin
            valid_o <= 0;
        end
    end
    
    // 初始化掩码用于伪随机生成
    initial begin
        mask = {{(WIDTH-1){1'b0}}, 1'b1};
    end
    
endmodule