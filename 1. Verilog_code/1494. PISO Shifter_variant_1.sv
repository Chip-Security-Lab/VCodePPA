//SystemVerilog

module piso_shifter (
    input wire clk,
    input wire clear,
    input wire load,
    input wire [7:0] parallel_data,
    output wire serial_out
);
    // 内部连线
    wire [7:0] shift_reg_out;
    
    // 实例化控制单元子模块
    control_unit ctrl_unit (
        .clk(clk),
        .clear(clear),
        .load(load),
        .parallel_data(parallel_data),
        .shift_reg_out(shift_reg_out)
    );
    
    // 实例化输出单元子模块
    output_unit out_unit (
        .shift_reg_out(shift_reg_out),
        .serial_out(serial_out)
    );
    
endmodule

module control_unit (
    input wire clk,
    input wire clear,
    input wire load,
    input wire [7:0] parallel_data,
    output reg [7:0] shift_reg_out
);
    // 移位寄存器操作
    always @(posedge clk) begin
        if (clear)
            shift_reg_out <= 8'h00;
        else if (load)
            shift_reg_out <= parallel_data;
        else
            shift_reg_out <= {shift_reg_out[6:0], 1'b0};
    end
endmodule

module output_unit (
    input wire [7:0] shift_reg_out,
    output wire serial_out
);
    // 输出MSB作为串行输出
    assign serial_out = shift_reg_out[7];
endmodule