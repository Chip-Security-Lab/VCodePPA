//SystemVerilog
// 顶层模块
module ring_counter_bidirectional (
    input  logic       clk,
    input  logic       dir,
    input  logic       rst,
    output logic [3:0] shift_reg
);

    // 控制单元信号
    logic       shift_left;
    logic       shift_right;
    logic       load_init_value;
    logic [3:0] next_shift_reg;

    // 实例化控制单元
    ring_counter_control_unit control_unit (
        .clk              (clk),
        .dir              (dir),
        .rst              (rst),
        .shift_left       (shift_left),
        .shift_right      (shift_right),
        .load_init_value  (load_init_value)
    );

    // 实例化数据路径单元
    ring_counter_datapath datapath (
        .shift_reg        (shift_reg),
        .shift_left       (shift_left),
        .shift_right      (shift_right),
        .load_init_value  (load_init_value),
        .next_shift_reg   (next_shift_reg)
    );

    // 状态更新逻辑
    ring_counter_state_update state_update (
        .clk              (clk),
        .next_shift_reg   (next_shift_reg),
        .shift_reg        (shift_reg)
    );

endmodule

// 控制单元子模块
module ring_counter_control_unit (
    input  logic clk,
    input  logic dir,
    input  logic rst,
    output logic shift_left,
    output logic shift_right,
    output logic load_init_value
);

    // 控制信号生成逻辑
    always_comb begin
        load_init_value = rst;
        shift_left = !rst && dir;
        shift_right = !rst && !dir;
    end

endmodule

// 数据路径子模块
module ring_counter_datapath (
    input  logic [3:0] shift_reg,
    input  logic       shift_left,
    input  logic       shift_right,
    input  logic       load_init_value,
    output logic [3:0] next_shift_reg
);

    // 计算下一个状态
    always_comb begin
        if (load_init_value) begin
            next_shift_reg = 4'b0001;
        end
        else if (shift_left) begin
            // 向左移位
            next_shift_reg = {shift_reg[2:0], shift_reg[3]};
        end
        else if (shift_right) begin
            // 向右移位
            next_shift_reg = {shift_reg[0], shift_reg[3:1]};
        end
        else begin
            next_shift_reg = shift_reg;
        end
    end

endmodule

// 状态更新子模块
module ring_counter_state_update (
    input  logic       clk,
    input  logic [3:0] next_shift_reg,
    output logic [3:0] shift_reg
);

    // 状态寄存器更新
    always_ff @(posedge clk) begin
        shift_reg <= next_shift_reg;
    end

endmodule