//SystemVerilog
module EmergencyArbiter (
    input           clk,
    input           rst,
    input  [3:0]    req,
    input           emergency,
    output [3:0]    grant
);

    // 组合逻辑信号
    wire [3:0] normal_grant;
    wire [3:0] emergency_grant;
    wire [3:0] final_grant;

    // 组合逻辑模块实例化
    PriorityArbiter priority_arbiter_inst (
        .req        (req),
        .grant      (normal_grant)
    );

    EmergencyHandler emergency_handler_inst (
        .emergency  (emergency),
        .emerg_grant(emergency_grant)
    );

    GrantSelector grant_selector_inst (
        .normal_grant   (normal_grant),
        .emergency_grant(emergency_grant),
        .emergency      (emergency),
        .final_grant    (final_grant)
    );

    // 时序逻辑模块实例化
    OutputRegister output_register_inst (
        .clk        (clk),
        .rst        (rst),
        .grant_in   (final_grant),
        .grant_out  (grant)
    );

endmodule

// 纯组合逻辑模块
module PriorityArbiter (
    input  [3:0] req,
    output [3:0] grant
);
    assign grant = req & (~req + 1);
endmodule

// 纯组合逻辑模块
module EmergencyHandler (
    input           emergency,
    output [3:0]    emerg_grant
);
    assign emerg_grant = 4'b1000;
endmodule

// 纯组合逻辑模块
module GrantSelector (
    input  [3:0] normal_grant,
    input  [3:0] emergency_grant,
    input        emergency,
    output [3:0] final_grant
);
    assign final_grant = emergency ? emergency_grant : normal_grant;
endmodule

// 纯时序逻辑模块
module OutputRegister (
    input           clk,
    input           rst,
    input  [3:0]    grant_in,
    output reg [3:0] grant_out
);
    always @(posedge clk) begin
        if (rst)
            grant_out <= 4'b0000;
        else
            grant_out <= grant_in;
    end
endmodule