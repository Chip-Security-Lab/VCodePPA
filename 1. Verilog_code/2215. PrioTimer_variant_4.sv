//SystemVerilog
//IEEE 1364-2005
module PrioTimer #(parameter N=4) (
    input wire clk,
    input wire rst_n,
    input wire [N-1:0] req,
    output wire [$clog2(N)-1:0] grant
);
    // 内部连接信号
    wire [7:0] counter_values [0:N-1];
    wire [N-1:0] counter_overflow;
    reg [N-1:0] req_reg;
    
    // 输入寄存器化
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            req_reg <= {N{1'b0}};
        else
            req_reg <= req;
    end
    
    // 实例化计数器阵列模块
    CounterArray #(.N(N)) u_counter_array (
        .clk(clk),
        .rst_n(rst_n),
        .req(req_reg),
        .counter_values(counter_values),
        .counter_overflow(counter_overflow)
    );
    
    // 实例化优先级选择器模块
    PrioritySelector #(.N(N)) u_priority_selector (
        .clk(clk),
        .rst_n(rst_n),
        .counter_overflow(counter_overflow),
        .grant(grant)
    );
    
endmodule

module CounterArray #(parameter N=4) (
    input wire clk,
    input wire rst_n,
    input wire [N-1:0] req,
    output reg [7:0] counter_values [0:N-1],
    output reg [N-1:0] counter_overflow
);
    integer i;
    reg [7:0] next_counter_values [0:N-1];
    wire [N-1:0] overflow_condition;
    
    // 计算下一个计数值（组合逻辑）- 针对req=1的情况
    always @(*) begin
        for(i=0; i<N; i=i+1) begin
            if(req[i])
                next_counter_values[i] = counter_values[i] + 8'h01;
            else
                next_counter_values[i] = counter_values[i];
        end
    end
    
    // 溢出条件检测（组合逻辑）
    generate
        for(genvar j=0; j<N; j=j+1) begin : overflow_check
            assign overflow_condition[j] = (next_counter_values[j] > 8'h7F);
        end
    endgenerate
    
    // 计数器寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for(i=0; i<N; i=i+1) begin
                counter_values[i] <= 8'h00;
            end
        end
        else begin
            for(i=0; i<N; i=i+1) begin
                counter_values[i] <= next_counter_values[i];
            end
        end
    end
    
    // 溢出检测寄存器化
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_overflow <= {N{1'b0}};
        end
        else begin
            counter_overflow <= overflow_condition;
        end
    end
    
endmodule

module PrioritySelector #(parameter N=4) (
    input wire clk,
    input wire rst_n,
    input wire [N-1:0] counter_overflow,
    output reg [$clog2(N)-1:0] grant
);
    reg [$clog2(N)-1:0] next_grant;
    reg [N-1:0] priority_mask;
    
    // 生成优先级掩码（组合逻辑）
    integer k;
    always @(*) begin
        priority_mask = {N{1'b0}};
        for(k=N-1; k>=0; k=k-1) begin
            if(counter_overflow[k])
                priority_mask[k] = 1'b1;
        end
    end
    
    // 找到最高优先级（组合逻辑）
    integer i;
    always @(*) begin
        next_grant = {$clog2(N){1'b0}}; // 默认值
        for(i=N-1; i>=0; i=i-1) begin
            if(priority_mask[i]) 
                next_grant = i[$clog2(N)-1:0];
        end
    end
    
    // 输出寄存器化
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            grant <= {$clog2(N){1'b0}};
        else
            grant <= next_grant;
    end
    
endmodule