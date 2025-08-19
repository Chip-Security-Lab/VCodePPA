//SystemVerilog
// 顶层模块
module wave5_triangle #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    output wire [WIDTH-1:0] wave_out
);
    wire direction_up;
    wire direction_down;
    wire [WIDTH-1:0] next_value;
    wire direction;

    // 方向控制子模块
    triangle_direction_control #(
        .WIDTH(WIDTH)
    ) direction_ctrl (
        .clk(clk),
        .rst(rst),
        .current_value(wave_out),
        .direction(direction),
        .direction_up(direction_up),
        .direction_down(direction_down)
    );

    // 值计算子模块
    triangle_value_generator #(
        .WIDTH(WIDTH)
    ) value_gen (
        .current_value(wave_out),
        .direction(direction),
        .next_value(next_value)
    );

    // 状态寄存器子模块
    triangle_state_register #(
        .WIDTH(WIDTH)
    ) state_reg (
        .clk(clk),
        .rst(rst),
        .direction_up(direction_up),
        .direction_down(direction_down),
        .next_value(next_value),
        .direction(direction),
        .wave_out(wave_out)
    );
endmodule

// 方向控制子模块
module triangle_direction_control #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire [WIDTH-1:0] current_value,
    input  wire             direction,
    output reg              direction_up,
    output reg              direction_down
);
    always @(*) begin
        direction_up   = 1'b0;
        direction_down = 1'b0;
        
        if(current_value == {WIDTH{1'b1}})
            direction_down = 1'b1;
            
        if(current_value == {WIDTH{1'b0}})
            direction_up = 1'b1;
    end
endmodule

// 值计算子模块
module triangle_value_generator #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] current_value,
    input  wire             direction,
    output reg  [WIDTH-1:0] next_value
);
    always @(*) begin
        if(direction)
            next_value = current_value + 1'b1;
        else
            next_value = current_value - 1'b1;
    end
endmodule

// 状态寄存器子模块
module triangle_state_register #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             direction_up,
    input  wire             direction_down,
    input  wire [WIDTH-1:0] next_value,
    output reg              direction,
    output reg  [WIDTH-1:0] wave_out
);
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            wave_out  <= {WIDTH{1'b0}};
            direction <= 1'b1;
        end else begin
            wave_out <= next_value;
            
            if(direction_down)
                direction <= 1'b0;
            else if(direction_up)
                direction <= 1'b1;
        end
    end
endmodule