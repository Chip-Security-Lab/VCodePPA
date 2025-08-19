//SystemVerilog
module shadow_reg_dual_clk #(parameter DW=16) (
    input main_clk, shadow_clk,
    input load, 
    input [DW-1:0] din,
    input [7:0] sub_value,  // Added subtraction value input
    output [DW-1:0] dout,
    output [7:0] sub_result  // Added subtraction result output
);

    // 实例化存储子模块
    shadow_storage #(.DW(DW)) storage_inst (
        .main_clk(main_clk),
        .load(load),
        .din(din),
        .storage_out(shadow_storage)
    );

    // 实例化输出子模块
    shadow_output #(.DW(DW)) output_inst (
        .shadow_clk(shadow_clk),
        .storage_in(shadow_storage),
        .dout(dout)
    );
    
    // 实例化减法器子模块
    two_complement_subtractor #(.WIDTH(8)) subtractor_inst (
        .clk(main_clk),
        .a(din[7:0]),
        .b(sub_value),
        .result(sub_result)
    );

endmodule

// 存储子模块
module shadow_storage #(parameter DW=16) (
    input main_clk,
    input load,
    input [DW-1:0] din,
    output reg [DW-1:0] storage_out
);
    always @(posedge main_clk) 
        if(load) storage_out <= din;
endmodule

// 输出子模块
module shadow_output #(parameter DW=16) (
    input shadow_clk,
    input [DW-1:0] storage_in,
    output reg [DW-1:0] dout
);
    always @(posedge shadow_clk) 
        dout <= storage_in;
endmodule

// 二进制补码减法器子模块
module two_complement_subtractor #(parameter WIDTH=8) (
    input clk,
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output reg [WIDTH-1:0] result
);
    // 内部信号
    reg [WIDTH-1:0] b_complement;
    reg [WIDTH:0] temp_result;
    
    // 二进制补码减法实现
    always @(posedge clk) begin
        // 计算b的补码
        b_complement <= ~b + 1'b1;
        
        // 执行加法 (a + (-b))
        temp_result <= a + b_complement;
        
        // 输出结果
        result <= temp_result[WIDTH-1:0];
    end
endmodule