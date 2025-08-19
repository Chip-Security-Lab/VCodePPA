//SystemVerilog
module mux_divider (
    input main_clock, reset, enable,
    input [1:0] select,
    output reg out_clock
);
    reg [3:0] divider;
    reg [1:0] select_pipe;
    reg [3:0] divider_pipe;
    
    // 计数器逻辑
    always @(posedge main_clock or posedge reset) begin
        if (reset)
            divider <= 4'b0000;
        else if (enable)
            divider <= divider + 1'b1;
    end
    
    // 流水线寄存器以切割关键路径
    always @(posedge main_clock or posedge reset) begin
        if (reset) begin
            select_pipe <= 2'b00;
            divider_pipe <= 4'b0000;
        end
        else begin
            select_pipe <= select;
            divider_pipe <= divider;
        end
    end
    
    // 输出逻辑，使用流水线寄存器中的值
    always @(posedge main_clock or posedge reset) begin
        if (reset)
            out_clock <= 1'b0;
        else begin
            case (select_pipe)
                2'b00: out_clock <= divider_pipe[0]; // div2
                2'b01: out_clock <= divider_pipe[1]; // div4
                2'b10: out_clock <= divider_pipe[2]; // div8
                2'b11: out_clock <= divider_pipe[3]; // div16
            endcase
        end
    end
endmodule