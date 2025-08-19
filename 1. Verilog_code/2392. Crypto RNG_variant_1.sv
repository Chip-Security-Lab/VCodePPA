//SystemVerilog
module crypto_rng #(parameter WIDTH = 32, SEED_WIDTH = 16) (
    input  wire                  clock,
    input  wire                  resetb,
    input  wire [SEED_WIDTH-1:0] seed,
    input  wire                  load_seed,
    input  wire                  get_random,
    output reg  [WIDTH-1:0]      random_out,
    output reg                   valid
);
    reg  [WIDTH-1:0] state;
    reg  [WIDTH-1:0] shifted_state;
    wire [WIDTH-1:0] next_state;
    
    // 预计算移位操作
    always @(*) begin
        shifted_state = {state[7:0], state[WIDTH-1:8]};
    end
    
    // 优化非线性状态更新函数
    assign next_state = {state[WIDTH-2:0], state[WIDTH-1]} ^ (state + shifted_state);
    
    // 状态寄存器更新逻辑
    always @(posedge clock or negedge resetb) begin
        if (!resetb) begin
            state <= {WIDTH{1'b1}};
        end 
        else if (load_seed) begin
            // 复制种子到状态寄存器
            state <= {{(WIDTH-SEED_WIDTH){seed[SEED_WIDTH-1]}}, seed};
        end
        else if (get_random) begin
            state <= next_state;
        end
    end
    
    // 随机输出逻辑
    always @(posedge clock or negedge resetb) begin
        if (!resetb) begin
            random_out <= {WIDTH{1'b0}};
        end
        else if (get_random) begin
            random_out <= state ^ next_state;
        end
    end
    
    // 有效信号逻辑
    always @(posedge clock or negedge resetb) begin
        if (!resetb) begin
            valid <= 1'b0;
        end
        else if (load_seed) begin
            valid <= 1'b0;
        end
        else if (get_random) begin
            valid <= 1'b1;
        end
        else begin
            valid <= 1'b0;
        end
    end
endmodule