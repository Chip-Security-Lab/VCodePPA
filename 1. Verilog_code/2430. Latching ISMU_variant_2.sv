//SystemVerilog
module latch_ismu #(parameter WIDTH = 16)(
    input wire i_clk, i_rst_b,
    input wire [WIDTH-1:0] i_int_src,
    input wire i_latch_en,
    input wire [WIDTH-1:0] i_int_clr,
    output reg [WIDTH-1:0] o_latched_int,
    // 流水线控制信号
    input wire i_valid_in,
    output reg o_valid_out,
    input wire i_ready_in,
    output wire o_ready_out
);
    // 输入寄存器
    reg [WIDTH-1:0] int_src_reg;
    reg latch_en_reg;
    reg [WIDTH-1:0] int_clr_reg;
    reg valid_in_reg;
    
    // 流水线控制逻辑
    wire stall_pipeline;
    reg valid_stage1;
    reg valid_stage2;
    assign stall_pipeline = valid_stage2 && !i_ready_in;
    assign o_ready_out = !stall_pipeline;
    
    // 中间数据信号
    wire [WIDTH-1:0] int_set_comb;
    wire [WIDTH-1:0] latched_with_set_comb;
    
    // 借位减法器相关信号
    wire [WIDTH-1:0] minuend; // 被减数
    wire [WIDTH-1:0] subtrahend; // 减数
    wire [WIDTH:0] borrow; // 借位信号，增加一位
    wire [WIDTH-1:0] next_latched_int_comb; // 差
    
    // 状态寄存器
    reg [WIDTH-1:0] latched_int_reg;
    
    // 输入寄存
    always @(posedge i_clk or negedge i_rst_b) begin
        if (!i_rst_b) begin
            int_src_reg <= {WIDTH{1'b0}};
            latch_en_reg <= 1'b0;
            int_clr_reg <= {WIDTH{1'b0}};
            valid_in_reg <= 1'b0;
        end else if (!stall_pipeline) begin
            int_src_reg <= i_int_src;
            latch_en_reg <= i_latch_en;
            int_clr_reg <= i_int_clr;
            valid_in_reg <= i_valid_in;
        end
    end
    
    // 计算中断源置位信号
    assign int_set_comb = int_src_reg & {WIDTH{latch_en_reg}};
    assign latched_with_set_comb = latched_int_reg | int_set_comb;
    
    // 借位减法器实现
    assign minuend = latched_with_set_comb;
    assign subtrahend = int_clr_reg;
    
    // 计算借位链
    assign borrow[0] = 1'b0; // 初始无借位
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_borrow
            assign borrow[i+1] = (~minuend[i] & subtrahend[i]) | 
                                 (~minuend[i] & borrow[i]) | 
                                 (subtrahend[i] & borrow[i]);
        end
    endgenerate
    
    // 使用借位减法器计算差值
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_diff
            assign next_latched_int_comb[i] = minuend[i] ^ subtrahend[i] ^ borrow[i];
        end
    endgenerate
    
    // 状态及流水线控制寄存器更新
    always @(posedge i_clk or negedge i_rst_b) begin
        if (!i_rst_b) begin
            latched_int_reg <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (!stall_pipeline) begin
            latched_int_reg <= next_latched_int_comb;
            valid_stage1 <= valid_in_reg;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出寄存器
    always @(posedge i_clk or negedge i_rst_b) begin
        if (!i_rst_b) begin
            o_latched_int <= {WIDTH{1'b0}};
            o_valid_out <= 1'b0;
        end else if (!stall_pipeline) begin
            o_latched_int <= latched_int_reg;
            o_valid_out <= valid_stage2;
        end
    end
endmodule