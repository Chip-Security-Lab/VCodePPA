//SystemVerilog
// IEEE 1364-2005 Verilog标准
module DynamicWidthShift #(parameter MAX_WIDTH=16) (
    input wire clk, 
    input wire rstn,
    input wire [$clog2(MAX_WIDTH)-1:0] width_sel,
    input wire din,
    output reg [MAX_WIDTH-1:0] q
);
    // 组合逻辑信号声明
    wire [MAX_WIDTH-1:0] shifted_data;
    
    // 分离的组合逻辑部分
    DynamicShiftCombLogic #(
        .MAX_WIDTH(MAX_WIDTH)
    ) shift_logic (
        .current_q(q),
        .width_sel(width_sel),
        .din(din),
        .shifted_data(shifted_data)
    );
    
    // 时序逻辑部分
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            q <= {MAX_WIDTH{1'b0}};
        end else begin
            q <= shifted_data;
        end
    end
endmodule

// 分离的组合逻辑模块
module DynamicShiftCombLogic #(parameter MAX_WIDTH=16) (
    input wire [MAX_WIDTH-1:0] current_q,
    input wire [$clog2(MAX_WIDTH)-1:0] width_sel,
    input wire din,
    output wire [MAX_WIDTH-1:0] shifted_data
);
    // 内部信号
    reg [MAX_WIDTH-1:0] next_q_comb;
    integer i;
    
    // 组合逻辑
    always @(*) begin
        // 第一位总是新输入的数据
        next_q_comb = current_q;
        next_q_comb[0] = din;
        
        // 根据width_sel选择性地进行移位
        for (i=1; i<MAX_WIDTH; i=i+1) begin
            if (i < width_sel)
                next_q_comb[i] = current_q[i-1];
            else
                next_q_comb[i] = current_q[i];
        end
    end
    
    // 将组合逻辑的结果连接到输出
    assign shifted_data = next_q_comb;
endmodule