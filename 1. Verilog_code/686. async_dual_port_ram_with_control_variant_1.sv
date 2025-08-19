//SystemVerilog
// 顶层模块
module async_dual_port_ram_with_control #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire we_a, we_b,
    input wire control_signal_a, control_signal_b
);

    // 控制信号生成模块
    wire write_enable_a, write_enable_b;
    control_signal_generator #(
        .DATA_WIDTH(DATA_WIDTH)
    ) control_gen (
        .control_signal_a(control_signal_a),
        .control_signal_b(control_signal_b),
        .we_a(we_a),
        .we_b(we_b),
        .write_enable_a(write_enable_a),
        .write_enable_b(write_enable_b)
    );

    // 地址冲突检测模块
    wire addr_collision;
    address_collision_detector #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) addr_detector (
        .addr_a(addr_a),
        .addr_b(addr_b),
        .write_enable_a(write_enable_a),
        .write_enable_b(write_enable_b),
        .addr_collision(addr_collision)
    );

    // RAM存储核心模块
    ram_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) ram_inst (
        .addr_a(addr_a),
        .addr_b(addr_b),
        .din_a(din_a),
        .din_b(din_b),
        .dout_a(dout_a),
        .dout_b(dout_b),
        .write_enable_a(write_enable_a),
        .write_enable_b(write_enable_b),
        .addr_collision(addr_collision)
    );

endmodule

// 控制信号生成子模块
module control_signal_generator #(
    parameter DATA_WIDTH = 8
)(
    input wire control_signal_a,
    input wire control_signal_b,
    input wire we_a,
    input wire we_b,
    output wire write_enable_a,
    output wire write_enable_b
);

    assign write_enable_a = control_signal_a & we_a;
    assign write_enable_b = control_signal_b & we_b;

endmodule

// 地址冲突检测子模块
module address_collision_detector #(
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr_a,
    input wire [ADDR_WIDTH-1:0] addr_b,
    input wire write_enable_a,
    input wire write_enable_b,
    output wire addr_collision
);

    wire addr_match = ~|(addr_a ^ addr_b);
    assign addr_collision = addr_match & (write_enable_a | write_enable_b);

endmodule

// RAM存储核心子模块
module ram_core #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr_a,
    input wire [ADDR_WIDTH-1:0] addr_b,
    input wire [DATA_WIDTH-1:0] din_a,
    input wire [DATA_WIDTH-1:0] din_b,
    output reg [DATA_WIDTH-1:0] dout_a,
    output reg [DATA_WIDTH-1:0] dout_b,
    input wire write_enable_a,
    input wire write_enable_b,
    input wire addr_collision
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    always @* begin
        case ({write_enable_a, write_enable_b, addr_collision})
            3'b100: ram[addr_a] = din_a;
            3'b010: ram[addr_b] = din_b;
            3'b110: ram[addr_a] = din_a;  // 冲突时优先A
            default: ;  // 保持原值
        endcase
    end
    
    always @* begin
        dout_a <= ram[addr_a];
        dout_b <= ram[addr_b];
    end

endmodule