//SystemVerilog
//IEEE 1364-2005
module counter_array #(parameter NUM=4, WIDTH=4) (
    input clk, rst,
    output reg [NUM*WIDTH-1:0] cnts
);
    wire [NUM*WIDTH-1:0] cnt_next;
    
    genvar i;
    generate
        for(i=0; i<NUM; i=i+1) begin : cnt
            counter_sync_inc #(WIDTH) u_cnt(
                .clk(clk),
                .rst_n(~rst),
                .en(1'b1),
                .cnt_next(cnt_next[i*WIDTH +: WIDTH])
            );
        end
    endgenerate
    
    // 后向寄存器重定时：将输出寄存器移到顶层模块
    always @(posedge clk) begin
        if (rst)
            cnts <= {(NUM*WIDTH){1'b0}};
        else
            cnts <= cnt_next;
    end
endmodule

module counter_sync_inc #(parameter WIDTH=4) (
    input clk, rst_n, en,
    output [WIDTH-1:0] cnt_next
);
    reg [WIDTH-1:0] cnt;
    reg rst_n_reg, en_reg;
    
    // 寄存输入信号，减少输入端到第一级寄存器间的延迟
    always @(posedge clk) begin
        rst_n_reg <= rst_n;
        en_reg <= en;
    end
    
    // 计数器逻辑
    always @(posedge clk) begin
        if (!rst_n_reg)
            cnt <= 0;
        else if (en_reg)
            cnt <= cnt + 1;
    end
    
    // 后向寄存器重定时：将输出寄存直接连接到组合逻辑
    assign cnt_next = (!rst_n_reg) ? {WIDTH{1'b0}} : (en_reg ? cnt + 1'b1 : cnt);
endmodule