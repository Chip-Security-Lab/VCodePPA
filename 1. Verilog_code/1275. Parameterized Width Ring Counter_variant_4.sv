//SystemVerilog
//-----------------------------------------------------------------------------
// 顶层模块: 流水线化参数化环形计数器
//-----------------------------------------------------------------------------
module param_ring_counter #(
    parameter CNT_WIDTH = 8
)(
    input  wire                clk_in,
    input  wire                rst_in,
    input  wire                valid_in,
    output wire                ready_out,
    output wire [CNT_WIDTH-1:0] counter_out,
    output wire                valid_out
);
    // 流水线控制信号
    wire valid_stage1, valid_stage2;
    wire stage1_ready, stage2_ready;
    
    // 流水线数据信号
    wire [CNT_WIDTH-1:0] reset_value;
    wire [CNT_WIDTH-1:0] shifted_value;
    wire [CNT_WIDTH-1:0] counter_stage1;
    
    // 流水线控制逻辑
    assign ready_out = stage1_ready;
    assign stage1_ready = !valid_stage1 || stage2_ready;
    assign stage2_ready = 1'b1; // 最后一级始终就绪
    
    // 实例化重置值生成器子模块
    reset_value_generator #(
        .WIDTH(CNT_WIDTH)
    ) reset_gen_inst (
        .rst_in      (rst_in),
        .reset_value (reset_value)
    );
    
    // 实例化第一级流水线: 位移逻辑
    pipeline_stage1 #(
        .WIDTH(CNT_WIDTH)
    ) pipeline_stage1_inst (
        .clk_in       (clk_in),
        .rst_in       (rst_in),
        .valid_in     (valid_in),
        .ready_out    (stage1_ready),
        .counter_in   (counter_out),
        .shifted_data (shifted_value),
        .counter_out  (counter_stage1),
        .valid_out    (valid_stage1)
    );
    
    // 实例化第二级流水线: 寄存器更新
    pipeline_stage2 #(
        .WIDTH(CNT_WIDTH)
    ) pipeline_stage2_inst (
        .clk_in       (clk_in),
        .rst_in       (rst_in),
        .valid_in     (valid_stage1),
        .ready_out    (stage2_ready),
        .reset_value  (reset_value),
        .next_value   (counter_stage1),
        .current_value(counter_out),
        .valid_out    (valid_out)
    );
    
endmodule

//-----------------------------------------------------------------------------
// 子模块: 重置值生成器
//-----------------------------------------------------------------------------
module reset_value_generator #(
    parameter WIDTH = 8
)(
    input  wire             rst_in,
    output reg  [WIDTH-1:0] reset_value
);
    always @(*) begin
        reset_value = {{(WIDTH-1){1'b0}}, 1'b1};
    end
endmodule

//-----------------------------------------------------------------------------
// 子模块: 第一级流水线 - 位移逻辑
//-----------------------------------------------------------------------------
module pipeline_stage1 #(
    parameter WIDTH = 8
)(
    input  wire             clk_in,
    input  wire             rst_in,
    input  wire             valid_in,
    output wire             ready_out,
    input  wire [WIDTH-1:0] counter_in,
    output reg  [WIDTH-1:0] shifted_data,
    output reg  [WIDTH-1:0] counter_out,
    output reg              valid_out
);
    // 内部位移逻辑
    wire [WIDTH-1:0] shifted_value;
    assign shifted_value = {counter_in[WIDTH-2:0], counter_in[WIDTH-1]};
    
    // 握手逻辑
    wire should_process;
    assign should_process = valid_in && ready_out;
    assign ready_out = 1'b1; // 本级永远就绪
    
    // 第一级流水线寄存器
    always @(posedge clk_in) begin
        if (rst_in) begin
            shifted_data <= {WIDTH{1'b0}};
            counter_out <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end
        else if (should_process) begin
            shifted_data <= shifted_value;
            counter_out <= counter_in;
            valid_out <= valid_in;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// 子模块: 第二级流水线 - 寄存器更新
//-----------------------------------------------------------------------------
module pipeline_stage2 #(
    parameter WIDTH = 8
)(
    input  wire             clk_in,
    input  wire             rst_in,
    input  wire             valid_in,
    output wire             ready_out,
    input  wire [WIDTH-1:0] reset_value,
    input  wire [WIDTH-1:0] next_value,
    output reg  [WIDTH-1:0] current_value,
    output reg              valid_out
);
    // 握手逻辑
    wire should_update;
    assign should_update = valid_in && ready_out;
    assign ready_out = 1'b1; // 本级永远就绪
    
    // 第二级流水线寄存器
    always @(posedge clk_in) begin
        if (rst_in) begin
            current_value <= reset_value;
            valid_out <= 1'b0;
        end
        else if (should_update) begin
            current_value <= next_value;
            valid_out <= valid_in;
        end
    end
endmodule