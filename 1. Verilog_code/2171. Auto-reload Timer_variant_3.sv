//SystemVerilog
// 顶层模块
module auto_reload_timer #(
    parameter WIDTH = 32
)(
    input  wire              clk,
    input  wire              rstn,
    input  wire              en,
    input  wire              reload_en,
    input  wire [WIDTH-1:0]  reload_val,
    output wire [WIDTH-1:0]  count,
    output wire              timeout
);

    wire [WIDTH-1:0] reload_reg;
    wire count_eq_reload;

    // 子模块实例化
    reload_register #(
        .WIDTH(WIDTH)
    ) u_reload_register (
        .clk        (clk),
        .rstn       (rstn),
        .reload_en  (reload_en),
        .reload_val (reload_val),
        .reload_reg (reload_reg)
    );

    comparator #(
        .WIDTH(WIDTH)
    ) u_comparator (
        .count          (count),
        .reload_reg     (reload_reg),
        .count_eq_reload(count_eq_reload)
    );

    counter_module #(
        .WIDTH(WIDTH)
    ) u_counter_module (
        .clk            (clk),
        .rstn           (rstn),
        .en             (en),
        .count_eq_reload(count_eq_reload),
        .count          (count),
        .timeout        (timeout)
    );

endmodule

// 重装值寄存器模块
module reload_register #(
    parameter WIDTH = 32
)(
    input  wire              clk,
    input  wire              rstn,
    input  wire              reload_en,
    input  wire [WIDTH-1:0]  reload_val,
    output reg  [WIDTH-1:0]  reload_reg
);

    always @(posedge clk) begin
        if (!rstn) 
            reload_reg <= {WIDTH{1'b1}}; // 所有位设为1
        else if (reload_en) 
            reload_reg <= reload_val;
    end

endmodule

// 比较器模块
module comparator #(
    parameter WIDTH = 32
)(
    input  wire [WIDTH-1:0]  count,
    input  wire [WIDTH-1:0]  reload_reg,
    output wire              count_eq_reload
);

    // 组合逻辑比较
    assign count_eq_reload = (count == reload_reg);

endmodule

// 计数器和超时标志位模块
module counter_module #(
    parameter WIDTH = 32
)(
    input  wire              clk,
    input  wire              rstn,
    input  wire              en,
    input  wire              count_eq_reload,
    output reg  [WIDTH-1:0]  count,
    output reg               timeout
);

    always @(posedge clk) begin
        if (!rstn) begin 
            count <= {WIDTH{1'b0}}; 
            timeout <= 1'b0; 
        end
        else if (en) begin
            if (count_eq_reload) begin
                count <= {WIDTH{1'b0}}; 
                timeout <= 1'b1;
            end 
            else begin 
                count <= count + 1'b1; 
                timeout <= 1'b0; 
            end
        end
    end

endmodule