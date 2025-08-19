//SystemVerilog
module SyncLatch #(parameter WIDTH=8) (
    input clk, rst_n, en,
    input [WIDTH-1:0] d,
    output [WIDTH-1:0] q
);

    // 实例化寄存器子模块
    RegArray #(.WIDTH(WIDTH)) reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .d(d),
        .q(q)
    );

endmodule

// 寄存器阵列子模块
module RegArray #(parameter WIDTH=8) (
    input clk, rst_n, en,
    input [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= {WIDTH{1'b0}};
        end else if (en) begin
            q <= d;
        end
    end

endmodule