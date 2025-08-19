//SystemVerilog
// SystemVerilog
// IEEE 1364-2005 Verilog标准

module shift_reg_4bit (
    input wire clk, rst, load_en, shift_en, serial_in,
    input wire [3:0] parallel_data,
    output wire serial_out,
    output wire [3:0] parallel_out
);
    // 内部连线
    wire [3:0] reg_data_internal;
    
    // 控制逻辑子模块
    control_unit control_inst (
        .clk(clk),
        .rst(rst),
        .load_en(load_en),
        .shift_en(shift_en),
        .serial_in(serial_in),
        .parallel_data(parallel_data),
        .reg_data(reg_data_internal)
    );
    
    // 输出逻辑子模块
    output_unit output_inst (
        .reg_data(reg_data_internal),
        .serial_out(serial_out),
        .parallel_out(parallel_out)
    );
    
endmodule

// 控制单元 - 处理寄存器数据的更新逻辑
module control_unit (
    input wire clk, rst, load_en, shift_en, serial_in,
    input wire [3:0] parallel_data,
    output reg [3:0] reg_data
);
    // 寄存器更新逻辑
    always @(posedge clk) begin
        if (rst)
            reg_data <= 4'b0000;
        else if (load_en)
            reg_data <= parallel_data;
        else if (shift_en)
            reg_data <= {reg_data[2:0], serial_in};
    end
endmodule

// 输出单元 - 处理寄存器数据到输出端口的映射
module output_unit (
    input wire [3:0] reg_data,
    output wire serial_out,
    output wire [3:0] parallel_out
);
    // 输出映射逻辑
    assign serial_out = reg_data[3];
    assign parallel_out = reg_data;
endmodule