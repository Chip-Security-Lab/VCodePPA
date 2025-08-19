//SystemVerilog
// 顶层模块
module MuxTriState #(parameter W=8, N=4) (
    inout [W-1:0] bus,
    input [W-1:0] data_in [0:N-1],
    input [N-1:0] oe
);

    // 内部信号
    wire [W-1:0] tri_state_out [0:N-1];
    
    // 实例化三态缓冲器子模块
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin: gen_tri_buf
            TriStateBuffer #(.WIDTH(W)) tri_buf (
                .data_in(data_in[i]),
                .oe(oe[i]),
                .data_out(tri_state_out[i])
            );
        end
    endgenerate

    // 实例化总线仲裁器子模块
    BusArbiter #(.WIDTH(W), .NUM_PORTS(N)) bus_arb (
        .tri_state_in(tri_state_out),
        .bus(bus)
    );

endmodule

// 三态缓冲器子模块
module TriStateBuffer #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    input oe,
    output [WIDTH-1:0] data_out
);
    assign data_out = oe ? data_in : {WIDTH{1'bz}};
endmodule

// 总线仲裁器子模块
module BusArbiter #(parameter WIDTH=8, NUM_PORTS=4) (
    input [WIDTH-1:0] tri_state_in [0:NUM_PORTS-1],
    inout [WIDTH-1:0] bus
);
    // 总线仲裁逻辑
    wire [WIDTH-1:0] bus_drive;
    assign bus = bus_drive;
    
    // 优先级编码器 - 使用借位减法器算法
    reg [WIDTH-1:0] selected_data;
    reg [WIDTH-1:0] borrow;
    integer i;
    
    always @(*) begin
        selected_data = {WIDTH{1'bz}};
        borrow = {WIDTH{1'b0}};
        
        for (i = 0; i < NUM_PORTS; i = i + 1) begin
            if (tri_state_in[i] !== {WIDTH{1'bz}}) begin
                // 借位减法器算法实现
                selected_data = tri_state_in[i] - borrow;
                borrow = (tri_state_in[i] < borrow) ? 1'b1 : 1'b0;
            end
        end
    end
    
    assign bus_drive = selected_data;
endmodule